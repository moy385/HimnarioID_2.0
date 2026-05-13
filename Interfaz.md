# 🖥️ Diseño de Vistas, Flujo de Usuario y Requerimientos (Himnario 2.0)

> **Nota importante sobre versiones:** Este documento describe la versión **LOCAL** del himnario (aplicación que corre en la PC del operador y se conecta al celular). La versión web tendrá un camino de desarrollo diferente que se abordará en una fase posterior.

---

## 🗺️ 1. Modelo de Arquitectura General

El ecosistema HimnarioID 2.0 funciona como un sistema **cliente-servidor local**:

- **Display (PC/TV):** Servidor principal - muestra la letra en pantalla grande y recibe comandos
- **Controlador (Móvil):** Cliente - busca himnos, ajusta configuraciones y envía comandos de navegación

> La comunicación entre ambos dispositivos ocurre exclusivamente en la red local (LAN/WiFi), sin depender de Internet.

---

## 🗺️ 2. Flujo del Usuario (User Flow)

### A. Flujo del Controlador (App Móvil - Android/iOS)

1. **Inicio y Conexión (Discovery):** El músico abre la app. En segundo plano, mDNS escanea la LAN buscando la PC donde está corriendo la app Display. El sistema notifica: *"Conectado a Pantalla Principal"* o *"Buscando Display..."*.

2. **Dashboard (Home):** El usuario ve un buscador central y filtros rápidos (Oficiales, Inspiradas, Convenciones).

3. **Selección de Himno:** El usuario selecciona un himno por número o título.
   - Entra a la **Vista de Detalle**. Aquí ve la letra completa con acordes y la tonalidad original.
   - **Formato Móvil:** A diferencia de la PC, en móvil la letra se muestra **entera en una sola pantalla** con scroll vertical. Esto permite al músico ver todas las estrofas de un vistazo.

4. **Decisión de Flujo:**
   - *Ruta 1 (Proyectar Directo):* Presiona el botón "Proyectar". Pasa a la **Pantalla Live**.
   - *Ruta 2 (Transponer):* Usa los botones `+1` / `-1` para ajustar el tono. Los acordes en pantalla cambian al instante. Luego presiona "Proyectar".
   - *Ruta 3 (Personalizar/Fork):* Presiona "Crear Arreglo". Se abre el **Editor Visual**. Modifica los acordes, guarda (se asocia a su ID de `Usuario`) y luego proyecta.

5. **Control en Vivo (Pantalla Live):** El usuario usa botones de navegación para comandar la PC en tiempo real.

### B. Flujo del Display (App PC / Windows / Smart TV)

1. **Standby (Espera):** La aplicación se abre en pantalla completa. Muestra un fondo sobrio, el nombre de la red Wi-Fi y la leyenda *"Esperando conexión del controlador..."*.

2. **Proyección en Vivo (Live Mode):** Recibe el payload por gRPC. La pantalla hace una transición suave y muestra el título del himno.

3. **Navegación:** A medida que el celular envía comandos, la letra en pantalla hace transiciones de fundido (Fade In/Out) entre estrofas.

---

## 📱 3. Estructura de Vistas y Contenido

### 🟢 Aplicación Controlador (Móvil)

#### 1. Pantalla de Inicio / Buscador
* **Barra de Búsqueda:** Campo de texto prominente para búsqueda por **número** o **título** del himno.
* **Chips de Filtrado:** [Todos] [Oficiales] [Inspiradas] [Por Categoría].
* **Indicador de Conexión:** Un icono de estado en la barra superior (Verde: Conectado a TV, Rojo: Modo Offline puro).
* **Listado de Resultados:** Lista de himnos con número, título y primeras líneas de la primera estrofa.

#### 2. Vista de Detalle del Himno
* **Formato Scroll (Diferencia clave con PC):** La letra completa del himno se muestra en **una sola pantalla** con scroll vertical. El músico puede ver todas las estrofas y coros de un vistazo sin necesidad de navegar.
* **Cabecera:** Título, Número, Categoría y Versión de País.
* **Cuerpo:** Scroll con la letra y acordes intercalados (Renderizado desde el texto ChordPro).
* **Barra de Herramientas Inferior (Sticky):**
  * Controles de Transposición: `[ - ] Tono: G [ + ]`
  * Botón Play (para escuchar pista de audio asociada).
  * Botón FAB (Floating Action Button) grande: **"PROYECTAR"**.
  * Menú de 3 puntos: Opción "Crear Arreglo Personalizado".

#### 3. Pantalla Live (Control Remoto)
* **Vista Previa:** Muestra qué estrofa está actualmente en la pantalla de la PC y cuál es la siguiente.
* **Botonera Táctica (Diseñada para no mirar el celular):**
  * Botón Gigante: **Siguiente** (Ocupa el 40% de la pantalla).
  * Botón Grande: **Anterior**.
  * Botones de salto rápido: `[Ir al Coro]`, `[Ir al Inicio]`, `[Apagar Pantalla / Blackout]`.
* **Panel de Configuración en Tiempo Real (Side Panel o Modal):**
  * Selector de fondo (Negro, Imagen, Color sólido)
  * Control de tamaño de fuente (Pequeño, Mediano, Grande, Extra Grande)
  * Selector de siguiente estrofa (para verificar cuál viene después)
  * Control de velocidad de transición

#### 4. Editor de Arreglos (Modo Edición)
* **Lienzo de Letra:** La letra del himno donde cada palabra es "tocable".
* **Selector Musical:** Un teclado o rueda inferior que aparece al tocar una palabra para insertar un acorde nuevo.
* **Botón Guardar:** Guarda el arreglo en la tabla `Estrofa_Arreglo` vinculado al `Usuario` actual.

### 🔵 Aplicación Display (PC/Windows/TV)

#### 1. Pantalla de Proyección
* **Cero UI:** No hay botones, ni menús, ni cursores de mouse visibles.
* **Contenedor Principal:** Texto renderizado en tamaño masivo (tipografía sans-serif de alto contraste).
* **Soporte de Fondos:** Capacidad de mostrar fondos negros (para proyectores), videos en loop sutiles o imágenes estáticas sin opacar la letra.
* **Transiciones:** Efectos de fundido suave entre estrofas (Fade In/Out).

---

## 🔗 4. Conexión Remota (Control Remoto)

### Mecanismo de Comunicación
* **Protocolo:** gRPC sobre HTTP/2 en la red local.
* **Descubrimiento:** mDNS (Avahi/Bonjour) para detectar automáticamente la PC en la LAN.
* **Puerto:** Configurable (por defecto 50051).

### Comandos Sincronizados
| Comando | Descripción |
|---------|-------------|
| `ShowHimno(id)` | Carga y muestra un himno específico |
| `NextStanza()` | Avanza a la siguiente estrofa/coro |
| `PrevStanza()` | Retrocede a la anterior |
| `GoToStanza(n)` | Salta a una estrofa específica |
| `SetConfig(fondo, tamaño)` | Cambia configuración de visualización |
| `Blackout()` | Limpia la pantalla inmediatamente |
| `PlayAudio()` / `StopAudio()` | Control de pista de audio |

### Orden Fijo de Estrofas
El sistema maneja un **orden fijo predefinido** para la navegación:
> Estrofa 1 → Coro → Estrofa 2 → Coro → Estrofa 3 → Coro → ... → Puente → Estrofa Final

Este orden está codificado en la estructura del himno y el botón "Siguiente" siempre respeta esta secuencia predeterminada.

---

## 📋 5. Requerimientos del Sistema

### ⚙️ Requerimientos Funcionales (RF)
1. **Transposición Automática:** El sistema debe calcular y renderizar el cambio de acordes de la escala cromática de manera instantánea al presionar los controles de tono.
2. **Sincronización LAN:** El celular debe poder enviar comandos de cambio de estrofa a la PC mediante gRPC.
3. **Manejo de Arreglos:** El sistema debe permitir derivar (forkear) un himno oficial, guardando las modificaciones bajo el identificador del `Usuario` creador sin mutar el texto oficial.
4. **Reproducción de Pistas:** El sistema móvil debe listar y reproducir archivos de audio locales vinculados al himno.
5. **Modo Blackout:** El controlador debe poder enviar un comando de emergencia para limpiar la pantalla de proyección instantáneamente.
6. **Resolución ChordPro:** El sistema debe parsear el formato `[Acorde]Texto` para renderizar el acorde exactamente sobre la sílaba correspondiente.
7. **Configuración en Tiempo Real:** El controlador debe poder modificar fondo, tamaño de fuente y otros parámetros de visualización mientras se proyecta, sin interrumpir la presentación.
8. **Descubrimiento Automático:** La app móvil debe detectar automáticamente la PC en la red local mediante mDNS sin necesidad de configuración manual de IP.

### 🛡️ Requerimientos No Funcionales (RNF)
1. **Operabilidad Offline:** El sistema (tanto móvil como PC) debe funcionar al 100% sin acceso a Internet, requiriendo únicamente un router local (LAN/WLAN) para la comunicación.
2. **Latencia:** El tiempo de respuesta entre pulsar "Siguiente" en el móvil y la actualización visual en la PC no debe superar los **100 milisegundos**.
3. **Persistencia Ligera:** La base de datos SQLite debe empaquetarse junto con el ejecutable, eliminando la necesidad de instalar motores de base de datos de terceros.
4. **Usabilidad a una mano (Móvil):** La "Pantalla Live" del controlador móvil debe tener áreas táctiles lo suficientemente grandes para ser operada por un músico mientras toca un instrumento (sin necesidad de mirar fijamente la pantalla).
5. **Legibilidad Visual (Display):** La proyección debe garantizar contraste mínimo de accesibilidad AAA (letras claras sobre fondo oscuro o con bordes pronunciados).
6. **Portabilidad de Despliegue:** La versión de PC debe ser compilada como un único ejecutable o carpeta portátil de Windows, facilitando que el grupo de trabajo la traslade en una memoria USB si es necesario.
7. **Formato Scroll en Móvil:** La vista de detalle en móvil debe mostrar la letra completa con scroll, permitiendo al usuario ver todas las estrofas de un vistazo (diferente al modo presentación de la PC).
8. **Distinción de Versiones:** Debe quedar claro que esta arquitectura corresponde a la versión **LOCAL** del sistema, donde la PC actúa como servidor y el celular como control remoto. La versión web tendrá una arquitectura diferente.

---

## 🗂️ 6. Estructura de Navegación Resumida

```
APP CONTROLADOR (MÓVIL)
├── Pantalla 1: Home / Buscador
│   └── Barra de búsqueda + filtros + lista de himnos
├── Pantalla 2: Vista de Detalle (formato scroll)
│   └── Letra completa + transposición + botón "PROYECTAR"
├── Pantalla 3: Pantalla Live (Control Remoto)
│   ├── Botonera de navegación (Siguiente/Anterior)
│   ├── Panel de configuración en tiempo real
│   └── Botones de acceso rápido (Coro, Inicio, Blackout)
└── Pantalla 4: Editor de Arreglos (Opcional)
    └── Modificación de acordes y guardado

APP DISPLAY (PC/TV)
└── Pantalla Única: Proyección
    └── Modo standby + Modo live (transiciones de estrofas)
```