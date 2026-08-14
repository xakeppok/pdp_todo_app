# Flutter platform interop — wiki & knowledge-sharing session

Team wiki for **when to use which native bridge**, plus a runnable session that walks the demos in this app.

The repo cheat sheet (codecs, threading, annotated snippets, test doubles) stays in [platform-channels.md](platform-channels.md). Do not merge them.

Official references used by this app’s APIs: [Platform channels](https://docs.flutter.dev/platform-integration/platform-channels), [Pigeon](https://pub.dev/packages/pigeon) (`^27.3.0` here), [Android platform views](https://docs.flutter.dev/platform-integration/android/platform-views), [iOS platform views](https://docs.flutter.dev/platform-integration/ios/platform-views).

## Runnable demos (this app)

| Topic | What you do | What you should see | Dart | Native |
|-------|-------------|---------------------|------|--------|
| **MethodChannel** | Todos screen, tap the battery card | `%` from `BatteryManager` / `UIDevice`; background the app, resume → refresh | [`battery_platform_data_source.dart`](../lib/features/battery/data/datasources/battery_platform_data_source.dart) | [`BatteryChannel.kt`](../android/app/src/main/kotlin/com/example/pdp_todo_app/native/BatteryChannel.kt) / [`BatteryChannel.swift`](../ios/Runner/Native/BatteryChannel.swift) |
| **EventChannel** | Stay on Todos; toggle Wi‑Fi / cellular / airplane | Banner switches `wifi` / `mobile` / `none` | [`connectivity_platform_datasource.dart`](../lib/features/connectivity/data/datasources/connectivity_platform_datasource.dart) | [`ConnectivityChannel.kt`](../android/app/src/main/kotlin/com/example/pdp_todo_app/native/ConnectivityChannel.kt) / [`ConnectivityChannel.swift`](../ios/Runner/Native/ConnectivityChannel.swift) |
| **BasicMessageChannel** | App bar sync icon → type payload → **Ping** | Log: `ping` then `pong` with `android:…` / `ios:…` and matching `id` | [`messages_platform_data_source.dart`](../lib/features/messages/data/datasources/messages_platform_data_source.dart) | [`MessagesChannel.kt`](../android/app/src/main/kotlin/com/example/pdp_todo_app/native/MessagesChannel.kt) / [`MessagesChannel.swift`](../ios/Runner/Native/MessagesChannel.swift) |
| **Pigeon** (typed twins + map clicks) | Default DI already uses Pigeon | Same UI; generated APIs instead of `pdp.flutter.app/*` | [`pigeons/platform_apis.dart`](../pigeons/platform_apis.dart), `*PigeonDataSource` | `*PigeonApi.kt` / `.swift`, `*PigeonStreamHandler` |
| **Platform View** + Pigeon events | App bar map icon → pan/zoom → tap | MapLibre map; bottom banner shows `lat, lng` | [`native_map_page.dart`](../lib/features/native_map/presentation/pages/native_map_page.dart) | [`NativeMapView.kt`](../android/app/src/main/kotlin/com/example/pdp_todo_app/native/NativeMapView.kt) / [`NativeMapView.swift`](../ios/Runner/Native/NativeMapView.swift) |

Swap **manual vs Pigeon** for battery / connectivity / messages in [`lib/app/di.dart`](../lib/app/di.dart) only (one `*DataSource` registration). Both native hosts are always registered on Android/iOS. The map has **no** manual-channel twin — clicks go through Pigeon `@EventChannelApi onMapClick()`.

UI entry points:

- Battery + connectivity banners: [`todos_page.dart`](../lib/features/todos/presentation/pages/todos_page.dart)
- Messages: route `/messages`
- Native map: route `/native-map`

---

## Shared model

- **Channels** move bytes (a request, a stream of events, a typed blob).
- **Platform Views** embed a native `UIView` / `android.view.View` in the Flutter widget tree (`AndroidView` / `UiKitView`).
- This map still needs a channel: taps go through Pigeon `onMapClick()`, not through the view widget itself.

Domain never imports `flutter/services.dart` or `*.g.dart`. The data source owns encode / decode / `PlatformException` → `PlatformFailure`. Codecs, threading, error matrix: [platform-channels.md](platform-channels.md).

**This app:** MethodChannel = battery, EventChannel = connectivity, BasicMessageChannel = messages ping/pong, Pigeon = typed twins of those plus map clicks, Platform View = MapLibre on `/native-map`.

---

## 1. MethodChannel

### What it is

Named RPC over `StandardMethodCodec`. Dart sends a **method string** + args; native replies **once** with success, error, or `notImplemented()`.

```text
invokeMethod("getBatteryLevel")  →  int  |  PlatformException  |  MissingPluginException
```

### Use when

- Dart asks native **once** and waits: here, `getBatteryLevel` → `int`.

### Do not use when

- Native must **push** changes (`wifi` → `mobile`). That is EventChannel in this app.

Manual and Pigeon battery hosts are both registered. Default DI is `BatteryPigeonDataSource`; uncomment `BatteryPlatformDataSource.new` in `di.dart` to hit `pdp.flutter.app/battery`.

### Trade-offs

| + | − |
|---|---|
| Easy to mock (`setMockMethodCallHandler`) | Stringly method names (`getBatteryLevel`) on Dart / Kotlin / Swift |
| `result.error` → `PlatformException`; `notImplemented` → `MissingPluginException` | Manual stack must check `is int` (see [platform-channels.md](platform-channels.md)) |

### Demo walkthrough

1. `flutter run` → Todos. Battery card reads `%` via `GetBatteryLevel` → repository → data source.
2. Tap the card to refresh (same one-shot call).
3. Background the app: cubit does not hit the channel while paused; resume refreshes. See [`battery_cubit.dart`](../lib/features/battery/presentation/bloc/battery_cubit.dart).
4. In `di.dart`, Pigeon is the default. Uncomment `BatteryPlatformDataSource.new` to show the manual channel — UI stays the same.

Tests: [`test/unit/battery_platform_channel_test.dart`](../test/unit/battery_platform_channel_test.dart).

---

## 2. EventChannel

### What it is

Long-lived **stream**. Native implements `StreamHandler`: `onListen` starts watching, `onCancel` tears down. Dart: `receiveBroadcastStream()`.

```text
listen  →  "wifi" | "mobile" | "none"  →  …  →  cancel
```

### Use when

- Native pushes updates: here, connectivity `'wifi' | 'mobile' | 'none'`. Map clicks use the same *shape* via Pigeon `@EventChannelApi onMapClick()`, not `pdp.flutter.app/connectivity`.

### Do not use when

- There is only a single read (`getBatteryLevel`). That is MethodChannel / `@HostApi` here.

### Trade-offs

| + | − |
|---|---|
| Native pushes; Dart listens | Last Dart cancel must unregister `NetworkCallback` / `NWPathMonitor` |
| Matches `NetworkCallback` / `NWPathMonitor` | Event sink is posted to main (`Handler` / `DispatchQueue.main.async`) |

### Demo walkthrough

1. Stay on Todos. Connectivity banner is a live subscription (`WatchConnectivity`).
2. Toggle airplane mode / Wi‑Fi. Banner updates without a tap.
3. Android: `Handler(Looper.getMainLooper()).post` before `eventSink`. iOS: `DispatchQueue.main.async`. Same in the Pigeon stream handlers and in [platform-channels.md](platform-channels.md).
4. Optional: swap `ConnectivityPlatformDataSource` in `di.dart`.

Tests: [`test/unit/connectivity_platform_channel_test.dart`](../test/unit/connectivity_platform_channel_test.dart). Unknown string `'bluetooth'` fails in the **repository** (`connectivity_repository_test.dart`), not the codec.

---

## 3. BasicMessageChannel

### What it is

One payload in, one payload out. **No method name**, no `MethodCall` envelope. Both ends use `StandardMessageCodec`.

```text
{ type: ping, id, payload }  →  { type: pong, id, payload: "android:…" | "ios:…" }
```

In this app Dart `send`s; native `setMessageHandler` replies. JSON codec is not used ([platform-channels.md](platform-channels.md)).

### Use when

- Envelope without a method name: here, ping `Map` → pong `Map` with `type` / `id` / `payload`.

### Do not use when

- Named RPC (`getBatteryLevel`) — MethodChannel / `@HostApi`.
- Native-initiated stream — EventChannel / `@EventChannelApi`.

### Trade-offs

| + | − |
|---|---|
| Codec is explicit (`StandardMessageCodec`) | Envelope is a `Map`; Dart checks `type == pong` and matching `id` |
| Native replies on the same send | Page subtitle still says `BasicMessageChannel: ping → pong` even when DI is `MessagesPigeonDataSource` |

### Demo walkthrough

1. App bar sync icon → `/messages`.
2. Default text field is `hello`. Ping. Expect a pong with the same `id` and `android:hello` / `ios:hello`.
3. Default DI is Pigeon (`MessagesPigeonDataSource`). Uncomment `MessagesPlatformDataSource.new` to hit `pdp.flutter.app/messages`. Dart still validates pong + `id` on both stacks.

Tests: [`test/unit/messages_platform_channel_test.dart`](../test/unit/messages_platform_channel_test.dart), widget: [`test/widget/messages_page_test.dart`](../test/widget/messages_page_test.dart).

---

## 4. Pigeon

### What it is

Codegen over the same `BinaryMessenger`. Contract: [`pigeons/platform_apis.dart`](../pigeons/platform_apis.dart). Generate with `dart run pigeon --input pigeons/platform_apis.dart`. Do not edit `*.g.dart` / `*.g.kt` / `*.g.swift`.

| Manual | Pigeon |
|--------|--------|
| MethodChannel `getBatteryLevel` | `@HostApi() BatteryHostApi { int getBatteryLevel(); }` |
| BasicMessageChannel ping/pong `Map` | `@HostApi() MessagesHostApi { ApiChannelMessage sendPing(...); }` |
| EventChannel connectivity strings | `@EventChannelApi() connectivityEvents()` → `Stream<ApiConnectivityStatus>` |
| *(no manual twin)* | `@EventChannelApi() onMapClick()` → `Stream<ApiMapClick>` |

Pigeon `@EventChannelApi` methods return the **event type**, not `Stream`. The generator emits the Dart `Stream`. This app puts both event methods on `PlatformEventApi` — Pigeon allows only one `@EventChannelApi` per definition file.

### Use when

- Shared Android/iOS contract with types: `BatteryHostApi`, `MessagesHostApi`, `PlatformEventApi`.

### Do not use when

- You are exercising codec surprises on the **manual** stack. This repo keeps both; default DI is Pigeon.

### Trade-offs

| + | − |
|---|---|
| One contract file; no method-name drift | Must regenerate after editing `pigeons/platform_apis.dart` |
| Typed enums / DTOs (`ApiConnectivityStatus`, `ApiChannelMessage`, `ApiMapClick`) | Manual `is int` tests do not apply to the Pigeon battery API |
| `@EventChannelApi` typed streams | Setup still required: `BatteryHostApi.setUp` / `*StreamHandler.register` |

### Demo walkthrough

1. Open [`pigeons/platform_apis.dart`](../pigeons/platform_apis.dart): `@ConfigurePigeon` outputs + the two `@HostApi`s + `@EventChannelApi`.
2. Open [`di.dart`](../lib/app/di.dart): `BatteryPigeonDataSource.new` (manual line commented). Cubit / use case / repository stay on the data-source interface.
3. Dart call site: [`battery_pigeon_data_source.dart`](../lib/features/battery/data/datasources/battery_pigeon_data_source.dart) — `await _api.getBatteryLevel()`.
4. Registration: [`MainActivity.kt`](../android/app/src/main/kotlin/com/example/pdp_todo_app/MainActivity.kt) `BatteryHostApi.setUp`, `ConnectivityEventsStreamHandler.register`, `OnMapClickStreamHandler.register`. Same idea in [`AppDelegate.swift`](../ios/Runner/AppDelegate.swift).

```bash
dart run pigeon --input pigeons/platform_apis.dart
```

Pigeon data-source tests mock the generated API (`BatteryHostApi`), not the binary messenger: [`test/unit/battery_pigeon_data_source_test.dart`](../test/unit/battery_pigeon_data_source_test.dart).

---

## 5. Platform Views

### What it is

A native view hosted in Flutter’s render tree. Dart uses `AndroidView` / `UiKitView` with `viewType: 'native-map'`. Native registers a factory that returns a `PlatformView`.

This is not a fifth channel type. The map talks to Dart through Pigeon `onMapClick`.

```text
AndroidView / UiKitView (viewType: "native-map")
    → NativeMapViewFactory
    → MapLibre MapView / MLNMapView
    → tap → MapPigeonStreamHandler.emit(lat, lng)
    → Dart MapCubit → banner
```

### Use when

- Native UI that this app does not draw in Flutter: MapLibre (`MapView` / `MLNMapView`) on `/native-map`.

### Do not use when

- You only need data from native (battery, connectivity, ping/pong). Those are channels.

### Trade-offs

| + | − |
|---|---|
| MapLibre in the widget tree | Android `MapView` lifecycle forwarded from `DefaultLifecycleObserver` |
| Native pan/zoom/tap | Dart `EagerGestureRecognizer`; iOS `FlutterPlatformViewGestureRecognizersBlockingPolicyEager` |
| Clicks still go through Pigeon `onMapClick` | Not Android/iOS: fallback text in `_NativeMapView` |

What the code does:

- Dart: `AndroidView` / `UiKitView`, `viewType: 'native-map'` ([`native_map_page.dart`](../lib/features/native_map/presentation/pages/native_map_page.dart)).
- Android factory: [`NativeMapViewFactory.kt`](../android/app/src/main/kotlin/com/example/pdp_todo_app/native/NativeMapViewFactory.kt), registered in `MainActivity.configureFlutterEngine`.
- iOS factory: [`NativeMapViewFactory.swift`](../ios/Runner/Native/NativeMapViewFactory.swift), registered in `AppDelegate.didInitializeImplicitFlutterEngine` with `gestureRecognizersBlockingPolicy: FlutterPlatformViewGestureRecognizersBlockingPolicyEager`.
- Style URL: `https://demotiles.maplibre.org/style.json`.

### Demo walkthrough

1. App bar map icon → `/native-map`. MapLibre demo tiles (needs network).
2. Pan / pinch. `EagerGestureRecognizer` is set on both `AndroidView` and `UiKitView`.
3. Tap. Banner shows `lat, lng` from `MapClick.label`. Path: native click → [`MapPigeonStreamHandler`](../android/app/src/main/kotlin/com/example/pdp_todo_app/native/MapPigeonStreamHandler.kt) / [Swift twin](../ios/Runner/Native/MapPigeonStreamHandler.swift) → `onMapClick()` → [`MapPigeonDataSource`](../lib/features/native_map/data/datasources/map_pigeon_data_source.dart) → `MapCubit`.
4. Android: [`NativeMapView.kt`](../android/app/src/main/kotlin/com/example/pdp_todo_app/native/NativeMapView.kt) implements `DefaultLifecycleObserver` and forwards `onCreate`…`onDestroy` to `MapView`. `destroyed` prevents a second teardown from `dispose()`.
5. Leaving the page: `MapCubit.close()` cancels the Dart subscription → native `onCancel` clears the event sink. The factory stays registered on the engine.

`viewType` / `withId` must match (`native-map`).

Tests: [`test/widget/native_map_page_test.dart`](../test/widget/native_map_page_test.dart) (`AndroidView` / `UiKitView` / fallback, banner from cubit). Navigation: [`todos_page_test.dart`](../test/widget/todos_page_test.dart). Stream: `map_pigeon_data_source_test.dart`, `map_cubit_test.dart`. They do not load MapLibre tiles.

---

## Decision matrix

| If you need… | This app |
|--------------|----------|
| One named call, one value | **MethodChannel** / Pigeon `@HostApi` — battery |
| Native pushes updates | **EventChannel** / Pigeon `@EventChannelApi` — connectivity, map clicks |
| Envelope without a method name | **BasicMessageChannel** / Pigeon `@HostApi` + DTO — messages |
| Typed Android+iOS contract | **Pigeon** — `pigeons/platform_apis.dart` |
| Native UI | **Platform View** + Pigeon stream — MapLibre |

---

## Clean Architecture (all demos)

```
Widget / Cubit     BatteryCubit, ConnectivityCubit, MessagesCubit, MapCubit
Use case           GetBatteryLevel, WatchConnectivity, SendPing, WatchMapClicks
Domain port        *Repository
Data               *RepositoryImpl → *DataSource
Manual impl        *PlatformDataSource + *Channel.kt/swift
Pigeon impl        *PigeonDataSource + generated *.g.* + *PigeonApi / *StreamHandler
Platform View      NativeMapPage (AndroidView / UiKitView) + NativeMapViewFactory
```

`configureDependencies()` in [`lib/app/di.dart`](../lib/app/di.dart) registers one `*DataSource` per feature. Router: `createConfiguredRouter()`. `TodoApp` and `FailureModeToggleButton` also call `getIt`.

---

## Session pitfalls to say out loud

1. **Same channel name + same codec on both ends.** Manual: `pdp.flutter.app/{battery,connectivity,messages}`. Pigeon: generated `dev.flutter.pigeon.pdp_todo_app.*`. JSON codec is not used ([platform-channels.md](platform-channels.md)).
2. **Event sink thread.** Connectivity and map clicks hop to main before `success`.
3. **Reply exactly once** on MethodChannel (`success` *or* `error` *or* `notImplemented`) — [`BatteryChannel.kt`](../android/app/src/main/kotlin/com/example/pdp_todo_app/native/BatteryChannel.kt).
4. **Pigeon:** edit `pigeons/platform_apis.dart`, regenerate; do not edit `*.g.*`.
5. **Android map lifecycle:** [`NativeMapView.kt`](../android/app/src/main/kotlin/com/example/pdp_todo_app/native/NativeMapView.kt) uses `destroyed` so `onDestroy` / `dispose` do not tear down twice.
6. **Gestures:** `EagerGestureRecognizer` on Dart; iOS `FlutterPlatformViewGestureRecognizersBlockingPolicyEager` on the factory.
7. **Backgrounding:** battery cubit skips the channel while paused; connectivity stays subscribed until cancel ([platform-channels.md](platform-channels.md)).
8. **Tests:** widget tests find `AndroidView` / `UiKitView`; they do not load tiles.

More edge cases (missing plugin, type mismatches, lifecycle tests): [platform-channels.md](platform-channels.md).

---

