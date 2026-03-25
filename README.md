# Aura AR - Sistema de Captura y Visualización 3D

Aura AR es un proyecto integral diseñado para cerrar la brecha entre el arte físico y el mundo digital. Utiliza tecnologías de Realidad Aumentada y procesamiento 3D para capturar objetos del mundo real y transformarlos en modelos digitales que pueden ser visualizados en múltiples plataformas.

## 🚀 Descripción General

El sistema permite a los usuarios tomar ráfagas de fotografías de un objeto físico mediante una aplicación móvil. Estas imágenes se envían a un servidor backend que las procesa para generar un modelo 3D (actualmente en fase de prototipo como una caja texturizada). El resultado puede ser visualizado tanto en el dispositivo móvil como en una aplicación de escritorio dedicada y una interfaz web.

## 📂 Estructura del Proyecto

El repositorio está organizado en los siguientes componentes principales:

*   **`object_capture_3d/mobile/`**: Aplicación móvil desarrollada en **Flutter**. Permite realizar la captura de fotos y visualizar el modelo 3D resultante.
*   **`object_capture_3d/backend/`**: Servidor desarrollado en **Python (FastAPI)**. Se encarga de recibir las imágenes y realizar el procesamiento 3D.
*   **`Aura3DReview/`**: Aplicación de escritorio diseñada en **C# (WPF)** para la revisión avanzada de los modelos 3D en PC.
*   **`Web/`**: Una interfaz web sencilla (`nuestra_app.html`) que sirve como punto de entrada o landing page del proyecto.
*   **`Pruebas App Mobil/`** y **`Pruebas App Desktop/`**: Directorios que contienen prototipos previos y pruebas de concepto realizadas durante el desarrollo.

## 🛠️ Stack Tecnológico

| Componente | Tecnología |
| :--- | :--- |
| **Móvil** | Flutter, Dart |
| **Backend** | Python, FastAPI, Trimesh, NumPy |
| **Escritorio** | C#, .NET 9, WPF, Material Design |
| **Web** | HTML5, CSS3, JavaScript |
| **Base de Datos** | Firebase (Integrado en la app de escritorio) |

## ⚙️ Configuración y Ejecución

### 1. Backend (Servidor)
1. Navega a `object_capture_3d/backend`.
2. Instala las dependencias: `pip install -r requirements.txt`.
3. Ejecuta el servidor: `python -m app.main`.
   *   *El servidor correrá por defecto en el puerto 8080.*

### 2. Túnel de Conectividad (CRÍTICO)
Para que el móvil pueda comunicarse con el servidor local en tu PC, se debe usar un túnel ADB (vía cable USB):
1. Conecta el móvil al PC con depuración USB activada.
2. Ejecuta: `adb reverse tcp:8080 tcp:8080`.

### 3. Aplicación Móvil
1. Navega a `object_capture_3d/mobile`.
2. Asegúrate de que el `.env` apunte a `http://127.0.0.1:8080`.
3. Instala dependencias: `flutter pub get`.
4. Ejecuta: `flutter run`.

### 4. Aplicación de Escritorio
1. Abre la solución `Aura3DReview/Aura3DReview.sln` con Visual Studio 2022 o superior.
2. Asegúrate de tener instalado el SDK de .NET 9.
3. Compila y ejecuta el proyecto.

## ⚠️ Estado Actual y Limitaciones
*   **Geometría 3D**: Actualmente, el backend genera un cubo como representación geométrica y aplica la primera imagen capturada como textura (Prueba de Concepto). El flujo completo de datos (App -> Servidor -> Procesado -> App) está totalmente funcional.
*   **Conectividad**: Es indispensable el uso del comando `adb reverse` si no se dispone de una configuración de red que permita tráfico directo entre dispositivos.

---
*Proyecto Final de 2º DAM - Desarrollado para la integración de arte y tecnología.*
