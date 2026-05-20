# Contexto del Proyecto - HimnarioID 2.0

> **Última actualización:** 20 de mayo de 2026 — 3ª revisión

## Stack Tecnológico
- **Frontend**: Flutter (Dart)
- **Estado**: Riverpod
- **BD**: SQLite (sqflite en Android/iOS, sqflite_common_ffi en desktop)
- **Audio**: audioplayers + DeviceFileSource
- **Fuentes**: Google Fonts (Merriweather, Lora, Playfair Display, Cinzel)
- **Gestión de estado**: Riverpod (StateNotifier + FutureProvider)
- **Hosting**: GitHub Releases (para pistas de audio)

## Base de Datos (SQLite)
- Version actual: 4
- Tablas: Himno, Version_Pais, Pais, Estrofa, Categoria, Himno_Categoria, Usuario,
  Arreglo_Musical, Estrofa_Arreglo, Pista_Audio, Fondo_Pantalla, Configuracion,
  Historial_Reproduccion, **Himno_Busqueda**
- BD embebida en: `assets/db/himnario_id.db` (400 himnos precargados + 25 nuevos de convenciones)
- Migraciones: v1→v2→v3→v4
  - v4: `Himno_Busqueda` con texto pre-normalizado para búsqueda rápida en Android
- Scripts: `scripts/insertar_himnos_convenciones.py` — inserta 25 himnos desde PDF

## Estructura del Proyecto
```
lib/
├── core/
│   ├── database/          → database_helper.dart, schema.sql
│   ├── utils/             → chord_transposer, flag_utils, string_utils, stanza_layout_engine, audio_file_service, file_storage_service
│   ├── constants/         → musical_constants
│   ├── enums/             → estrofa_tipo, himno_tipo, fondo_pantalla_tipo, usuario_rol
│   ├── errors/            → auth_exception, exceptions, failures
│   ├── network/           → mdns_discovery, connection_state
│   ├── theme/             → app_theme
│   └── window_manager/    → window_service, window_providers, window_state
├── data/
│   ├── datasources/local/ → hymn, catalog, user, arreglo, audio
│   ├── models/            → himno, estrofa, categoria, usuario, version_pais, pista_audio, fondo_pantalla
│   ├── models/mappers/    → entidad ⇄ modelo
│   └── repositories/      → hymn, user, arreglo, audio, control, fondo
├── domain/
│   ├── entities/          → himno, estrofa, categoria, usuario, version_pais, pista_audio, fondo_pantalla
│   ├── repositories/      → interfaces
│   └── usecases/          → admin, auth, himno, arreglo, audio, control, transposicion
├── presentation/
│   ├── shared_widgets/    → hymn_card, control_sheets, fab_menu, search_bar, alphabet_index_bar
│   │   └── providers/     → appearance_provider, fondo_options_provider
│   ├── views_personal/
│   │   ├── dashboard/     → home_screen, connected_dashboard, present_button
│   │   ├── hymn_scroll/   → hymn_detail_screen, arrangement_editor_screen, fab_menu
│   │   └── providers/     → hymn, audio, transpose
│   ├── views_projection/
│   │   ├── controller/    → live_control, minimal_control, present_control_bar, discover_display_sheet
│   │   ├── display/       → live_projection, simple_projection, standby, projection_app, receptor_binding
│   │   └── providers/     → connection, live_control, discovery, presentation, projection
│   ├── views_admin/
│   │   ├── crud_hymns/    → hymn_form, hymn_list, stanza_block_editor, categoria_selector
│   │   ├── crud_catalogs/ → pais_tab, categoria_tab, pista_tab, fondo_tab, catalog_panel
│   │   └── providers/     → admin_providers, auth_providers
│   └── dual_mode_wrapper/ → himnario_dual_app, device_mode, device_switch, dual_mode_providers
├── bootstrap/             → app_initializer
└── main.dart
```

## Características implementadas
- Modo personal: búsqueda, filtros (tipo, A-Z, Z-A, categoría), scroll alfabético
- Acordes sobre el texto (ChordParser + ChordPainter con caché LRU + ChordOverlayText)
- Toggle global de acordes (`showChords` persistente en DB, botón Solfa funcional)
- Transposición de tonos con tonalidad detectada del primer acorde
- Brocha: tamaño fuente, color letra, color acordes, fondos color/imagen desde BD, selector de fuente, negritas
- Brocha conectada: cambios de apariencia se sincronizan vía IPC a ventana de proyección
- Brocha auto-refresh (Consumer + invalidate de fondosActivosProvider)
- Paleta de 22 colores rápidos + selector HSV libre para fondos en admin
- Opacidad configurable de tarjetas de estrofa (cardOpacity slider)
- Escalado independiente de fuente en modo proyección (`projectionFontScale`)
- Proyección con scroll condicional (auto-fit eliminado, SingleChildScrollView si texto no cabe)
- Reflow de acordes en proyección (StanzaLayoutEngine.processStanza para contenido ChordPro)
- Padding horizontal reducido en proyección: 80px → 40px (50 %)
- Pistas de audio: reproducción local, barra de progreso, seek, pausa/reanudar
- Panel admin: CRUD himnos, categorías, países, fondos (color/imagen), pistas
- Admin directo (icono de ajustes en lugar de candado + login)
- Al eliminar fondo: se refresca la brocha/vista del himno, se borra la copia local (nunca el original)
- Fondos de imagen se copian automáticamente a `{appDocs}/himnario_id/fondos/` al seleccionarlos (FileStorageService)
- Limpieza de código muerto: eliminados FondoPantallaTipo.video, 3 directorios huérfanos, login_screen, barrel files, 6 providers deprecados
- Filtros A-Z, Z-A por título (inteligente: ignora acentos y puntuación)
- Scroll alfabético lateral (tipo Xiaomi)
- Búsqueda inteligente (en estrofas, ranking por relevancia, tabla pre-normalizada)
- Búsqueda optimizada para Android (debounce 400ms, eliminado N+1, tabla `Himno_Busqueda`)
- Flujo de presentación por slides: Title → Lyrics → Amen
- Labels de estrofa en proyección: "Estrofa 1", "Coro", "Puente 2", etc.
- Modo proyección con ventana secundaria (SubprocessWindowService + IPC JSON)
- Conexión Emisor/Receptor vía mDNS + gRPC (infraestructura)
- Build Android funcional (APK release con JDK 17)
- 25 himnos adicionales de convenciones/campamentos insertados desde script Python

## Estado de Tests
- **Unit + Widget**: 263 tests
- **Integración**: 11 tests (~11 fallan por NOT NULL en tabla Pais)
- **Total**: 274 tests (~11 fallos conocidos)
- **`dart analyze lib/`**: 0 errors, 0 warnings (info pre-existentes)

## Plataformas Soportadas
- **Linux** (desarrollo principal) ✅
- **Android** (APK release, requiere JDK 17) ✅
- **Windows** (no probado)
- **macOS/iOS** (no probado)

## Pistas de Audio
- Alojadas en: GitHub Releases (`v1.0-audio`)
- URL base: `https://github.com/moy385/HimnarioID_2.0/releases/download/v1.0-audio/`
- Pendiente: implementar descarga desde la app

## Ramas Mergeadas a main
- `feature/pc-modo-personal` — Adaptación de UI para desktop
- `feature/fase4-subprocess-window` — Ventana de proyección secundaria
- `feature/brocha-conectada` — Sincronización IPC de apariencia
- `feature/escalado-proyeccion` — Font scale independiente en proyección
- `feature/flujo-presentacion-slides` — Slides Title→Lyrics→Amen
- `feature/busqueda-android-tabla-plana` — Tabla pre-normalizada para Android
- `feature/proyeccion-estrofa-visibilidad` — Stack overlay + labels en proyección
- `feature/acordes-sobre-texto` — ChordParser + ChordPainter + ChordOverlayText con caché LRU
- `feature/acordes-toggle-global` — Toggle showChords persistente, botón Solfa funcional
- `feature/proyeccion-auto-fit` — Scroll condicional en proyección
- `feature/proyeccion-line-breaking` — Reflow de acordes con StanzaLayoutEngine
- `feature/settings-panel-sin-login` — Admin directo (icono de ajustes sin login forzoso)
- `feature/agregar-himnos-convenciones` — 25 himnos de convenciones + mejoras brocha + fondos + fix delete
- `feature/copiar-fondos-a-local-storage` — FileStorageService, copia de fondos a directorio local de la app
- `chore/limpieza-codigo-muerto` — 310 líneas eliminadas, 32 archivos. Limpieza post-revert de video

## Notas técnicas importantes
- **Fondos de video**: Se intentó implementar con `video_player_media_kit` / `media_kit` + libmpv, pero se descartó por crash irrecuperable en Linux (assertion `group_index >= 0` en libmpv 0.41.0). Todo el código de video fue revertido. Pendiente para cuando Ubuntu actualice libmpv.
- **File Picker**: Los archivos de fondo (imagen) se seleccionan con `file_picker`. Se copian automáticamente a `{appDocs}/himnario_id/fondos/` con nombre único. Al eliminar un fondo, `FileStorageService.deleteIfAppFile()` solo borra si está dentro del directorio app, nunca el archivo original del usuario.
- **Riverpod caching**: Los `FutureProvider` cachean su resultado hasta invalidación explícita. Es crítico invalidar `fondosActivosProvider` tras crear/editar/eliminar fondos.
- **Limpieza de código muerto (20 mayo 2026)**: Se eliminaron `FondoPantallaTipo.video`, 3 directorios huérfanos (`state_management/`, `app_controller/`, `app_display/`), `login_screen.dart`, barrel files (`views_admin.dart`, `views_personal.dart`, `views_projection.dart`), y 6 providers deprecados de `live_control_providers.dart`. Total: 310 líneas, 32 archivos.
