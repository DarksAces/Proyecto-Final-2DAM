# Registro de Cambios - Implementación de Borrado de Cuenta

## Fecha: 10 de Diciembre de 2025

### Resumen
Se ha implementado la funcionalidad completa para permitir a los usuarios eliminar su cuenta de forma permanente. Esta acción elimina el acceso a la aplicación y limpia todos los datos asociados al usuario en la base de datos (Firestore) y almacenamiento de archivos (Storage).

### Cambios Realizados

#### 1. Interfaz de Usuario (`lib/screens/settings_screen.dart`)
- **Nueva Sección**: Se añadió una sección "Zona de Peligro" al final de la pantalla de configuración.
- **Botón de Eliminación**: Agregado botón rojo "ELIMINAR MI CUENTA".
- **Confirmación**: Se implementó un cuadro de diálogo (`AlertDialog`) que advierte al usuario sobre la irreversibilidad de la acción antes de proceder.

#### 2. Lógica de Servicio (`lib/api_service.dart`)
- **`deleteAllUserSites(String uid)`**: 
    - Busca todos los "sitios" creados por el usuario.
    - Elimina las imágenes asociadas en Firebase Storage.
    - Elimina los documentos de sitio en Firestore.
- **`deleteUserProfile(String uid)`**:
    - Elimina el documento del perfil público del usuario en la colección `users`.

#### 3. Autenticación (`lib/auth_service.dart`)
- **Actualización en `deleteAccount`**:
    - Se integraron las llamadas a `deleteAllUserSites` y `deleteUserProfile` antes de eliminar la cuenta de autenticación.
    - Flujo de eliminación:
        1. Borrar registro de nickname.
        2. Borrar sitios e imágenes.
        3. Borrar perfil público.
        4. Borrar usuario de Auth (Cierre de sesión automático).

### Verificación
- Se ha verificado que al eliminar la cuenta:
    - El usuario es desconectado.
    - Sus sitios desaparecen del mapa y listas.
    - Su perfil ya no es accesible.
    - Las imágenes se borran para liberar espacio.
