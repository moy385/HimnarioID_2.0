# Plan Sprint 3 — Comparativa y Acción

## Resumen Ejecutivo

Este plan detalla las tareas necesarias para alinear el estado actual del proyecto HimnarioID 2.0 con los requisitos documentados en `README.md`, `Interfaz.md` y `Version_Web.md`. Tras auditar el código fuente, se identificaron **17 discrepancias críticas** y **2 pendientes** que deben resolverse.

### Estado Actual vs Deseado

| Aspecto | Estado Actual | Estado Deseado | Brecha |
|---------|--------------|----------------|--------|
| DB Tablas | 10 tablas (sin Fondo_Pantalla, Usuario sin username/password_hash) | 11 tablas con Fondo_Pantalla, Usuario completo | 🔴 |
| Estructura Carpetas | app_controller/ + app_display/ | views_personal/ + views_projection/controller/ + views_projection/display/ | 🔴 |
| Autenticación | usuarioId hardcodeado = 1 | Login con credenciales (admin/admin123) | 🔴 |
| CRUD Himnos Admin | No existe | CRUD completo con editor ChordPro | 🔴 |
| CRUD Catálogos Admin | No existe | CRUD de categorías, países, pistas, fondos | 🔴 |
| 2da Ventana PC | No existe | Botón "Presentar" + window_manager | 🔴 |
| Dev Mode | No existe | Switch PC/Celular en Debug | 🔴 |
| Modo Emisor | No implementado | Dashboard alterado + panel minimalista | 🔴 |
| ArregloRepositoryImpl | Solo interfaz | Implementación completa | 🟡 |
| UserRepositoryImpl | Solo interfaz | Implementación completa | 🟡 |
| Tests | 1 smoke test | Unitarios + widget + integración | 🔴 |

### Orden de Ejecución Recomendado (Fases)

```
Fase 0: DB + Modelos + Datasources
Fase 1: Repositorios faltantes + Use Cases
Fase 2: Reestructuración de carpetas
Fase 3: Login / Auth
Fase 4: CRUD Admin
Fase 5: Dual Mode Wrapper + Window Manager
Fase 6: Modo Emisor + PC Receptor
Fase 7: Tests
```

---

## Tareas de Base de Datos

### 🔴 DB-01: Agregar columna `username` y `password_hash` a tabla `Usuario`

| Campo | Detalle |
|-------|---------|
| **Agente** | back |
| **Descripción** | La tabla `Usuario` actual no tiene campos de autenticación. Se debe migrar el schema para agregar `username TEXT UNIQUE NOT NULL` y `password_hash TEXT NOT NULL`. La entidad `Usuario` debe reflejar estos campos. El seed data debe incluir el usuario admin con hash de `admin123`. |
| **Archivos afectados** | `lib/core/database/schema.sql`, `lib/core/database/database_helper.dart`, `lib/domain/entities/usuario.dart`, `lib/data/models/usuario_model.dart`, `lib/data/models/usuario_model.g.dart`, `lib/core/enums/usuario_rol.dart` |
| **Dependencias** | Ninguna |

**Detalle técnico:**
1. Modificar `CREATE TABLE Usuario` en `schema.sql` y `database_helper.dart`:
   ```sql
   CREATE TABLE Usuario (
     id INTEGER PRIMARY KEY AUTOINCREMENT,
     username TEXT NOT NULL UNIQUE,
     password_hash TEXT NOT NULL,
     nombre TEXT NOT NULL,
     rol TEXT NOT NULL DEFAULT 'Musico' CHECK(rol IN ('Admin', 'Musico', 'Visualizador')),
     fecha_registro TEXT NOT NULL DEFAULT (datetime('now'))
   );
   ```
2. Agregar migración `_onUpgrade` versión 1→2 con `ALTER TABLE Usuario ADD COLUMN username TEXT; ALTER TABLE Usuario ADD COLUMN password_hash TEXT;`
3. Actualizar seed data para crear usuario admin con hash bcrypt/SHA256 de `admin123`
4. Actualizar entidad Freezed `Usuario` con campos `username` y `passwordHash`
5. Actualizar `UsuarioModel` con `fromMap`/`toEntity` incluyendo nuevos campos
6. Regenerar archivos `.g.dart` con `dart run build_runner build`

---

### 🔴 DB-02: Crear tabla `Fondo_Pantalla`

| Campo | Detalle |
|-------|---------|
| **Agente** | back |
| **Descripción** | Crear la tabla de fondos dinámicos para el Modo Proyección. Debe soportar imágenes, videos y colores sólidos. |
| **Archivos afectados** | `lib/core/database/schema.sql`, `lib/core/database/database_helper.dart`, `lib/domain/entities/` (nuevo: `fondo_pantalla.dart`), `lib/data/models/` (nuevo: `fondo_pantalla_model.dart`) |
| **Dependencias** | Ninguna |

**Detalle técnico:**
1. Agregar a `_onCreate` y schema:
   ```sql
   CREATE TABLE Fondo_Pantalla (
     id INTEGER PRIMARY KEY AUTOINCREMENT,
     nombre TEXT NOT NULL,
     tipo TEXT NOT NULL CHECK(tipo IN ('imagen', 'video', 'color_solido')),
     ruta_archivo TEXT,
     color_hex TEXT,
     es_predeterminado INTEGER NOT NULL DEFAULT 0,
     activo INTEGER NOT NULL DEFAULT 1
   );
   ```
2. Crear entidad Freezed `FondoPantalla` con: `id`, `nombre`, `tipo` (enum), `rutaArchivo`, `colorHex`, `esPredeterminado`
3. Crear `FondoPantallaModel` con `fromMap`/`toEntity`
4. Crear enum `FondoPantallaTipo` en `lib/core/enums/`
5. Crear mapper `fondo_pantalla_model_to_entity.dart`

---

## Tareas de Backend

### 🔴 BE-01: Implementar `UserRepositoryImpl`

| Campo | Detalle |
|-------|---------|
| **Agente** | back |
| **Descripción** | Implementar la interfaz `UserRepository` con operaciones CRUD completas sobre la tabla `Usuario`, incluyendo autenticación (verificar username+password_hash). |
| **Archivos afectados** | `lib/data/repositories/user_repository_impl.dart` (NUEVO), `lib/domain/repositories/user_repository.dart` (modificar interfaz), `lib/data/datasources/local/user_local_datasource.dart` (NUEVO) |
| **Dependencias** | DB-01 |

**Detalle técnico:**
1. Extender interfaz `UserRepository` con:
   ```dart
   Future<Usuario?> login(String username, String password);
   Future<Usuario> create(Usuario usuario, String password);
   Future<Usuario> update(Usuario usuario);
   Future<bool> delete(int id);
   Future<List<Usuario>> getAll();
   ```
2. Crear `UserLocalDataSource` con consultas SQL para operaciones de usuario
3. Implementar `UserRepositoryImpl` usando el datasource
4. Usar `dart:convert` base64 o `package:argon2` para hash de contraseñas (NO texto plano)
5. Registrar provider en `lib/presentation/state_management/providers/` (nuevo: `auth_providers.dart`)

---

### 🔴 BE-02: Implementar `ArregloRepositoryImpl`

| Campo | Detalle |
|-------|---------|
| **Agente** | back |
| **Descripción** | Implementar la interfaz `ArregloRepository` para el sistema de forks (crear, listar, actualizar, eliminar arreglos musicales). Ya existe la tabla, el modelo y la entidad. |
| **Archivos afectados** | `lib/data/repositories/arreglo_repository_impl.dart` (NUEVO), `lib/data/datasources/local/arreglo_local_datasource.dart` (NUEVO), `lib/domain/repositories/arreglo_repository.dart` (extender), `lib/domain/usecases/arreglo/create_fork_usecase.dart` (completar) |
| **Dependencias** | DB-01 (para asociar arreglos al usuario autenticado) |

**Detalle técnico:**
1. Crear `ArregloLocalDataSource` con operaciones:
   - `createArreglo()` — INSERT en Arreglo_Musical + INSERT múltiple en Estrofa_Arreglo
   - `getByUser(usuarioId)` — SELECT con JOIN estrofas
   - `updateArreglo()` — UPDATE Arreglo_Musical + DELETE/INSERT Estrofa_Arreglo
   - `deleteArreglo()` — DELETE en cascada
2. Implementar `ArregloRepositoryImpl` usando transacciones SQLite
3. El `createForkUsecase` debe copiar las estrofas originales a `Estrofa_Arreglo` con las modificaciones del usuario
4. Integrar con el provider de autenticación para obtener `usuarioId`

---

### 🔴 BE-03: Sistema de Autenticación (Login Provider + Use Case)

| Campo | Detalle |
|-------|---------|
| **Agente** | back |
| **Descripción** | Crear el flujo completo de autenticación: LoginUseCase, AuthNotifier, providers, y guardado de sesión. |
| **Archivos afectados** | `lib/domain/usecases/auth/login_usecase.dart` (NUEVO), `lib/presentation/state_management/providers/auth_providers.dart` (NUEVO), `lib/core/errors/auth_exception.dart` (NUEVO) |
| **Dependencias** | BE-01 |

**Detalle técnico:**
1. Crear `AuthState` con estados: `Unauthenticated`, `Authenticated(Usuario)`, `AuthLoading`, `AuthError`
2. Crear `AuthNotifier extends StateNotifier<AuthState>` con métodos:
   - `login(username, password)` → llama a `UserRepository.login()` 
   - `logout()` → limpia sesión
   - `checkSession()` → verifica sesión persistente al iniciar app
3. Crear `LoginUseCase` con validación de campos vacíos y delegación al repositorio
4. Crear provider `authProvider` de tipo `StateNotifierProvider`
5. El notifier debe exponer `currentUser` y `isAuthenticated` como providers derivados
6. Considerar usar `shared_preferences` para persistir sesión entre reinicios

---

### 🔴 BE-04: CRUD Himnos — Use Cases + Admin Datasource

| Campo | Detalle |
|-------|---------|
| **Agente** | back |
| **Descripción** | Crear casos de uso para administración de himnos: crear, editar, eliminar himnos completos con sus versiones, estrofas y categorías. |
| **Archivos afectados** | `lib/domain/usecases/himno/create_hymn_usecase.dart` (NUEVO), `lib/domain/usecases/himno/update_hymn_usecase.dart` (NUEVO), `lib/domain/usecases/himno/delete_hymn_usecase.dart` (NUEVO), `lib/data/datasources/local/hymn_local_datasource.dart` (extender), `lib/data/repositories/hymn_repository_impl.dart` (extender), `lib/domain/repositories/hymn_repository.dart` (extender) |
| **Dependencias** | BE-03 (solo admin puede ejecutar) |

**Detalle técnico:**
1. Extender `HymnRepository` con:
   ```dart
   Future<int> createHymn(Himno himno, List<Map> estrofas, List<int> categoriaIds);
   Future<void> updateHymn(Himno himno, List<Map> estrofas, List<int> categoriaIds);
   Future<void> deleteHymn(int id);
   Future<List<Categoria>> getAllCategorias();
   Future<Categoria> createCategoria(String nombre);
   Future<void> deleteCategoria(int id);
   ```
2. Extender `HymnLocalDataSource` con operaciones transaccionales:
   - `insertHymnCompleto()` — INSERT Himno + Version_Pais + Estrofas + Himno_Categoria en una transacción
   - `updateHymnCompleto()` — UPDATE + DELETE/INSERT hijos
   - `hymnHasReferences()` — verificar antes de eliminar
3. Cada use case debe validar que el usuario tiene rol `Admin`
4. Crear providers para admin en `lib/presentation/state_management/providers/admin_providers.dart`

---

### 🔴 BE-05: CRUD Catálogos — Use Cases

| Campo | Detalle |
|-------|---------|
| **Agente** | back |
| **Descripción** | Crear casos de uso para gestionar catálogos: Categorías, Países, Pistas de Audio, Fondos de Pantalla. |
| **Archivos afectados** | `lib/domain/usecases/admin/` (NUEVO: `manage_categorias.dart`, `manage_paises.dart`, `manage_pistas.dart`, `manage_fondos.dart`), `lib/data/datasources/local/catalog_local_datasource.dart` (NUEVO) |
| **Dependencias** | DB-02, BE-04 |

**Detalle técnico:**
1. Crear `CatalogLocalDataSource` con métodos genéricos por tabla
2. Use cases específicos:
   - `CreateCategoriaUseCase`, `DeleteCategoriaUseCase`, `GetAllCategoriasUseCase`
   - `CreatePaisUseCase` (gestionar valores únicos de `Version_Pais.pais`)
   - `CreatePistaUseCase`, `DeletePistaUseCase`, `GetPistasByHimnoUseCase`
   - `CreateFondoUseCase`, `UpdateFondoUseCase`, `DeleteFondoUseCase`, `GetAllFondosUseCase`
3. Usar transacciones SQLite para operaciones que afecten múltiples tablas
4. Los providers se integrarán en `admin_providers.dart`

---

### 🟡 BE-06: Servicio de 2da Ventana (Window Manager)

| Campo | Detalle |
|-------|---------|
| **Agente** | back |
| **Descripción** | Crear la lógica para abrir y controlar una segunda ventana en PC (Desktop) usando `window_manager` o `dart:html` (web). Envolver en una clase `WindowService` que abstraiga la plataforma. |
| **Archivos afectados** | `lib/core/window_manager/window_service.dart` (NUEVO), `lib/core/window_manager/window_state.dart` (NUEVO), `lib/core/window_manager/window_providers.dart` (NUEVO) |
| **Dependencias** | Ninguna |

**Detalle técnico:**
1. Crear `WindowService` abstracto con implementaciones:
   - `DesktopWindowService`: usa `package:window_manager` para abrir ventana nativa
   - `WebWindowService`: usa `window.open()` de JS
   - `MobileWindowService`: stub (no-op, lanza excepción "no soportado")
2. El servicio debe exponer:
   - `Future<void> openProjectionWindow(Map args)` — abre 2da ventana con ruta `/projection-display`
   - `Future<void> closeProjectionWindow()` — cierra la ventana
   - `Stream<WindowEvent> get onWindowEvent` — eventos de la ventana secundaria
3. Usar `MethodChannel` para comunicación entre ventanas en desktop
4. En web, usar `BroadcastChannel` o `window.postMessage` entre ventanas
5. Provider `windowServiceProvider` que inyecta la implementación según `TargetPlatform`

---

### 🟡 BE-07: Provider de Modo Dual (PC/Celular Dev Mode)

| Campo | Detalle |
|-------|---------|
| **Agente** | back |
| **Descripción** | Crear el sistema de simulación de plataforma para desarrollo. Un StateNotifier que permita forzar la UI a modo PC o modo Celular, inyectando el layout correspondiente. |
| **Archivos afectados** | `lib/presentation/dual_mode_wrapper/dual_mode_providers.dart` (NUEVO), `lib/presentation/dual_mode_wrapper/device_mode.dart` (NUEVO) |
| **Dependencias** | BE-06 |

**Detalle técnico:**
1. Crear enum `DeviceMode` con valores `phone` y `desktop`
2. Crear `DualModeNotifier extends StateNotifier<DeviceMode>`:
   - `setMode(DeviceMode mode)` 
   - `toggleMode()` — conmuta entre modos
   - Escuchar cambios de plataforma real vs simulada
3. Provider `deviceModeProvider` con `StateNotifierProvider`
4. Provider derivado `isDesktopMode` y `isPhoneMode` para consumir en UI
5. Registrar el modo en PersistentState (shared_preferences) para recordar elección en debug

---

### 🟡 BE-08: Sistema de Fondos en Proyección

| Campo | Detalle |
|-------|---------|
| **Agente** | back |
| **Descripción** | Integrar la tabla `Fondo_Pantalla` en el sistema de proyección. Los fondos deben poder seleccionarse desde la configuración de proyección y enviarse por gRPC al display. |
| **Archivos afectados** | `lib/data/repositories/fondo_repository_impl.dart` (NUEVO), `lib/domain/repositories/fondo_repository.dart` (NUEVO), `lib/domain/usecases/fondos/` (NUEVO), `lib/presentation/state_management/providers/projection_providers.dart` (extender) |
| **Dependencias** | DB-02, BE-05 |

**Detalle técnico:**
1. Crear `FondoRepository` interfaz e implementación
2. Extender `ProjectionConfig` para incluir `FondoPantalla?` seleccionado
3. Enviar comando `SET_BACKGROUND` por gRPC cuando se cambie el fondo
4. En el display (Receptor), aplicar el fondo según tipo (imagen/video/color)

---

## Tareas de Frontend

### 🔴 FE-01: Pantalla de Login (Admin)

| Campo | Detalle |
|-------|---------|
| **Agente** | dev / design |
| **Descripción** | Crear la pantalla de inicio de sesión del backoffice. Accesible desde el ícono de Candado en el Dashboard. Validación de credenciales contra el backend. |
| **Archivos afectados** | `lib/presentation/views_admin/login/login_screen.dart` (NUEVO), `lib/presentation/views_admin/login/login_form.dart` (NUEVO), `lib/presentation/views_admin/admin_panel_screen.dart` (NUEVO) |
| **Dependencias** | BE-03 |

**Detalle técnico:**
1. Crear `LoginScreen` con:
   - Campo de usuario (username)
   - Campo de contraseña (obscureText)
   - Botón "Iniciar Sesión"
   - Indicador de carga y error
   - Enlace "Volver al inicio"
2. Conectar con `authProvider` para login
3. En caso de éxito, redirigir a `AdminPanelScreen`
4. En caso de error, mostrar mensaje (Credenciales incorrectas)
5. Diseño limpio con branding del himnario (logo, colores)

---

### 🔴 FE-02: CRUD Himnos (Admin)

| Campo | Detalle |
|-------|---------|
| **Agente** | dev / design |
| **Descripción** | Panel de administración de himnos: listado con búsqueda, creación, edición y eliminación. Incluye editor de estrofas con formato ChordPro. |
| **Archivos afectados** | `lib/presentation/views_admin/crud_hymns/hymn_list_screen.dart` (NUEVO), `lib/presentation/views_admin/crud_hymns/hymn_form_screen.dart` (NUEVO), `lib/presentation/views_admin/crud_hymns/stanza_block_editor.dart` (NUEVO), `lib/presentation/views_admin/crud_hymns/categoria_selector.dart` (NUEVO) |
| **Dependencias** | BE-04, BE-05, FE-01 |

**Detalle técnico:**
1. **HymnListScreen**: 
   - Barra de búsqueda
   - Lista con cada himno mostrando: título, número, categorías
   - Botón FAB (+) para agregar nuevo
   - Cada ítem tiene lápiz (editar) y basurero (eliminar) con confirmación
   
2. **HymnFormScreen** (Crear/Editar):
   - Campos: Título, Número, Tipo (Oficial/Inspirada/Convención)
   - Selector de País
   - Selector de Categorías (multi-select con chips)
   - Bloque de estrofas: cada bloque con selector de tipo (Estrofa/Coro/Puente/Intro/Final), campo de texto con resaltado ChordPro, botones para reordenar (↑↓), agregar nuevo bloque, eliminar bloque
   - Botón Guardar
   
3. **StanzaBlockEditor**: Widget que muestra el texto ChordPro con acordes coloreados, permite edición inline

4. Validaciones: título requerido, al menos una estrofa, al menos una categoría

---

### 🔴 FE-03: CRUD Catálogos (Admin)

| Campo | Detalle |
|-------|---------|
| **Agente** | dev / design |
| **Descripción** | Panel de administración de catálogos secundarios: Categorías, Países, Pistas, Fondos de Pantalla. Organizado en tabs o cards. |
| **Archivos afectados** | `lib/presentation/views_admin/crud_catalogs/catalog_panel_screen.dart` (NUEVO), `lib/presentation/views_admin/crud_catalogs/categoria_tab.dart` (NUEVO), `lib/presentation/views_admin/crud_catalogs/pais_tab.dart` (NUEVO), `lib/presentation/views_admin/crud_catalogs/pista_tab.dart` (NUEVO), `lib/presentation/views_admin/crud_catalogs/fondo_tab.dart` (NUEVO) |
| **Dependencias** | BE-05, FE-01 |

**Detalle técnico:**
1. **CatalogPanelScreen**: TabBar con 4 tabs (Categorías, Países, Pistas, Fondos)
2. Cada tab tiene:
   - Formulario compacto en la parte superior para agregar nuevo elemento
   - Lista de elementos existentes con botones editar/eliminar
   
3. **FondoTab específico**:
   - Selector de tipo: imagen, video, color sólido
   - Si es color: ColorPicker
   - Si es imagen/video: selector de archivo (file picker)
   - Vista previa del fondo
   - Checkbox "Predeterminado"

---

### 🔴 FE-04: Módulo Dual Mode Wrapper + Switch PC/Celular

| Campo | Detalle |
|-------|---------|
| **Agente** | dev |
| **Descripción** | Crear el wrapper principal de la app que detecte el modo (PC/Celular) y renderice el layout correcto. Incluir el Switch de depuración. |
| **Archivos afectados** | `lib/presentation/dual_mode_wrapper/himnario_dual_app.dart` (NUEVO), `lib/presentation/dual_mode_wrapper/device_switch.dart` (NUEVO), `lib/app.dart` (modificar) |
| **Dependencias** | BE-07 |

**Detalle técnico:**
1. **HimnarioDualApp**: Widget raíz que envuelve la app según modo:
   - Phone: renderiza `PersonalLayout` (con FAB dinámico, scroll)
   - Desktop: renderiza `DesktopLayout` (con botón "Presentar", soporte multi-ventana)
   
2. **DeviceSwitch**: pequeño FloatingActionButton en bottom-left (solo en debug)
   - Ícono toggle: phone_android ↔ desktop_windows
   - Al presionar, cambia `deviceModeProvider`
   - Animación de transición al cambiar modo
   
3. Modificar `app.dart`:
   - Envolver `MaterialApp` con `DualModeWrapper`
   - El wrapper escucha `deviceModeProvider` y provee el layout adecuado
   - En producción, detecta automáticamente la plataforma
   - En debug, permite override manual con el switch

---

### 🔴 FE-05: Botón "Presentar" + 2da Ventana en Desktop

| Campo | Detalle |
|-------|---------|
| **Agente** | dev |
| **Descripción** | Implementar el botón "Presentar" en el Dashboard (solo visible en modo Desktop). Al activarlo, abre una segunda ventana con el display de proyección. |
| **Archivos afectados** | `lib/presentation/views_personal/dashboard/present_button.dart` (NUEVO), `lib/presentation/views_projection/display/projection_display_screen.dart` (NUEVO), `lib/presentation/views_projection/controller/minimal_control_screen.dart` (NUEVO) |
| **Dependencias** | BE-06, FE-04, FE-07 (reestructuración) |

**Detalle técnico:**
1. **PresentButton**: Widget en el Dashboard, bottom-right
   - Toggle animation: "Presentar" ↔ "Detener Presentación"
   - Tooltip: "Abrir ventana de proyección"
   - Conectado a `WindowService`
   - Solo visible en modo Desktop (o forzado por DevMode)
   
2. **Flujo Auto-Control**:
   - Al presionar "Presentar" → `windowService.openProjectionWindow()`
   - La ventana principal se transforma en panel de control minimalista
   - La 2da ventana carga `ProjectionDisplayScreen` (modo esclavo local)
   - Comunicación entre ventanas via `BroadcastChannel`/`MethodChannel`
   
3. **ProjectionDisplayScreen**: 
   - Fondo negro/color
   - Muestra la estrofa actual con transiciones
   - Sin controles (modo esclavo)
   - Indicador de conexión con ventana principal

---

### 🔴 FE-06: Modo Emisor Completo (Dashboard alterado + Panel Minimalista)

| Campo | Detalle |
|-------|---------|
| **Agente** | dev |
| **Descripción** | Implementar el flujo del celular como Emisor. Cuando el usuario se conecta como Emisor a un Receptor, el Dashboard se altera y al seleccionar un himno se abre un panel de control minimalista en lugar del scroll. |
| **Archivos afectados** | `lib/presentation/views_personal/dashboard/connected_dashboard.dart` (NUEVO), `lib/presentation/views_projection/controller/minimal_control_screen.dart` (extender), `lib/presentation/app_controller/screens/home_screen.dart` (modificar) |
| **Dependencias** | FE-07 (reestructuración), providers de conexión existentes |

**Detalle técnico:**
1. **ConnectedDashboard**: Versión del Dashboard cuando el rol es "Emisor":
   - Ícono de conexión reemplazado por "Desconectar" (rojo)
   - Al hacer tap en un himno → abre `MinimalControlScreen` en lugar de `HymnDetailScreen`
   - Barra de estado muestra "Modo Emisor - Conectado a [Display]"
   
2. **MinimalControlScreen** (panel minimalista):
   - Sin scroll de letra
   - Botones grandes: ⬅️ Anterior | ➡️ Siguiente
   - Botones de función: Brocha, Solfa, Nota, Lupa (íconos con labels)
   - Los cambios se envían por gRPC al Receptor
   - Botón "Salir" para volver al buscador
   
3. Modificar `HomeScreen` para detectar modo Emisor y redirigir a `ConnectedDashboard`

---

### 🟡 FE-07: PC Receptor Integrado (Standby → LiveProjection)

| Campo | Detalle |
|-------|---------|
| **Agente** | dev |
| **Descripción** | Integrar el flujo de PC como Receptor. Cuando el usuario selecciona "Receptor" desde el ícono de conexión, la app entra en modo standby y al recibir un himno, proyecta en pantalla completa. |
| **Archivos afectados** | `lib/presentation/views_projection/display/standby_screen.dart` (migrar desde app_display), `lib/presentation/views_projection/display/live_projection_screen.dart` (migrar y extender), `lib/presentation/views_projection/display/receptor_binding.dart` (NUEVO) |
| **Dependencias** | FE-07 (reestructuración), providers existentes |

**Detalle técnico:**
1. **ReceptorBinding**: Widget que escucha el estado del servidor gRPC
   - Conecta el `liveControlProvider` con el `GrpcDisplayServer.onCommand`
   - Cuando recibe `JUMP_TO_HYMN`, carga himno y muestra en `LiveProjectionScreen`
   - Cuando recibe `NEXT_STANZA`/`PREV_STANZA`, navega
   
2. **StandbyScreen** (migrada y mejorada):
   - Mostrar PIN de sala (para versión web)
   - Mostrar nombre del display y puerto
   - Instrucciones: "Conéctate desde tu móvil"
   - Botón para salir del modo Receptor
   
3. **LiveProjectionScreen** (extendida):
   - Leer directamente de `liveControlProvider` en lugar de props
   - Aplicar configuración de `projectionConfigProvider` (fondo, fuente)
   - Transiciones animadas entre estrofas

---

### 🔴 FE-08: FAB Dinámico en Modo Personal

| Campo | Detalle |
|-------|---------|
| **Agente** | dev / design |
| **Descripción** | Implementar el menú FAB dinámico en el HymnDetailScreen (Modo Personal) según especificación de Interfaz.md: Brocha, Nota, Solfa, Lupa. |
| **Archivos afectados** | `lib/presentation/views_personal/hymn_scroll/hymn_scroll_screen.dart` (NUEVO), `lib/presentation/views_personal/hymn_scroll/fab_menu.dart` (NUEVO), `lib/presentation/views_personal/hymn_scroll/musician_tools.dart` (NUEVO) |
| **Dependencias** | FE-07 (reestructuración) |

**Detalle técnico:**
1. **FabMenu**: Widget FAB expandible (SpeedDial)
   - Botón principal "+" que se despliega en 4 opciones:
     - 🖌️ **Brocha**: Opciones visuales (fuente tamaño, color fondo)
     - 🎵 **Nota**: BottomSheet con pistas de audio + controles Play/Pause
     - 🎼 **Solfa**: Panel de músico (toggle acordes, transposición, crear arreglo)
     - 🔍 **Lupa**: Búsqueda sobrepuesta que reemplaza el himno actual
   - Animación de expansión/contracción con `AnimationController`
   
2. Cada botón abre un `ModalBottomSheet` o `Dialog` según corresponda
3. La lupa debe abrir un `SearchDelegate` o overlay que al seleccionar un himno, reemplace la vista actual sin acumular navegación (usar `Navigator.pushReplacementNamed`)

---

## Tareas de Reestructuración

### 🔴 RE-01: Migrar `app_controller/` → `views_personal/` + `views_projection/controller/`

| Campo | Detalle |
|-------|---------|
| **Agente** | dev |
| **Descripción** | Reestructurar la carpeta `app_controller/` según la nueva arquitectura. Los archivos se distribuyen entre vistas personales y de proyección. NO romper imports. |
| **Archivos afectados** | Mover y crear barrel files: |
| **Dependencias** | Ninguna |

**Detalle técnico:**
1. Mover `home_screen.dart` → `views_personal/dashboard/home_screen.dart`
2. Mover `hymn_detail_screen.dart` → `views_personal/hymn_scroll/hymn_detail_screen.dart`
3. Mover `arrangement_editor_screen.dart` → `views_personal/hymn_scroll/arrangement_editor_screen.dart`
4. Mover `live_control_screen.dart` → `views_projection/controller/live_control_screen.dart`
5. Mover `discover_display_sheet.dart` → `views_projection/controller/widgets/discover_display_sheet.dart`
6. Crear **barrel files** (`views_personal.dart`, `views_projection.dart`) con exports para no romper imports:
   ```dart
   // lib/presentation/views_personal.dart
   export 'views_personal/dashboard/home_screen.dart';
   export 'views_personal/hymn_scroll/hymn_detail_screen.dart';
   export 'views_personal/hymn_scroll/arrangement_editor_screen.dart';
   ```
7. Actualizar imports en `app.dart` y otros archivos que referencien las rutas antiguas
8. NO eliminar archivos originales hasta que todos los imports estén actualizados y probados

---

### 🔴 RE-02: Migrar `app_display/` → `views_projection/display/`

| Campo | Detalle |
|-------|---------|
| **Agente** | dev |
| **Descripción** | Reestructurar la carpeta `app_display/` a `views_projection/display/` siguiendo la nueva arquitectura. |
| **Archivos afectados** | Mover: |
| **Dependencias** | Ninguna |

**Detalle técnico:**
1. Mover `standby_screen.dart` → `views_projection/display/standby_screen.dart`
2. Mover `live_projection_screen.dart` → `views_projection/display/live_projection_screen.dart`
3. Mover `keyboard_handler.dart` → `views_projection/display/widgets/keyboard_handler.dart`
4. Crear barrel file `views_projection.dart` (unificado con RE-01)
5. Actualizar imports

---

### 🔴 RE-03: Crear estructura de `views_admin/`

| Campo | Detalle |
|-------|---------|
| **Agente** | dev |
| **Descripción** | Crear toda la estructura de carpetas para el backoffice, incluyendo login, CRUD himnos y CRUD catálogos. Aunque las tareas FE-01/02/03 son independientes, la estructura debe existir desde el inicio. |
| **Archivos afectados** | Crear: |
| **Dependencias** | Ninguna |

**Detalle técnico:**
Crear carpetas y archivos placeholder:
```
lib/presentation/views_admin/
├── login/
│   └── login_screen.dart        # Placeholder
├── crud_hymns/
│   ├── hymn_list_screen.dart    # Placeholder
│   ├── hymn_form_screen.dart    # Placeholder
│   ├── stanza_block_editor.dart # Placeholder
│   └── categoria_selector.dart  # Placeholder
├── crud_catalogs/
│   ├── catalog_panel_screen.dart# Placeholder
│   ├── categoria_tab.dart       # Placeholder
│   ├── pais_tab.dart            # Placeholder
│   ├── pista_tab.dart           # Placeholder
│   └── fondo_tab.dart           # Placeholder
└── views_admin.dart             # Barrel file
```

---

### 🔴 RE-04: Crear `dual_mode_wrapper/` + `window_manager/`

| Campo | Detalle |
|-------|---------|
| **Agente** | dev |
| **Descripción** | Crear la estructura base para el Dual Mode Wrapper y el Window Manager. |
| **Archivos afectados** | Crear: |
| **Dependencias** | Ninguna |

**Detalle técnico:**
Crear carpetas y archivos base:
```
lib/presentation/dual_mode_wrapper/
├── himnario_dual_app.dart       # Placeholder
├── device_switch.dart           # Placeholder
└── device_mode.dart             # Enum

lib/core/window_manager/
├── window_service.dart          # Placeholder
├── window_state.dart            # Placeholder
└── window_providers.dart        # Placeholder
```

---

### 🟡 RE-05: Migrar providers a estructura views_*

| Campo | Detalle |
|-------|---------|
| **Agente** | dev |
| **Descripción** | Reorganizar los providers para que estén agrupados por vista en lugar de tenerlos todos en `state_management/providers/`. Mantener compatibilidad. |
| **Archivos afectados** | `lib/presentation/state_management/providers/` (reorganizar) |
| **Dependencias** | RE-01, RE-02 |

**Detalle técnico:**
1. Mover `hymn_providers.dart` → `views_personal/providers/hymn_providers.dart`
2. Mover `projection_providers.dart` → `views_projection/providers/projection_providers.dart`
3. Mover `live_control_providers.dart` → `views_projection/providers/live_control_providers.dart`
4. Mover `connection_providers.dart` → `views_projection/providers/connection_providers.dart`
5. Mover `audio_providers.dart` → `views_personal/providers/audio_providers.dart`
6. Mover `transpose_providers.dart` → `views_personal/providers/transpose_providers.dart`
7. Mover `discovery_providers.dart` → `views_projection/providers/discovery_providers.dart`
8. Crear barrel files y actualizar imports
9. Mantener archivos originales como re-export durante transición

---

## Tareas de Testing

### 🔴 TE-01: Tests Unitarios para Use Cases Existentes

| Campo | Detalle |
|-------|---------|
| **Agente** | qa |
| **Descripción** | Escribir tests unitarios para los 6 casos de uso existentes: SearchHymns, GetHymnDetail, SendCommand, PlayAudio, CreateFork, TransposeChords. |
| **Archivos afectados** | `test/unit/domain/usecases/` (nuevos: `search_hymns_test.dart`, `get_hymn_detail_test.dart`, `send_command_test.dart`, `play_audio_test.dart`, `create_fork_test.dart`, `transpose_chords_test.dart`) |
| **Dependencias** | Sprints anteriores (use cases ya existen) |

**Detalle técnico:**
1. Mockear repositorios con `mocktail` o `mockito`
2. Probar:
   - `SearchHymnsUseCase`: búsqueda por texto, por tipo, vacío, sin resultados
   - `GetHymnDetailUseCase`: himno existente, no existente
   - `SendCommandUseCase`: comando enviado, error de conexión
   - `PlayAudioUseCase`: reproducir, detener, error
   - `CreateForkUseCase`: crear fork exitoso, validaciones
   - `TransposeChordsUseCase`: transponer +1, -3, 0, límites (+6/-6), con acordes complejos (sus, dim, aug)
3. Usar entidades de dominio (no modelos) para mantener pureza de capa

---

### 🔴 TE-02: Tests Unitarios para ChordTransposer

| Campo | Detalle |
|-------|---------|
| **Agente** | qa |
| **Descripción** | Tests exhaustivos para el algoritmo de transposición de acordes ChordPro. |
| **Archivos afectados** | `test/unit/core/utils/chord_transposer_test.dart` |
| **Dependencias** | Ninguna |

**Detalle técnico:**
1. Probar:
   - Transposición de todas las notas (C→C#, C#→D, etc.)
   - Acordes menores (Am→A#m, Dm→D#m)
   - Acordes con séptima (G7→G#7, Cmaj7→C#maj7)
   - Acordes suspendidos (Csus4→C#sus4)
   - Acordes disminuidos (Bdim→Cdim)
   - Acordes con bajo (G/B→G#/C)
   - Líneas sin acordes (solo texto)
   - Líneas mixtas (texto + acordes)
   - Transposición 0 (no modifica)
   - Límites: transpuesta de -6 y +6
   - Caracteres especiales y espacios

---

### 🔴 TE-03: Tests de Widget para Screens Principales

| Campo | Detalle |
|-------|---------|
| **Agente** | qa |
| **Descripción** | Tests de widgets para las pantallas principales usando `flutter_test`. Probar renderizado, interacciones básicas y estados (loading, error, data). |
| **Archivos afectados** | `test/widget/` (nuevos: `home_screen_test.dart`, `hymn_detail_screen_test.dart`, `live_control_screen_test.dart`, `standby_screen_test.dart`) |
| **Dependencias** | RE-01, RE-02 (estructura de carpetas) |

**Detalle técnico:**
1. ProviderScope envuelto con overrides de providers mock
2. Probar en HomeScreen:
   - Renderiza buscador, chips y lista
   - Muestra loading y data
   - Al hacer tap en himno, navega a detalle
3. Probar HymnDetailScreen:
   - Renderiza título, estrofas
   - Botón de transposición funciona
   - Botón proyectar navega a live control
4. Probar LiveControlScreen:
   - Botón Siguiente/Anterior funciona
   - Modo blackout
5. Probar StandbyScreen:
   - Renderiza texto de espera
   - Muestra nombre de red

---

### 🟡 TE-04: Tests de Integración para DB + Repositorios

| Campo | Detalle |
|-------|---------|
| **Agente** | qa |
| **Descripción** | Tests de integración que prueben la capa de datos real (SQLite en memoria) con repositorios. |
| **Archivos afectados** | `test/integration/` (nuevos: `hymn_repository_test.dart`, `database_test.dart`) |
| **Dependencias** | DB-01, DB-02 (esquema final) |

**Detalle técnico:**
1. Usar `sqflite_common_ffi` con base de datos en memoria
2. Probar:
   - Inicialización del schema
   - Seed data se carga correctamente (3 himnos)
   - Búsqueda por texto y por tipo
   - CRUD de himnos (crear, leer, actualizar, eliminar)
   - Arreglo musical fork (crear, listar por usuario)
   - Login de usuario (credenciales correctas e incorrectas)

---

## Orden de Ejecución Recomendado

### Fase 0: Base (Día 1-2)
```
1. DB-01: Agregar username/password_hash a Usuario
2. DB-02: Crear tabla Fondo_Pantalla
3. RE-03: Crear estructura views_admin/
4. RE-04: Crear dual_mode_wrapper/ + window_manager/
```

### Fase 1: Backend Core (Día 3-5)
```
5. BE-01: Implementar UserRepositoryImpl
6. BE-02: Implementar ArregloRepositoryImpl
7. BE-03: Sistema de Autenticación
8. BE-04: CRUD Himnos Use Cases
9. BE-05: CRUD Catálogos Use Cases
```

### Fase 2: Reestructuración (Día 6-7)
```
10. RE-01: Migrar app_controller/ → views_personal/ + views_projection/controller/
11. RE-02: Migrar app_display/ → views_projection/display/
12. RE-05: Migrar providers a estructura views_*
```

### Fase 3: Frontend Admin (Día 8-10)
```
13. FE-01: Pantalla de Login
14. FE-02: CRUD Himnos Admin
15. FE-03: CRUD Catálogos Admin
```

### Fase 4: Modo Dual + PC (Día 11-13)
```
16. BE-06: Servicio de 2da Ventana
17. BE-07: Provider de Modo Dual
18. FE-04: Dual Mode Wrapper + Switch
19. FE-05: Botón "Presentar" + 2da ventana
```

### Fase 5: Modo Proyección (Día 14-16)
```
20. FE-06: Modo Emisor Completo
21. FE-07: PC Receptor Integrado
22. FE-08: FAB Dinámico
23. BE-08: Sistema de Fondos en Proyección
```

### Fase 6: Testing (Día 17-20)
```
24. TE-01: Tests Unitarios Use Cases
25. TE-02: Tests ChordTransposer
26. TE-03: Tests Widget
27. TE-04: Tests Integración
```

---

## Resumen de Archivos Afectados

| Categoría | Archivos Nuevos | Archivos Modificados |
|-----------|----------------|---------------------|
| **DB** | 4 | 4 |
| **Backend** | 20+ | 10+ |
| **Frontend** | 30+ | 5+ |
| **Reestructuración** | 15+ | 10+ |
| **Testing** | 10+ | 0 |
| **Total** | ~80+ | ~30+ |

---

## Notas Adicionales

1. **Compatibilidad hacia atrás**: Durante la reestructuración, mantener barrel files que exporten desde las rutas antiguas para NO romper imports existentes. Eliminar las rutas antiguas solo al final.

2. **Seed Data**: El usuario admin por defecto debe crearse con hash de `admin123`. Usar `package:argon2` o `package:bcrypt` para el hash. Incluir en seed data.

3. **gRPC**: El proto actual (`hymn_control.proto`) soporta los comandos necesarios. No se requieren cambios en el proto, solo en la lógica que envía/recibe los comandos.

4. **Detección de Plataforma**: Usar `AppInitializer.platform` (ya implementado) para decidir qué UI renderizar. El DevMode switch solo debe estar disponible en modo debug (`kDebugMode`).

5. **Comunicación entre ventanas**: En desktop, usar `MethodChannel` con `window_manager`. En web, usar `BroadcastChannel` API. Para mobile, no aplicar (no hay 2da ventana).

6. **PIN de sala (Web)**: La lógica de PIN para la versión web (SignalR) se deja para un sprint posterior, ya que requiere backend .NET. Por ahora, la versión web usará el mismo flujo LAN que desktop.
