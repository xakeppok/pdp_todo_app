# Home-screen widgets

Cheat sheet for this repo: native widget architecture per platform, refresh lifecycle, Flutter↔widget storage, size families, deep links, setup (app groups / signing / entitlements), and practices for keeping the app and widgets in sync.

Knowledge-sharing session (demo script, screenshots, pitfalls): [home-widgets-session.md](home-widgets-session.md).

Official references: [Android App Widgets](https://developer.android.com/develop/ui/views/appwidgets), [Jetpack Glance](https://developer.android.com/develop/ui/compose/glance), [WidgetKit](https://developer.apple.com/documentation/widgetkit), [`home_widget` 0.9.3](https://pub.dev/packages/home_widget).

Home-screen widgets are **not** Flutter widgets. The UI is native (`RemoteViews` / Glance / SwiftUI). Flutter writes a snapshot into shared storage and asks the OS to redraw. Taps either deep-link into the app or mutate that snapshot in a native receiver / App Intent.

## This app

Two Android providers and one iOS WidgetKit extension, all reading the same keys.

| Surface | Framework | User-visible name | Native entry |
|---------|-----------|-------------------|--------------|
| Android XML | App Widget + `RemoteViews` | My Todos | [`TodoWidget.kt`](../android/app/src/main/kotlin/com/example/pdp_todo_app/TodoWidget.kt) |
| Android Glance | Jetpack Glance Compose | My Todos (Glance) | [`TodoGlanceWidget.kt`](../android/app/src/main/kotlin/com/example/pdp_todo_app/TodoGlanceWidget.kt) |
| iOS | WidgetKit + SwiftUI | My Todos | [`TodoWidget.swift`](../ios/TodoWidget/TodoWidget.swift) |

Shared contract (keep Dart / Kotlin / Swift copies in sync): [`TodoWidgetContract`](../lib/core/home_widget/todo_widget_contract.dart), Android [`TodoWidgetStore`](../android/app/src/main/kotlin/com/example/pdp_todo_app/TodoWidgetStore.kt), iOS [`TodoWidgetConfig`](../ios/TodoWidget/BackgroundIntent.swift).

| Key | Type | Role |
|-----|------|------|
| `todos` | JSON string | Full list. Flutter source of truth; native toggle mutates it |
| `widget_todos` | JSON string | Projection: `{id, title, completed}` × first 8 |
| `todos_total` | int | Full count for “+ N more” |
| App group | `group.com.example.pdpTodoApp` | iOS `UserDefaults` suite |
| URI scheme | `todowidget://app/todos[/{id}]` | Deep link into Flutter |

Flutter persistence: [`HomeWidgetTodoDataSource`](../lib/features/todos/data/datasources/home_widget_todo_data_source.dart) → [`HomeWidgetTodoService`](../lib/features/todos/data/services/home_widget_todo_service.dart) (`home_widget` `saveWidgetData` + `updateWidget`).

## Architecture

```
TodosBloc / details cubit
        ↓
  TodoDataSource (HomeWidgetTodoDataSource)
        ↓
  HomeWidgetTodoService
        ↓  saveWidgetData + updateWidget
  Android SharedPreferences          iOS UserDefaults (app group)
        ↓                                    ↓
  TodoWidget (RemoteViews)            TodoWidget (WidgetKit)
  TodoGlanceWidget (Glance)           TimelineProvider policy .never
        ↓                                    ↓
  TodoWidgetToggleReceiver            BackgroundIntent (iOS 17)
        ↓                                    ↓
  rewrite prefs + refresh             rewrite suite + reloadTimelines
        ↓
  tap title → todowidget://app/todos[/id]
        ↓
  MainActivity / Runner URL
        ↓
  HomeWidget.widgetClicked / initiallyLaunchedFromHomeWidget
        ↓
  TodoWidgetLink → go_router  /todos  or  /todos/:id
```

Domain never imports `home_widget`. The data source owns encode / decode / the 8-item projection (`TodoModel.widgetListToJsonString`). Tests swap in [`FakeHomeWidgetTodoService`](../test/helpers/fake_home_widget_todo_service.dart).

### Android App Widgets / RemoteViews

`AppWidgetProvider` subclass [`TodoWidget`](../android/app/src/main/kotlin/com/example/pdp_todo_app/TodoWidget.kt) extends `home_widget`’s `HomeWidgetProvider`. The system hosts the layout in the launcher process. You cannot run arbitrary Android Views; only `RemoteViews` (`TextView`, `CheckBox`, `LinearLayout`, …).

This app:

- Layout: [`todo_widget.xml`](../android/app/src/main/res/layout/todo_widget.xml) — 8 fixed rows (RemoteViews has no RecyclerView).
- Provider XML: [`todo_widget_info.xml`](../android/app/src/main/res/xml/todo_widget_info.xml) — min 110×110 dp, target 2×3 cells, `updatePeriodMillis=86400000`.
- Clicks: `PendingIntent` per row. Title → `ACTION_VIEW` `todowidget://…`. Checkbox → `TodoWidgetToggleReceiver`.
- Resize: `onAppWidgetOptionsChanged` re-runs `fitTodos` against `OPTION_APPWIDGET_SIZES` (API 31+) or min/max height.

### Android Glance

[`TodoGlanceWidget`](../android/app/src/main/kotlin/com/example/pdp_todo_app/TodoGlanceWidget.kt) is a second provider, not a replacement. Same store, same toggle receiver, Compose-like UI (`SizeMode.Exact`, `HomeWidgetGlanceStateDefinition`).

Glance still compiles to `RemoteViews`. You get `@Composable` layout and `LocalSize`, not a full Compose runtime on the home screen. Checkboxes are images (`widget_checkbox_*.xml`) because Glance has no `CheckBox` primitive that matches the XML widget 1:1.

Gradle: Compose compiler plugin in [`android/settings.gradle.kts`](../android/settings.gradle.kts), `buildFeatures.compose = true`, `androidx.glance:glance-appwidget:1.1.1` in [`android/app/build.gradle.kts`](../android/app/build.gradle.kts).

### iOS WidgetKit / SwiftUI

A **widget extension** (`TodoWidgetExtension.appex`, bundle `com.example.pdpTodoApp.TodoWidget`) runs in a separate process. It cannot import Flutter. It reads the app-group `UserDefaults` and renders SwiftUI.

This app:

- `StaticConfiguration` kind `TodoWidget`, families `.systemSmall` / `.systemMedium` / `.systemLarge`.
- `TimelineProvider`: `placeholder` (gallery), `getSnapshot` (one frame), `getTimeline` with **`.never`** — the list only changes when the app or an App Intent writes storage.
- Toggle: iOS 17 `AppIntent` [`BackgroundIntent`](../ios/TodoWidget/BackgroundIntent.swift) (`openAppWhenRun = false`). Writes `todos` + projection, then `WidgetCenter.shared.reloadTimelines(ofKind:)`.
- Title / empty / row text: SwiftUI `Link` to `todowidget://app/todos[/{id}]?homeWidget`.

Deployment target for the extension is **iOS 17** (interactive buttons). The Flutter app itself can still target the Flutter default.

## Refresh lifecycle

Widgets are snapshots. The OS decides when your code runs. Treat “push a new snapshot when *you* know data changed” as the primary path; periodic OS refresh is a backup.

### Android

| Trigger | What runs | Counted as “update”? |
|---------|-----------|----------------------|
| `HomeWidget.updateWidget(name: TodoWidget / TodoGlanceWidgetReceiver)` | `onUpdate` / Glance `provideGlance` | Immediate. This is how the Flutter app refreshes |
| `AppWidgetManager.updateAppWidget` from `TodoWidgetStore.refresh` | Same, after a checkbox tap | Immediate, app process not required |
| `updatePeriodMillis` (here 24 h) | `onUpdate` | OS may batch; **minimum 30 min**; `0` means never. Do not use this for user-visible freshness |
| `onAppWidgetOptionsChanged` | Rebuild for new cell size | Resize, not a data refresh |
| Launcher / pin / first add | `onUpdate` | First paint from current prefs |

`updatePeriodMillis` is a last-resort alarm. Values under 30 minutes are ignored (except `0`). This app sets 24 hours so the OS still has a stale-data backstop; every user edit goes through `save()` → `updateWidget()`.

### iOS

| Trigger | What runs | Budget |
|---------|-----------|--------|
| `HomeWidget.updateWidget(iOSName: TodoWidget)` | `getTimeline` | **Not** counted while the containing app is in the foreground |
| `WidgetCenter.reloadTimelines(ofKind:)` from `BackgroundIntent` | `getTimeline` | App Intent taps are **not** counted |
| Timeline policy `.atEnd` / `.after(date)` | System asks for a new timeline | **Counted** (~40–70 reloads / 24 h for a frequently viewed widget, tuned to usage) |
| This app’s policy `.never` | No scheduled reload | Relies on Flutter + App Intent |
| Gallery / Smart Stack glance | `placeholder` / `getSnapshot` | Not a live update |

Do not schedule a 15-minute timeline “just in case”. Apple will drop reloads when the budget is gone; the widget then shows a stale entry until the next allowed reload. Event-driven data (a todo list) should use `.never` plus explicit reloads.

WidgetKit developer mode (Settings → Developer) lifts the budget on a debug device. Do not assume that behaviour in production.

### Flutter

```text
create / update / delete / toggle in the app
  → HomeWidgetTodoDataSource._persist
  → save todos + widget_todos + todos_total
  → updateWidget (XML) + updateWidget (Glance)   // iOSName on the first call
```

When the user toggles **on the widget**, Flutter is not running. Native code writes the same keys. Consistency on the way back:

1. [`TodoApp`](../lib/app/app.dart) observes `AppLifecycleState.resumed`.
2. Dispatches `TodosSyncRequested`.
3. [`TodosBloc._onSync`](../lib/features/todos/presentation/bloc/todos_bloc.dart) re-reads `todos` without a loading flash; failures keep the current snapshot.

## Data-sharing options

All options below are “share a snapshot the widget can read without Flutter”. Channels / Pigeon do **not** work here: the widget process is not attached to the Dart isolate.

| Option | How | + | − | This app |
|--------|-----|---|---|----------|
| **`home_widget` + SharedPreferences / App Group UserDefaults** | `saveWidgetData` / `getWidgetData`; Android `HomeWidgetPlugin.getData`; iOS `UserDefaults(suiteName:)` | One Dart API; package wires prefs + `updateWidget`; Glance `HomeWidgetGlanceStateDefinition` | Stringly keys; JSON you parse twice (Dart + native); not a database | **Yes** |
| **Raw SharedPreferences / UserDefaults** | Same stores, no package | No plugin; full control | You write `updateAppWidget` / `reloadTimelines` and iOS `setAppGroupId` yourself | Keys match this, via the plugin |
| **App-group / `filesDir` file** | JSON / protobuf on disk | Bigger payload; easier versioning | iOS must use the app-group container; more I/O in `getTimeline` (budget-sensitive) | No |
| **SQLite / Core Data in app group** | Shared DB | Query, indexes, migrations | Widget code must be tiny and crash-safe; locking; Glance/RemoteViews still need a projection | No — in-memory domain + prefs snapshot |
| **WorkManager / `BGAppRefresh` / push-to-widget** | Background fetch then write snapshot | Fresh when the app is dead | Battery, entitlements, still no Dart unless you also spin an isolate | No |
| **`home_widget` Flutter bitmap** | Render a Flutter widget to a PNG, show `ImageView` / `Image` | Reuse Flutter UI | No per-row taps; scale/theme issues; larger update payload | No |
| **Widget → Dart callback** (`HomeWidget.registerInteractivityCallback` + background isolate) | Checkbox starts Flutter in the background | One toggle implementation in Dart | Slow cold start; isolate must be tiny; fails if the callback isn’t registered; overkill for flipping a bool | **No** — native toggle writes prefs directly |

**Trade-off we took:** native toggle + shared JSON snapshot. Completing a todo from the home screen works with the Flutter engine dead. The cost is duplicated parse/toggle in Kotlin and Swift, and a resume-sync in Dart.

Do not put tokens, passwords, or PII you would not show on a lock screen into widget storage. Launchers and WidgetKit snapshots can be screenshotted and backed up.

## Size families

Widgets have a small, OS-defined box. This app stores 8 projected rows and **hides** extras per size.

**Android** (`fitTodos` in `TodoWidget.kt`, reused by Glance):

- Title 36 dp + row 40 dp + “more” 32 dp + 32 dp padding.
- Uses actual widget height (`LocalSize` / `OPTION_APPWIDGET_SIZES`).
- Shows “+ N more” when `todos_total - visibleCount > 0`.

**iOS** (`visibleTodoCount`):

| Family | Rows |
|--------|------|
| `systemSmall` | 2 |
| `systemMedium` | 3 |
| `systemLarge` / `systemExtraLarge` | 8 |

Header badge: `+N` remaining, or `N left` / `Done`.

XML RemoteViews cannot grow rows dynamically — the 8 slots are always in the layout, with `GONE` on the unused ones. Glance can `forEach` the visible slice.

## Deep links

Scheme `todowidget`, host `app`:

| URI | Flutter route |
|-----|----------------|
| `todowidget://app/todos` | `/todos` |
| `todowidget://app/todos/{id}` | `/todos/{id}` |
| `todowidget://complete?id=` | **Not** a Flutter route — Android toggle only |

Parser: [`TodoWidgetLink`](../lib/features/todos/presentation/todo_widget_link.dart) (accepts `todowidget://app/todos/…`, `todowidget:///todos/…`, and `?homeWidget` from iOS). Router redirect: [`_widgetDeepLinkRedirect`](../lib/core/router/app_router.dart). Click stream: `HomeWidget.initiallyLaunchedFromHomeWidget()` + `HomeWidget.widgetClicked` in `TodoApp` (skipped in widget tests that inject a router/bloc).

Android:

- Intent filter on `MainActivity`: `todowidget` + `es.antonborri.home_widget.action.LAUNCH`.
- `launchMode=singleTop`. API 34+ `PendingIntent` uses `MODE_BACKGROUND_ACTIVITY_START_ALLOWED` so a widget tap can start the activity from the background.
- Unique request codes (`key.hashCode()` / `31 * "complete".hashCode() + id.hashCode()`) so rows do not share one `PendingIntent`.

iOS:

- `CFBundleURLTypes` scheme `todowidget` in [`ios/Runner/Info.plist`](../ios/Runner/Info.plist).
- `FlutterDeepLinkingEnabled`.
- Widget `Link` adds `?homeWidget` so `home_widget` can tell a widget launch from a random URL.

## Best practices (keep widget and app consistent)

1. **One contract for keys, scheme, limit, class names.** Change `TodoWidgetContract` and the Kotlin/Swift copies together. Drift here is a silent empty widget.
2. **Write a widget projection, not the full entity.** `widget_todos` is `{id, title, completed}` × 8. `todos` stays the full JSON for Flutter + native toggle. Keep `getTimeline` / `onUpdate` cheap.
3. **Save, then refresh.** `HomeWidget.saveWidgetData` then `updateWidget`. A refresh with stale prefs shows the previous list.
4. **Refresh every provider.** This app calls `updateWidget` twice (XML + Glance). `TodoWidgetStore.refresh` updates both after a checkbox tap.
5. **Event-driven refresh, not a timer.** iOS `.never` + `reloadTimelines`. Android 24 h `updatePeriodMillis` only as a backstop.
6. **Native mutations must write the same keys Flutter writes.** Toggle updates `todos`, `widget_todos`, and `todos_total`, then reloads. Otherwise the app overwrites the tap on next save, or “+ N more” is wrong.
7. **Re-read on resume.** Widget taps happen while Flutter is paused or dead. `TodosSyncRequested` on `resumed` is the merge. Do not show a full-screen loader for that path.
8. **Deep-link to a screen, not “open the app”.** Title → list, row → details. Unique `PendingIntent`s / `Link`s per row.
9. **Fit the family; don’t scroll.** No scrolling lists in these widgets. Hide rows and show “+ N more”.
10. **Fail closed.** Bad JSON → empty list, not a crash in the launcher / widget process.
11. **Same Apple team + App Group on app and extension.** Mismatched groups look like “widget never updates”.
12. **Don’t round-trip Dart for a bool.** Native toggle is the reliable path when the engine is cold.

## Setup

### Android

No App Group. `home_widget` uses the app’s default `SharedPreferences`.

1. Receivers in [`AndroidManifest.xml`](../android/app/src/main/AndroidManifest.xml): `TodoWidget`, `TodoGlanceWidgetReceiver`, `TodoWidgetToggleReceiver` (`exported=false`), plus the `todowidget` intent filter on `MainActivity`.
2. Glance: Kotlin Compose plugin + `glance-appwidget` dependency (already in this repo).
3. Signing: debug keys are enough for `flutter run`. Release can keep the default debug signing in this sample (`signingConfig = debug` in `build.gradle.kts`). A real store build needs your upload keystore — same as any Android app; widgets do not add extra signing steps.
4. Install, long-press home → Widgets → **My Todos** and **My Todos (Glance)**.

### iOS (App Groups, signing, entitlements)

The widget is a separate target. It only sees data if **both** the app and the extension are signed with the **same Team** and share the **same App Group**.

| Piece | Value |
|-------|--------|
| App bundle id | `com.example.pdpTodoApp` |
| Extension bundle id | `com.example.pdpTodoApp.TodoWidget` (must be prefixed by the app id) |
| App Group | `group.com.example.pdpTodoApp` |
| Entitlements | [`ios/Runner/Runner.entitlements`](../ios/Runner/Runner.entitlements), [`ios/TodoWidget/TodoWidget.entitlements`](../ios/TodoWidget/TodoWidget.entitlements) |
| Signing | Automatic (`CODE_SIGN_STYLE = Automatic`). **No `DEVELOPMENT_TEAM` is committed** — pick your Personal Team / org in Xcode |
| URL scheme | `todowidget` on Runner |
| Extension deploy | iOS 17.0 |

Xcode (first clone on a new Mac):

1. Open `ios/Runner.xcworkspace` (not the `.xcodeproj`).
2. Select **Runner** and **TodoWidgetExtension** → Signing & Capabilities.
3. Choose a Team. Enable **Automatically manage signing**.
4. Confirm **App Groups** lists `group.com.example.pdpTodoApp` on **both** targets (the `.entitlements` files already declare it; the portal / team must allow that group).
5. `flutter run` on a device or simulator. Then long-press home → **Edit** → **Add Widget** → **Pdp Todo App** → **My Todos**. Swipe the gallery for small / medium / large.

If the widget is empty after the app shows todos: the App Group is missing on one target, or `HomeWidget.setAppGroupId` never ran (`TodoApp` and `HomeWidgetTodoService` both set it). If install fails with a signing error: select a Team on **both** targets.

Physical device: paid or free Apple ID team works for development; the App Group capability must still be present. Free teams sometimes cannot create App Groups on the developer portal — use a paid team if Xcode cannot add `group.com.example.pdpTodoApp`.

## Tests

| Area | File |
|------|------|
| Data source persist / projection / mutex | [`test/unit/home_widget_todo_data_source_test.dart`](../test/unit/home_widget_todo_data_source_test.dart) |
| URI parse | [`test/unit/todo_widget_link_test.dart`](../test/unit/todo_widget_link_test.dart) |
| Resume-style sync | [`test/bloc/todos_bloc_test.dart`](../test/bloc/todos_bloc_test.dart) (`TodosSyncRequested`) |
| Fake storage | [`test/helpers/fake_home_widget_todo_service.dart`](../test/helpers/fake_home_widget_todo_service.dart) |

Native `RemoteViews` / WidgetKit UI is not in `flutter test`. Prove it on a device; screenshots live in [`home_widget_screenshots/`](../home_widget_screenshots/).
