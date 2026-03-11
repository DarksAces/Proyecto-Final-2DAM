# Flutter Setup Guide for Windows

It seems you are missing both **Flutter** and **Git**. You need both to run this app.

## 1. Install Git (REQUIRED FIRST)
Flutter requires Git to download code dependencies.
1.  Download Git for Windows: [https://git-scm.com/download/win](https://git-scm.com/download/win)
2.  Run the installer. **Just click "Next"** through all the options (the defaults are fine).
3.  Once finished, close any open terminals.

## 2. Download Flutter
1.  Go to the official Flutter install page: [https://docs.flutter.dev/get-started/install/windows](https://docs.flutter.dev/get-started/install/windows).
2.  Download the **stable zip** file (e.g., `flutter_windows_3.x.x-stable.zip`).

## 3. Install Flutter
1.  Extract the zip file to a simple path: `C:\src\flutter`.
    *   **Do not** install it in `C:\Program Files\`.

## 4. Configure Path
1.  Press `Win + S` and search for **"Edit environment variables for your account"**.
2.  In the confusing window that opens, look for the "User variables" section (top half).
3.  Select the **"Path"** variable and click **Edit**.
4.  Click **New** and paste the path to your flutter bin folder:
    `C:\src\flutter\bin`
5.  Click OK, OK, OK.

## 5. Verify
1.  **Close your current VS Code and Terminal entirely** (so it detects the new Path).
2.  Open a NEW PowerShell or Command Prompt.
3.  Run:
    ```powershell
    flutter doctor
    ```
4.  If it prints a summary, you are ready!

## 6. Run the App
Once installed, navigate to the app folder and run:
```powershell
cd c:\Users\admin\Desktop\mapa_flutter
flutter create . --platforms android,ios
flutter run
```
