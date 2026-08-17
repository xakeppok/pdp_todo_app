# Platform channels cheat sheet

Short guide for this repo: architecture, codecs, threading, **which channel**, annotated snippets, and the edge cases the suite actually covers.

Knowledge-sharing session, Platform Views, and use-case trade-offs (separate doc): [platform-interop.md](platform-interop.md).

Two stacks sit side by side. Native hosts for both are registered. Dart DI picks **one** `*DataSource` implementation.

| Stack | Dart | Native | Channel names |
|-------|------|--------|----------------|
| Manual | `*PlatformDataSource` | `*Channel.kt` / `*Channel.swift` | `pdp.flutter.app/{battery,connectivity,messages}` |
| Pigeon | `*PigeonDataSource` | `*PigeonApi.kt` / `*PigeonApi.swift` | `dev.flutter.pigeon.pdp_todo_app.*` (generated) |

Swap in `lib/app/di.dart` only via `usePigeonPlatformApis`. Cubit / use case / repository stay on the data-source interface.

## Architecture

```
Dart UI isolate
  Cubit → Use case → Repository  (domain port)
                         ↓
              *DataSource interface   ← data layer
               ↙              ↘
    PlatformDataSource    PigeonDataSource
               ↓              ↓
         Method/Event/      generated HostApi /
         BasicMessageChannel EventChannelApi
               ↓              ↓
         BinaryMessenger  (same engine)
               ↓
  Android main thread / iOS main queue
    BatteryChannel / ConnectivityChannel / MessagesChannel
    BatteryPigeonApi / ConnectivityPigeonStreamHandler / MessagesPigeonApi
    NativeMapViewFactory / MapPigeonStreamHandler
```

- **Domain** never imports `flutter/services.dart` or pigeon `*.g.dart`.
- **Repository** maps raw data (`int`, `Map`, `'wifi'`) → entities.
- **Data source** owns the channel: encode, decode, map `PlatformException` / `MissingPluginException` → `PlatformFailure`.

Registration (both stacks): Android `MainActivity.configureFlutterEngine`, iOS `AppDelegate.didInitializeImplicitFlutterEngine`.

## The three channels

All three are the same pipe (`BinaryMessenger` + a `MessageCodec`). They differ in **shape of the conversation**.

| Channel | Conversation | This app | Default codec |
|---------|--------------|----------|---------------|
| **MethodChannel** | named RPC: `method` + args → one result or error | Battery `%` | `StandardMethodCodec` |
| **EventChannel** | subscribe → stream of events / errors / done | Connectivity | `StandardMethodCodec` |
| **BasicMessageChannel** | one payload in, one payload out; **no** method name | Messages ping/pong | you pass it (`StandardMessageCodec` here) |

### MethodChannel — battery

Request/response with a **method name**. Use when Dart asks native once and waits.

Dart sends `'getBatteryLevel'` with no args. Native `when (call.method)` / `switch call.method`. Unknown methods → `result.notImplemented()`. Business failure → `result.error("UNAVAILABLE", ...)`.

Pigeon equivalent: `@HostApi() BatteryHostApi { int getBatteryLevel(); }`.

### EventChannel — connectivity

Long-lived **stream**. Native implements `StreamHandler`: `onListen` starts watching, `onCancel` tears down.

Dart: `receiveBroadcastStream()`. First listen registers the native callback; last cancel unregisters `NetworkCallback` / `NWPathMonitor`.

Events are strings `'wifi' | 'mobile' | 'none'`. Repository maps them to `ConnectivityStatus`. Unknown string → `PlatformFailure`.

Pigeon equivalent: `@EventChannelApi()` method returns the **event type**, not `Stream`. Generator emits `Stream<ApiConnectivityStatus> connectivityEvents()`.

### BasicMessageChannel — messages

Typed **blob** both ways. No method name, no `MethodCall`. Both ends must agree on codec **and** payload shape.

Here: `Map` with `type` / `id` / `payload`. Dart sends `ping`, native replies `pong` (`android:$payload` / `ios:$payload`). Dart still validates reply type and matching `id`.

Pigeon equivalent: `@HostApi() MessagesHostApi { ApiChannelMessage sendPing(ApiChannelMessage ping); }` — same round-trip, typed DTO instead of `Map`.

## Codecs

A codec is the **binary contract**. Both ends must use the same one or you get silent garbage / decode exceptions.

| Codec | Used by | Encodes |
|-------|---------|---------|
| `StandardMessageCodec` | `BasicMessageChannel` here | `null`, `bool`, `int`, `double`, `String`, typed lists, `List`, `Map` |
| `StandardMethodCodec` | `MethodChannel`, `EventChannel` | envelope around the above: method name + args, or error `{code, message, details}` |
| Pigeon `_PigeonCodec` | generated APIs | `StandardMessageCodec` + extra type bytes (`129+`) for enums / DTOs |

**Dart `int` is not Java `Integer`.** `StandardMessageCodec` sends integers as 64-bit. Native may hand back a 32-bit int, a `Long`, or (accidentally) a `Double` / `String`. The manual battery data source therefore checks `is int` after `invokeMethod<Object?>`. Pigeon codec makes `getBatteryLevel()` return `int` / Kotlin `Long` / Swift `Int64` — the type mismatch tests exist for the **manual** stack, not pigeon.

JSON codec (`JSONMessageCodec`) is **not** used here. Don't mix it with `StandardMessageCodec` on the same channel name.

## Threading

| Side | Thread |
|------|--------|
| Dart | UI isolate. `await channel.invokeMethod` does not block the isolate; it waits on a Future. |
| Android handler | Platform **main** thread |
| iOS handler | Main queue. |
| Event sink | Must be called on the **platform thread**. |

Connectivity callbacks are **not** guaranteed on main:

- Android `ConnectivityManager.NetworkCallback` → hop with `Handler(Looper.getMainLooper()).post { eventSink?.success(status) }`
- iOS `NWPathMonitor` runs on `DispatchQueue(label: "pdp.connectivity")` → hop with `DispatchQueue.main.async` before `eventSink`

Reply once (`result.success` / `result.error` / `notImplemented`). Battery and messages handlers in this app are quick reads/replies.

Pigeon `@HostApi` methods in this contract are native-synchronous (`getBatteryLevel`, `sendPing`). There is no `@async` in `pigeons/platform_apis.dart`. Event sinks still hop to main.

## Decision guide: which channel?

Ask what the conversation looks like — then pick the thinnest API that matches.

| If you need… | Prefer | Don't |
|--------------|--------|-------|
| One named call, one value (`getBatteryLevel`) | **MethodChannel** or Pigeon `@HostApi` | Stream a single read |
| Native pushes updates (`wifi` → `mobile`) | **EventChannel** or Pigeon `@EventChannelApi` | Poll a MethodChannel on a timer |
| Symmetric message / no method name (ping/pong, custom envelope) | **BasicMessageChannel** or Pigeon `@HostApi` + DTO | Fake methods as map keys unless that's the exercise |
| Several methods, shared Android/iOS contract, typed args | **Pigeon** | Hand-sync three stringly APIs |
| Dart `int` vs platform number bugs, missing plugin, background | Keep the **manual** stack + tests | Rely on Pigeon alone (it hides codec surprises) |

**Quick rule:** MethodChannel = RPC, EventChannel = subscribe, BasicMessageChannel = typed blob, Pigeon = generated version of those three.

## Clean Architecture map

```
Widget / Bloc     → BatteryCubit, ConnectivityCubit, MessagesCubit, MapCubit
Use case          → GetBatteryLevel, WatchConnectivity, SendPing, WatchMapClicks
Domain port       → BatteryRepository, …
Data              → *RepositoryImpl → *DataSource
Manual impl       → *PlatformDataSource + *Channel.kt/swift
Pigeon impl       → *PigeonDataSource + generated *.g.* + *PigeonApi
Platform View     → NativeMapPage + NativeMapViewFactory (clicks: MapPigeonStreamHandler)
```

`get_it` registers `BatteryDataSource` (one impl). Same for connectivity, messages, and map.

## Annotated snippets

### MethodChannel — Dart + type check

```dart
// lib/features/battery/data/datasources/battery_platform_data_source.dart
final batteryLevel = await _channel.invokeMethod<Object?>(
  getBatteryLevelMethod, // ← stringly method name
);
if (batteryLevel == null) {
  throw const PlatformFailure('Battery level not available');
}
if (batteryLevel is! int) {
  throw const PlatformFailure('Battery level has unexpected type'); // ← codec surprise
}
return batteryLevel;
```

### MethodChannel — native error vs notImplemented

```kotlin
// android/.../native/BatteryChannel.kt
when (call.method) {
    "getBatteryLevel" -> {
        if (batteryLevel != -1) result.success(batteryLevel)
        else result.error("UNAVAILABLE", "Battery level not available.", null)
    }
    else -> result.notImplemented() // ← Dart: MissingPluginException
}
```

### EventChannel — hop to main before sink

```kotlin
// android/.../native/ConnectivityChannel.kt
private fun emitStatus() {
    val status = currentStatus()
    mainHandler.post {           // ← NetworkCallback may be off main
        eventSink?.success(status)
    }
}
```

```swift
// ios/Runner/Native/ConnectivityChannel.swift
monitor.pathUpdateHandler = { [weak self] path in
    DispatchQueue.main.async {   // ← NWPathMonitor queue is not main
        self?.eventSink?(self?.status(for: path) ?? "none")
    }
}
monitor.start(queue: DispatchQueue(label: "pdp.connectivity"))
```

### BasicMessageChannel — envelope, not methods

```dart
// lib/features/messages/data/datasources/messages_platform_data_source.dart
final reply = await _channel.send(<String, Object?>{
  'type': 'ping',
  'id': id,
  'payload': payload,
});
if (reply is! Map) {
  throw const PlatformFailure('Message has unexpected type');
}
```

### Pigeon — same battery call, typed

```dart
// pigeons/platform_apis.dart  (input; not compiled into the app)
@HostApi()
abstract class BatteryHostApi {
  int getBatteryLevel();
}
```

```dart
// lib/features/battery/data/datasources/battery_pigeon_data_source.dart
return await _api.getBatteryLevel(); // ← generated; no method string, no is int
```

Regenerate after editing the contract:

```bash
dart run pigeon --input pigeons/platform_apis.dart
```

Do not edit `*.g.dart` / `*.g.kt` / `*.g.swift`.

## Edge cases (what the suite covers)

### Missing implementation

No handler, or native `result.notImplemented()`:

- Manual: `MissingPluginException` (`No implementation found…`) → `PlatformFailure`
- Pigeon: `PlatformException(code: channel-error, message: Unable to establish connection on channel: …)` → `PlatformFailure`

Tests: `test/unit/battery_platform_channel_test.dart` (`maps result.notImplemented`, `maps a missing channel handler`); pigeon tests construct `BatteryPigeonDataSource()` without a host.

### Codec / type failures

Manual stack must distrust the payload:

| Payload | Where | Maps to |
|---------|--------|---------|
| `null` | battery MethodChannel | `Battery level not available` |
| `'76'` / `76.0` | battery | `Battery level has unexpected type` |
| non-`String` event | connectivity EventChannel | `Connectivity status has unexpected type` |
| `null` reply | messages | `Messages channel returned null` |
| `type != pong` | messages | `Expected pong reply` |
| `'bluetooth'` | connectivity **repository** | `Unknown connectivity status` (codec was fine; domain mapping failed) |

Pigeon still maps host `FlutterError` / `PigeonError` to `PlatformException`. It does **not** replace validating ping/pong `id` in `MessagesPigeonDataSource`.

### Native business error

Android/iOS `UNAVAILABLE` / `FlutterError` / `PigeonError` → Dart `PlatformException` → `PlatformFailure`. Widget shows **Battery unavailable** + retry (`test/widget/battery_widget_test.dart`).

### Backgrounding

Battery is a **snapshot**, not a stream. Don't call the channel while paused.

```dart
// lib/features/battery/presentation/bloc/battery_cubit.dart
void handleAppLifecycle(AppLifecycleState state) {
  switch (state) {
    case AppLifecycleState.resumed:
      unawaited(getBatteryLevel());
    case AppLifecycleState.inactive:
    case AppLifecycleState.hidden:
    case AppLifecycleState.paused:
    case AppLifecycleState.detached:
      break;
  }
}
```

`BatteryWidget` wires `AppLifecycleListener`. Test `does not hit the channel in background, refreshes on resume` uses `sendAppToBackground` / `sendAppToForeground` from `test/helpers/mock_battery_channel.dart`: calls stay at `1` while paused, increment on resume.

On resume, cubit skips the loading chrome if state is already `BatteryLoaded` (`if (state is! BatteryLoaded) emit(BatteryLoading())`) so the last `%` stays on screen until the new value arrives.

Connectivity **does** keep a native listener while the Dart stream is subscribed; cancel on cubit/widget dispose via `onCancel`.

### EventChannel error path

`handleError` on the Dart stream: `PlatformException` / `MissingPluginException` → `PlatformFailure`; anything else is rethrown with the original stack.

## Tests vs doubles

| Layer | How |
|-------|-----|
| Unit (manual DS) | `setMockMethodCallHandler` / `setMockStreamHandler` / `setMockDecodedMessageHandler` |
| Unit (pigeon DS) | mocktail on `BatteryHostApi` / `MessagesHostApi` |
| Unit (repository) | mocktail on `*DataSource` |
| Widget (battery) | real `BatteryPlatformDataSource` + mock binary messenger + lifecycle |

Channel **name** tests lock the native contract (`pdp.flutter.app/battery`, …). Pigeon names live in generated code; don't hard-code them in app Dart.
