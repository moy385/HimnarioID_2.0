# 🌐 Arquitectura Web: Himnario SaaS (Software as a Service)

Este documento detalla la extensión del proyecto Himnario 2.0 para soportar un entorno 100% web, eliminando la necesidad de instalación (Zero-Install) y permitiendo la sincronización a través de Internet mediante el modelo "Room Code" (estilo Kahoot).

---

## 🏗️ 1. ¿Debemos desarrollar una app web desde cero?

**La respuesta corta es: NO.** 
Gracias a la elección de **Flutter** y a la estructuración basada en *Clean Architecture*, la Interfaz de Usuario (UI) y la Lógica de Negocio (Domain) se reciclan por completo. Flutter permite compilar el mismo código fuente a HTML/JS/WebAssembly para que corra en cualquier navegador.

Lo único que cambia es la **Capa de Infraestructura (Data Layer)**. En lugar de inyectar el repositorio que busca en SQLite y habla por gRPC, inyectaremos un repositorio que consume una API en la nube y se conecta por WebSockets.

---

## 🛠️ 2. Stack Tecnológico (Versión Web)

Para el entorno web, introducimos un Backend centralizado que actuará como intermediario (Broker) entre el navegador del Controlador y el navegador del Display.

*   **Frontend (Cliente/Display):** Flutter Web (compilado a WebAssembly para máximo rendimiento).
*   **Backend (API & Broker):** **ASP.NET Core (C#)**. Ideal para manejar alta concurrencia y conexiones persistentes.
*   **Comunicación en Tiempo Real:** **SignalR** (Integrado en .NET, maneja WebSockets con fallback automático a Server-Sent Events o Long Polling si el navegador tiene restricciones).
*   **Base de Datos (Nube):** **SQL Server** (o PostgreSQL). Alojará la misma estructura relacional (Himnos, Estrofas, Arreglos_Musicales) pero centralizada para todos los usuarios.
*   **Despliegue (Hosting):** Un VPS con **Ubuntu Linux** corriendo contenedores Docker (uno para el Backend .NET y otro para servir los estáticos de Flutter Web), o servicios PaaS como Azure/AWS.

---

## ⚖️ 3. Diferencias Clave: Local vs. Web

| Característica | Versión Local (Instalada) | Versión Web (Navegador) |
| :--- | :--- | :--- |
| **Dependencia de Internet** | Nula (Solo requiere Router Wi-Fi LAN) | **Obligatoria** (Ambos requieren acceso a la nube) |
| **Motor de Base de Datos** | SQLite (Archivo local `.db`) | SQL Server / PostgreSQL (Nube) |
| **Protocolo de Sincronización**| gRPC (Binario, ultra-rápido) | WebSockets vía SignalR (JSON o MessagePack) |
| **Descubrimiento de Dispositivos**| mDNS (Automático en la red local) | **Room Code** (PIN de 4-6 dígitos ingresado manualmente) |
| **Gestión de Archivos (Pistas)**| Almacenamiento local del dispositivo | AWS S3, Cloud Storage o servidor propio de archivos |
| **Latencia Esperada** | < 10 ms (Inmediato) | 50 - 150 ms (Depende de la conexión de ambos) |

---

## 🚀 4. ¿Qué es lo nuevo por desarrollar?

Para habilitar este "sabor" web, el equipo de desarrollo debe construir las siguientes piezas adicionales:

### A. El Backend en .NET Core
1.  **API REST:** Para operaciones CRUD iniciales (Login, buscar himnos, obtener la letra).
2.  **SignalR Hub (`HymnSyncHub`):** La clase que gestionará las "Salas" (Rooms).
    *   Debe tener métodos como `CreateRoom()` (genera el PIN), `JoinRoom(pin)`, `SendCommand(action, payload)`.

### B. El Flujo de "Room Code" en la UI de Flutter
Hay que diseñar dos pantallas nuevas exclusivas para el flujo web:
1.  **Pantalla de Recepción (Display Web):** Un lobby que muestra en grande "Ve a *tuhimnario.com/control* e ingresa el PIN: **7845**".
2.  **Pantalla de Ingreso (Controlador Web):** Un teclado numérico simple para que el músico digite el PIN y se vincule a esa pantalla específica.

### C. Abstracción de Repositorios (Dependency Injection)
Modificar el código de Flutter para que, al arrancar, detecte el entorno:
```dart
if (kIsWeb) {
  // Inyectar dependencias para la Nube
  locator.registerLazySingleton<HymnRepository>(() => CloudHymnRepository(signalRClient, apiService));
} else {
  // Inyectar dependencias para LAN Offline
  locator.registerLazySingleton<HymnRepository>(() => LocalHymnRepository(grpcClient, sqliteDb));
}
```

---

## 🎯 Conclusión de Arquitectura
El sistema se convierte en una plataforma **Híbrida**. Los usuarios que necesiten máxima fiabilidad sin internet descargarán la app local. Las iglesias o usuarios esporádicos que quieran una solución rápida sin instalaciones usarán la versión web, manteniendo la misma experiencia visual y de transposición de acordes en ambas modalidades.
