# ClearQuote Flutter Sample Project

Sample Flutter app showing how to integrate the **ClearQuote SDK** through a platform channel.

Use this as a reference when adding ClearQuote’s native SDK to your own Flutter app.

---

## Supported Platforms

| Platform | Status |
| --- | --- |
| **iOS** | Integrated — ClearQuoteSDK via SPM + `ClearQuotePlugin.swift` |
| **Android** | Not implemented yet |

- Flutter **3.44+** / Dart **3.12+**
- iOS minimum deployment target: **16.0**

---

## Prerequisites

- Flutter SDK
- Valid **ClearQuote SDK key**
- **iOS:** macOS, Xcode **16+** (Swift Package Manager)

---

## Project Layout

| Path | Role |
| --- | --- |
| `lib/main.dart` | App entry; routes to Initialize or Inspection based on `isSDKInitialized` |
| `lib/screens/initialize_screen.dart` | SDK key entry and `initSDK` |
| `lib/screens/inspection_screen.dart` | Client/customer/vehicle inputs, start inspection, logout |
| `lib/clear_quote_sdk.dart` | Dart method/event channel wrapper (shared) |
| `ios/Runner/ClearQuotePlugin.swift` | iOS native bridge to ClearQuoteSDK |
| `ios/Runner/AppDelegate.swift` | Registers `ClearQuotePlugin` on the Flutter engine |

---

## Architecture

```
Flutter UI (lib/)
    ↕ MethodChannel  com.clearquote/sdk
    ↕ EventChannel   com.clearquote/sdk/events
    ├─ iOS     → ClearQuotePlugin.swift → ClearQuoteSDK (SPM)
    └─ Android → (not implemented)
```

---

## Project Setup

```bash
git clone <this-repo>
cd flutter_sample_project
flutter pub get
```

---

## iOS

### Setup

```bash
open ios/Runner.xcworkspace
```

Open the **workspace** (not the `.xcodeproj`). Xcode resolves the ClearQuoteSDK package on first open/build.

### ClearQuoteSDK via Swift Package Manager

Already added to `ios/Runner.xcodeproj`:

| Setting | Value |
| --- | --- |
| Repository | `https://github.com/clearquotetech/cq-ios-sdk.git` |
| Requirement | Branch `main` (resolved to `a983780` / **v0.1.6**) |
| Product linked on Runner | `ClearQuoteSDK` |

Also linked on Runner for SDK runtime: `CoreML`, `MetalPerformanceShaders`, `Accelerate`.

ClearQuoteSDK depends on TensorFlow Lite (`kewlbear/TensorFlowLiteC`). Those binary frameworks omit App Store-required `Info.plist` keys (`CFBundleShortVersionString`, `MinimumOSVersion`). The Runner target includes a **Build Phases** run script named **Fix TensorFlowLite Info.plists** that patches SPM artifacts and the embedded `TensorFlowLiteC` / `TensorFlowLiteCMetal` / `TensorFlowLiteCCoreML` frameworks (and re-signs them) so archive validation does not fail with ITMS-90057 / ITMS-90530.

If you copy this sample into another Flutter iOS app, add the same run script after **Embed Frameworks** (and after Flutter’s **Thin Binary** phase).

### Native bridge

- `ios/Runner/ClearQuotePlugin.swift` — handles method/event channel calls and maps them to ClearQuoteSDK APIs
- Registered in `ios/Runner/AppDelegate.swift` via `FlutterImplicitEngineDelegate`

### Permissions

Configured in `ios/Runner/Info.plist`:

- Camera — vehicle image capture
- Location (When In Use / Always and When In Use) — inspection location and sync
- Background modes: `fetch`, `processing`, `location`

### Run

```bash
flutter run -d ios
```

Or build and run the **Runner** scheme from `ios/Runner.xcworkspace` in Xcode.

---

## Android

Not implemented yet.

---

## App Flow

1. **Launch** — checks `isSDKInitialized`; opens Inspection if already initialized, otherwise Initialize.
2. **Initialize** — enter SDK key → `initSDK` → on success (`code == 200`), navigate to Inspection.
3. **Inspection** — optional client / customer / vehicle / quote fields, offline toggle, start inspection (normal or skip input), manual offline sync, logout.
4. **Completion** — inspection status events are shown via the event channel listener.

---

## Platform Channel API

Shared Dart API in `lib/clear_quote_sdk.dart`. Implemented on **iOS** today.

This sample exposes a subset of ClearQuoteSDK. Additional SDK methods can be wired through the same platform channel — see the [ClearQuote SDK iOS integration doc](https://docs.google.com/document/d/1eqHUg3L7mqA4E8vqslzpLoqoC_8qxv7wTUn_JneKQmY/edit?tab=t.0#heading=h.7jb0pjtyuhqy) AND [ClearQuote SDK Android integration doc](https://docs.google.com/document/d/1qaoIRasNhM7pLG6hKX2aLnKaZr35R-_8GSMnZpDO9Sw/edit?tab=t.0#heading=h.7jb0pjtyuhqy).

### Method channel: `com.clearquote/sdk`

| Method | Dart API | Notes |
| --- | --- | --- |
| `initSDK` | `ClearQuoteSDK.initSDK(key)` | Args: `{ key }`. Returns `{ isInitialized, code, message }` |
| `startInspection` | `ClearQuoteSDK.startInspection(...)` | Args: `{ clientAttrs, inputDetails, userFlowParams }`. Returns `{ started, message, code }` |
| `logout` | `ClearQuoteSDK.logout()` | Clears SDK session |
| `getDealerCode` | `ClearQuoteSDK.getDealerCode()` | Returns `String?` |
| `isSDKInitialized` | `ClearQuoteSDK.isSDKInitialized()` | Returns `bool` |
| `manualOfflineSync` | `ClearQuoteSDK.manualOfflineSync()` | Triggers `initiateOfflineInspectionsSync` |
| `sdkVersion` | `ClearQuoteSDK.getSDKVersion()` | Returns `String` (`getCurrentSDKVersion`) |

#### `startInspection` argument shapes

**`clientAttrs`**

- `userName`, `dealer`, `dealerIdentifier`, `client_unique_id`, `organisationId`

**`inputDetails`**

- `customerDetails`: `name`, `email`, `dialCode`, `phoneNumber`
- `vehicleDetails`: `regNumber`, `make`, `model`, `bodyStyle`, `fuelType`, `variant`
- `quoteData`: `inspectionType`, `fleetImageType`

**`userFlowParams`**

- `isOffline` (`bool`)
- `skipInputPage` (`bool`)

### Event channel: `com.clearquote/sdk/events`

Subscribe with `ClearQuoteSDK.addInspectionCompletionListener(...)`.

Payload fields:

- `identifier`, `message`, `code`, `isOffline`, `serverQuoteId`, `serverInspectionId`

---

## Support

- https://github.com/clearquotetech/cq-ios-sdk/issues
- sharath@clearquote.io
- akhila@clearquote.io

---

## License

For reference and integration purposes only.
