# ClearQuote Flutter Sample Project

SDK integration details are in [ClearQuoteSDK Flutter Integration guide.pdf](<ClearQuoteSDK Flutter Integration guide.pdf>) in this repository.

## Prerequisites

- Flutter SDK **3.44+** (Dart **3.12+**)
- A valid **ClearQuote SDK key**

```bash
git clone <this-repo>
cd flutter-sample-project
flutter pub get
```

On launch, enter the SDK key on the Initialize screen.

## iOS

### Prerequisites

- macOS with Xcode **16+**
- iOS **16.0+** device or simulator

### Run

Open `ios/Runner.xcworkspace` in Xcode and let Swift packages resolve, then run the app:

```bash
flutter run -d <iOS_DEVICE_ID>
```

## Android

### Prerequisites

- Android Studio with Android SDK **36**
- JDK **17**
- Android device or emulator, API **24+**

### Run

```bash
flutter run -d <Android_DEVICE_ID>
```

You can also open the `android` folder in Android Studio and run the **app** configuration.
