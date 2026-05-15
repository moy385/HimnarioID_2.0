# Contexto del Proyecto - HimnarioID 2.0

## Stack Tecnológico
- **Frontend**: Flutter (Dart)
- **Estado**: Riverpod
- **BD**: SQLite (sqflite en Android/iOS, sqflite_common_ffi en desktop)
- **Audio**: audioplayers + DeviceFileSource
- **Fuentes**: Google Fonts (Merriweather, Lora, Playfair Display, Cinzel)
- **Hosting**: GitHub Releases (para pistas de audio)

## Base de Datos (SQLite)
- Version actual: 3
- Tablas: Himno, Version_Pais, Pais, Estrofa, Categoria, Himno_Categoria, Usuario,
  Arreglo_Musical, Estrofa_Arreglo, Pista_Audio, Fondo_Pantalla, Configuracion,
  Historial_Reproduccion
- BD embebida en: `assets/db/himnario_id.db` (400 himnos precargados)
- Migraciones: v1→v2→v3

## Estructura del Proyecto
```
lib/
├── core/
│   ├── database/          → database_helper.dart, schema.sql
│   ├── utils/             → chord_transposer, flag_utils, string_utils, stanza_layout_engine, audio_file_service
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
│   │   ├── login/         → login_screen
│   │   ├── crud_hymns/    → hymn_form, hymn_list, stanza_block_editor, categoria_selector
│   │   ├── crud_catalogs/ → pais_tab, categoria_tab, pista_tab, fondo_tab, catalog_panel
│   │   └── providers/     → admin_providers, auth_providers
│   ├── dual_mode_wrapper/ → himnario_dual_app, device_mode, device_switch, dual_mode_providers
│   └── state_management/  → providers (varios)
├── bootstrap/             → app_initializer
└── main.dart
```

## Características implementadas
- Modo personal: búsqueda, filtros (tipo, A-Z, Z-A, categoría), scroll alfabético
- Acordes sobre el texto (Stack + Positioned con TextPainter)
- Transposición de tonos con tonalidad detectada del primer acorde
- Brocha: tamaño fuente, color letra, color acordes, fondos desde BD, selector de fuente, negritas
- Pistas de audio: reproducción local, barra de progreso, seek, pausa/reanudar
- Panel admin: CRUD himnos, categorías, países, fondos, pistas
- Login/logout con persistencia de preferencias en BD
- Filtros A-Z, Z-A por título (inteligente: ignora acentos y puntuación)
- Scroll alfabético lateral (tipo Xiaomi)
- Búsqueda inteligente (en estrofas, ranking por relevancia)
- Modo proyección (no funcional en desarrollo actual)
- Build Android funcional (APK debug)

## Plataformas Soportadas
- **Linux** (desarrollo principal) ✅
- **Android** (APK debug, requiere SDK) ✅
- **Windows/Mac/iOS** (no probado)

## Build Android
- JDK 17 (NO JDK 25)
- Android SDK: platform 34, build-tools 34.0.0
- APK: `build/app/outputs/flutter-apk/app-debug.apk`
- Guía detallada: `doc/ANDROID_BUILD.md`

## Pistas de Audio
- Alojadas en: GitHub Releases (`v1.0-audio`)
- URL base: `https://github.com/moy385/HimnarioID_2.0/releases/download/v1.0-audio/`
- Pendiente: implementar descarga desde la app
