# 📝 Plan de Arquitectura: UI Reactiva y Sincronización de Datos (gRPC LAN)

## 📌 Contexto del Sistema
El proyecto ha logrado establecer con éxito una conexión gRPC bidireccional sobre la red local (LAN) entre la aplicación móvil (Emisor/Control) y la PC de escritorio (Receptor/Display). La conexión registra el estado `ESTABLISHED`.

El siguiente paso es enlazar esta capa de red con la capa de presentación (UI) e implementar la fuente de verdad (Single Source of Truth) para la transferencia de datos (Himnos y Fondos).

---

## 🏛️ 1. Definición Arquitectónica: ¿De dónde vienen los datos?

Para evitar conflictos de desincronización entre las bases de datos de SQLite del celular y la PC, se establecen las siguientes reglas de negocio:

### A. Gestión de Himnos y Letras (El Celular manda el contenido)
* **Duda resuelta:** Cuando el usuario busca un himno en su celular, la búsqueda se hace en la **base de datos local del celular** (para garantizar la velocidad y el funcionamiento offline).
* **El Transporte:** Al seleccionar un himno, el celular NO debe enviar solo el `ID` del himno a la PC (porque el ID #4 en el celular podría ser distinto al ID #4 en la PC si hay arreglos personalizados). El celular debe enviar el **Objeto Completo** (Título, Estrofas, Orden) empaquetado en un mensaje gRPC a la PC.
* **La PC:** Simplemente recibe el texto y lo dibuja en la pantalla negra, actuando como un "monitor tonto".

### B. Gestión de Fondos y Apariencia (La PC es la dueña)
* **Duda resuelta:** Los archivos multimedia (videos `.mp4` o imágenes `.jpg`) pesan mucho y residen físicamente en el disco duro de la PC. El celular no puede mandar un video por la red local cada vez que cambia el fondo porque colapsaría la red.
* **El Transporte:** Al conectarse, el celular hace una petición gRPC a la PC (`ObtenerFondosDisponibles()`). La PC responde con una lista de IDs y Nombres (ej. `[1: "Cielo Azul", 2: "Cruz"]`).
* **El Celular:** Muestra esta lista en su menú de brocha. Cuando el usuario elige "Cielo Azul", el celular solo manda una orden ligera: `CambiarFondo(id: 1)`. La PC recibe el ID, busca el archivo en su disco y lo proyecta.

---

## 🔄 2. Flujo de Interfaz Reactiva

### En la PC (Receptor / Display)
1.  **Escucha Activa:** El servidor gRPC (`GrpcDisplayServer`) detecta el evento de un nuevo cliente conectado.
2.  **Cambio de Estado:** Llama al gestor de estado (Provider/Riverpod) y cambia `isClientConnected = true`.
3.  **Apertura de Ventana:** Este cambio de estado dispara automáticamente el mismo método que ya existe para el botón "Proyectar". Abre la segunda ventana independiente (fondo negro) y la pone en estado de "Esperando instrucciones...".
4.  **Recepción de Datos:** Cada vez que el servidor gRPC recibe un método `ProyectarEstrofa(texto)`, actualiza el estado de la ventana secundaria para renderizar la letra.

### En el Celular (Emisor / Control)
1.  **Conexión Exitosa:** Al dar `ESTABLISHED`, el estado global cambia a `isConnectedToDisplay = true`.
2.  **Dashboard Alterado:** La app redirige a la pantalla principal con la barra de búsqueda de himnos.
3.  **Navegación Condicionada:** Al tocar un himno de la lista:
    * *Si `isConnectedToDisplay == false`:* Abre la vista escrolleable normal para leer en el celular.
    * *Si `isConnectedToDisplay == true`:* Navega a la vista `RemoteControlPanel`. Envía el himno completo por gRPC a la PC, y en la pantalla del celular solo muestra los botones: flechas izquierda/derecha, brocha (con la lista de fondos traída de la PC), etc.

---

## 🚀 3. Instrucciones de Implementación para el Agente (To-Do List)

1.  **Actualizar `hymn_control.proto`:**
    * Asegúrate de tener un servicio bidireccional o métodos definidos como:
        * `rpc SendHymnContent (HymnPayload) returns (Response);`
        * `rpc GetAvailableBackgrounds (Empty) returns (BackgroundList);`
        * `rpc SetBackground (BackgroundRequest) returns (Response);`
    * Regenera los archivos `.pb.dart` usando el compilador de `protoc`.
2.  **Modificar el Estado de la UI en Celular:**
    * En la lista de resultados de búsqueda (`HymnListWidget` o similar), envuelve el `onTap` en una condicional basada en el estado de conexión para rutear al `RemoteControlPanel`.
3.  **Refactorizar el `RemoteControlPanel` (Celular):**
    * Al inicializarse (en el `initState` o en el Provider vinculado), debe consumir `GetAvailableBackgrounds()` del cliente gRPC.
    * Al presionar la flecha derecha, extrae el texto de la siguiente estrofa y ejecuta `SendHymnContent(texto)`.
4.  **Conectar el Servidor gRPC con la Ventana (PC):**
    * En la implementación del servicio en Dart (PC), inyecta la referencia al gestor de estado global (o usa un `StreamController`).
    * Cuando un cliente se conecte exitosamente, invoca la lógica de soporte multi-ventana (el paquete `desktop_multi_window` o la lógica nativa existente) para renderizar la vista de presentación.