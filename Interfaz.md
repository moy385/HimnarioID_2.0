markdown_content = """# 🖥️ Diseño de Vistas, Flujo de Usuario y Requerimientos (Himnario 2.0)

Este documento detalla la experiencia de usuario (UX), el flujo de navegación y los requerimientos del sistema para el ecosistema del Himnario. Al estar dividido en dos aplicaciones (Controlador y Display), la interfaz de cada una tiene propósitos radicalmente distintos.

---

## 🗺️ 1. Flujo del Usuario (User Flow)

### A. Flujo del Controlador (App Móvil - Android/iOS)
1. **Inicio y Conexión (Discovery):** El músico abre la app. En segundo plano, mDNS escanea la LAN buscando la PC. El sistema notifica: *"Conectado a Pantalla Principal"*.
2. **Dashboard (Home):** El usuario ve un buscador central y filtros rápidos (Oficiales, Inspiradas, Convenciones).
3. **Selección de Himno:** - El usuario selecciona "Cuan Grande es Él".
   - Entra a la **Vista de Detalle**. Aquí ve la letra con acordes y la tonalidad original.
4. **Decisión de Flujo:**
   - *Ruta 1 (Proyectar Directo):* Presiona el botón "Proyectar". Pasa a la **Pantalla Live**.
   - *Ruta 2 (Transponer):* Usa los botones `+1` / `-1` para ajustar el tono. Los acordes en pantalla cambian al instante. Luego presiona "Proyectar".
   - *Ruta 3 (Personalizar/Fork):* Presiona "Crear Arreglo". Se abre el **Editor Visual**. Modifica los acordes, guarda (se asocia a su ID de `Usuario`) y luego proyecta.
5. **Control en Vivo (Pantalla Live):** El usuario usa botones de navegación (Siguiente/Anterior Estrofa, Coro) para comandar la PC en tiempo real.

### B. Flujo del Display (App PC / Smart TV)
1. **Standby (Espera):** La aplicación se abre en pantalla completa. Muestra un fondo sobrio, el nombre de la red Wi-Fi y la leyenda *"Esperando conexión del controlador..."*.
2. **Proyección en Vivo (Live Mode):** Recibe el payload por gRPC. La pantalla hace una transición suave y muestra el título del himno.
3. **Navegación:** A medida que el celular envía comandos, la letra en pantalla hace scroll o transiciones de fundido (Fade In/Out) entre estrofas.

---

## 📱 2. Estructura de Vistas y Contenido

### 🟢 Aplicación Controlador (Móvil)

#### 1. Pantalla de Inicio / Buscador
* **Buscador Universal:** Búsqueda por número, título o fragmento de letra.
* **Chips de Filtrado:** [Todos] [Oficiales] [Inspiradas] [Por Categoría].
* **Indicador de Conexión:** Un icono de estado en la barra superior (Verde: Conectado a TV, Rojo: Modo Offline puro).

#### 2. Vista de Detalle del Himno
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

#### 4. Editor de Arreglos (Modo Edición)
* **Lienzo de Letra:** La letra del himno donde cada palabra es "tocable".
* **Selector Musical:** Un teclado o rueda inferior que aparece al tocar una palabra para insertar un acorde nuevo.
* **Botón Guardar:** Guarda el arreglo en la tabla `Estrofa_Arreglo` vinculado al `Usuario` actual.

### 🔵 Aplicación Display (PC/Windows/TV)

#### 1. Pantalla de Proyección
* **Cero UI:** No hay botones, ni menús, ni cursores de mouse visibles.
* **Contenedor Principal:** Texto renderizado en tamaño masivo (tipografía sans-serif de alto contraste).
* **Soporte de Fondos:** Capacidad de mostrar fondos negros (para proyectores), videos en loop sutiles o imágenes estáticas sin opacar la letra.

---

## 📋 3. Requerimientos del Sistema

### ⚙️ Requerimientos Funcionales (RF)
1. **Transposición Automática:** El sistema debe calcular y renderizar el cambio de acordes de la escala cromática de manera instantánea al presionar los controles de tono.
2. **Sincronización LAN:** El celular debe poder enviar comandos de cambio de estrofa a la PC mediante gRPC.
3. **Manejo de Arreglos:** El sistema debe permitir derivar (forkear) un himno oficial, guardando las modificaciones bajo el identificador del `Usuario` creador sin mutar el texto oficial.
4. **Reproducción de Pistas:** El sistema móvil debe listar y reproducir archivos de audio locales vinculados al himno.
5. **Modo Blackout:** El controlador debe poder enviar un comando de emergencia para limpiar la pantalla de proyección instantáneamente.
6. **Resolución ChordPro:** El sistema debe parsear el formato `[Acorde]Texto` para renderizar el acorde exactamente sobre la sílaba correspondiente.

### 🛡️ Requerimientos No Funcionales (RNF)
1. **Operabilidad Offline:** El sistema (tanto móvil como PC) debe funcionar al 100% sin acceso a Internet, requiriendo únicamente un router local (LAN/WLAN) para la comunicación.
2. **Latencia:** El tiempo de respuesta entre pulsar "Siguiente" en el móvil y la actualización visual en la PC no debe superar los **100 milisegundos**.
3. **Persistencia Ligera:** La base de datos SQLite debe empaquetarse junto con el ejecutable, eliminando la necesidad de instalar motores de base de datos de terceros.
4. **Usabilidad a una mano (Móvil):** La "Pantalla Live" del controlador móvil debe tener áreas táctiles lo suficientemente grandes para ser operada por un músico mientras toca un instrumento (sin necesidad de mirar fijamente la pantalla).
5. **Legibilidad Visual (Display):** La proyección debe garantizar contraste mínimo de accesibilidad AAA (letras claras sobre fondo oscuro o con bordes pronunciados).
6. **Portabilidad de Despliegue:** La versión de PC debe ser compilada como un único ejecutable o carpeta portátil de Windows, facilitando que el grupo de trabajo la traslade en una memoria USB si es necesario.
"""

with open("Vistas_Requerimientos_Himnario.md", "w", encoding="utf-8") as f:
    f.write(markdown_content)

print("[file-tag: Vistas_Requerimientos_Himnario.md]")
