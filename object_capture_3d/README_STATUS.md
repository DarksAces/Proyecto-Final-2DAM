# Estado del Proyecto: Object Capture 3D

Este documento detalla el estado actual del proyecto, las limitaciones conocidas y las instrucciones críticas para su configuración y ejecución, especialmente en lo relativo a la conectividad.

## 1. Limitaciones de Generación 3D (Prototipo)

**Estado Actual:**
Actualmente, el sistema **NO genera una malla 3D exacta** (fotogrametría real) basada en la forma del objeto fotografiado. Implementar algoritmos como *Structure from Motion* (SfM) o *Multi-View Stereo* (MVS) en Python puro sin dependencias binarias complejas (como COLMAP o Meshroom) es inviable para este entorno de desarrollo.

**Comportamiento Actual:**
- El sistema toma las fotos subidas.
- Genera un **Cubo 3D** (voxels/caja).
- Aplica la **primera foto capturada como textura** en todas las caras del cubo.
- **Resultado visual:** El usuario ve su objeto representado en el espacio 3D, pero con geometría cúbica. Esto sirve como prueba de concepto (PoC) de que el flujo completo (App -> Servidor -> Procesado -> App) funciona.

## 2. Requisitos de Red y Conectividad (CRÍTICO)

Uno de los mayores desafíos durante el desarrollo ha sido la comunicación entre el Móvil (Frontend) y el PC (Backend).

### El Problema
El backend corre en `localhost` (tu PC). El móvil es un dispositivo externo.
- Si el móvil está en **4G/5G**, está en una red distinta (Internet público) y **NO puede ver tu PC** (Red privada).
- Si el móvil está en **Wi-Fi**, a veces los routers aíslan los dispositivos (AP Isolation) o el Firewall de Windows bloquea la conexión entrante.

### La Solución Implementada: Túnel ADB (Recomendada)
Para evitar problemas de Wi-Fi y Firewall, hemos configurado un **túnel directo por cable USB**.

**Requisitos:**
1.  Móvil conectado por USB al PC.
2.  Depuración USB activada en el móvil.
3.  Ejecutar el siguiente comando antes de abrir la app:
    ```powershell
    adb reverse tcp:8080 tcp:8080
    ```
    *Nota: Si `adb` no se reconoce, usar la ruta completa.*

**Configuración en la App:**
El archivo `mobile/.env` está configurado para usar el túnel:
```properties
API_URL=http://127.0.0.1:8080
```
Esto "engaña" al móvil haciéndole creer que el servidor está dentro de él mismo, cuando en realidad viaja por el cable hasta el PC.

## 3. Resumen de Errores Solucionados

*   **`WinError 10013` (Puerto ocupado):** Se cambió el puerto del backend de 8000 a **8080**.
*   **`No route to host` / Conexión rechazada:** Se solucionó usando el **Túnel ADB** y permitiendo tráfico HTTP (Cleartext).
*   **`NET::ERR_CLEARTEXT_NOT_PERMITTED`:** Android bloquea HTTP por defecto. Se creó `network_security_config.xml` para permitir conexiones a `127.0.0.1` y IPs locales estáticamente.
*   **Android Build Fail (v1 embedding):** Se regeneró la carpeta `android/` y se actualizó `minSdk` a **21** para compatibilidad con la cámara.
*   **Crash en Procesado (`ColorVisuals has no uv`):** La librería 3D generaba un cubo sin coordenadas de textura. Se implementó un cálculo manual de UVs para mapear la foto correctamente sobre el cubo.

## 4. Instrucciones de Ejecución Rápida

1.  **Backend:**
    ```powershell
    cd object_capture_3d/backend
    venv\Scripts\python -m app.main
    ```

2.  **Túnel (Cada vez que conectes el cable):**
    ```powershell
    adb reverse tcp:8080 tcp:8080
    ```

3.  **Móvil:**
    ```powershell
    cd object_capture_3d/mobile
    flutter run
    ```
