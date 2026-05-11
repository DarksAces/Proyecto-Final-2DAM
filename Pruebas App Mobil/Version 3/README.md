# ARte Go Map

A Flutter application featuring a MapLibre-based map with ARte-inspired elements, social feed, and AR capabilities.

## Features

- **Interactive Map**: Built with MapLibre GL for high performance.
- **Social Feed**: View and share posts with the community.
- **AR Interaction**: View 3D models and interact with the environment.
- **Firebase Integration**: Authentication, Firestore, and Storage.

## Getting Started

### Prerequisites

- Flutter SDK (>=3.0.0)
- Android Studio / VS Code
- Firebase Project

### Setup

1.  **Clone the repository**:
    ```bash
    git clone <repository-url>
    cd mapa_flutter
    ```

2.  **Install dependencies**:
    ```bash
    flutter pub get
    ```

3.  **Firebase Configuration**:
    - This project uses Firebase. You will need to set up your own Firebase project at [console.firebase.google.com](https://console.firebase.google.com/).
    - Run `flutterfire configure` to generate your `lib/firebase_options.dart` file.
    - Alternatively, place your `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) in the appropriate directories.

4.  **Run the app**:
    ```bash
    flutter run
    ```

## Project Structure

- `lib/`: Core application logic and UI.
- `assets/`: Images and other static resources.
- `android/`, `ios/`, `web/`: Platform-specific configurations.

## License

This project is for educational purposes.
