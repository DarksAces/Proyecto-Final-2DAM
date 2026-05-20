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

---

## 7. Configurar Google Sign-In (SHA Fingerprints) ⚠️

El login con Google **fallará con el error [16]** si los SHA fingerprints del keystore no están registrados en Firebase. Debes hacer esto una sola vez por entorno (debug y release).

### 7.1 Obtener el SHA-1 y SHA-256 del keystore de Debug

```powershell
# En PowerShell, desde cualquier directorio:
keytool -list -v -keystore "$env:USERPROFILE\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
```

Copia los valores de `SHA1:` y `SHA256:` que aparecen en la salida.

### 7.2 Obtener los SHA del keystore de Release

```powershell
# Sustituye las rutas y alias por los tuyos:
keytool -list -v -keystore "android\app\upload-keystore.jks" -alias upload
```

Introduce la contraseña del keystore cuando te la pida.

### 7.3 Registrar los SHA en Firebase Console

1. Abre [Firebase Console](https://console.firebase.google.com/) → Selecciona el proyecto **ARte**.
2. Ve a ⚙️ **Configuración del proyecto** → pestaña **General**.
3. En el bloque **"Tus apps"**, selecciona la app Android (`es.arte.app`).
4. Haz clic en **"Añadir huella digital"** y pega el SHA-1 y SHA-256 (tanto de debug como de release).
5. Descarga el nuevo `google-services.json` y reemplaza `android/app/google-services.json`.

### 7.4 Verificar el Web Client ID en Google Cloud

1. Ve a [Google Cloud Console](https://console.cloud.google.com/) → APIs y Servicios → Credenciales.
2. Busca el **OAuth 2.0 Client ID** de tipo "Android" para `es.arte.app`.
3. Comprueba que el SHA-1 listado coincide con el que obtuviste en el paso 7.1/7.2.
4. El **Web Client ID** (tipo "Web application") es el que se usa en `main.dart` como `serverClientId`.

> **Nota:** Cada vez que cambies de keystore o generes uno nuevo, repite este proceso.

### 7.5 Reconstruir la app tras el cambio

```powershell
flutter clean
flutter pub get
flutter run
```
