# Tareas Diferidas — Próximos Sprints

> **Actualización (19 mayo 2026):** Se agregaron 21 tests de ChordParser (263 unit/widget total). El proyecto tiene 274 tests contando integración.
> 
> Este documento registra las tareas identificadas por @documentador que fueron diferidas por exceder ~1h de trabajo o requerir infraestructura nueva. Se planificarán en sprints posteriores.

---

## Sprint 2

### I1 — Servidor gRPC (Display)
**Estimado**: ~4h
**Dependencias**: Proto compilado existente en `lib/proto/generated/`
**Archivos a crear**:
- `bin/server.dart` — Entry point del servidor gRPC
- `lib/core/network/grpc_server.dart` — Lógica del servidor
- Tests de integración

**Descripción**: Implementar el servidor gRPC que corre en el display (PC/TV) y recibe comandos del controlador remoto. Debe manejar:
- Handshake con el controlador
- Control de navegación de estrofas
- Estado compartido (estrofa actual, blackout, transposición)
- Watch status stream para actualizaciones en tiempo real

### I2 — Control remoto funcional
**Estimado**: ~3h
**Dependencias**: I1 (servidor gRPC funcionando)
**Archivos a modificar**:
- `lib/data/datasources/remote/grpc_control_datasource.dart`
- `lib/presentation/state_management/providers/connection_providers.dart`
- `lib/presentation/state_management/providers/live_control_providers.dart`

**Descripción**: Conectar los providers de control en vivo (`LiveControlNotifier`) con los comandos gRPC reales. Hoy los comandos se ejecutan localmente; deben enviarse al display remoto.

### M1 — Tests unitarios (cobertura ≥80%)
**Estimado**: ~6h (transversal)
**Dependencias**: —
**Archivos a crear/modificar**:
- `test/unit/core/**` — Tests para `ChordTransposer`, `MusicalConstants`
- `test/unit/data/**` — Tests para datasources y repositorios
- `test/widget/**` — Tests de widgets

**Descripción**: Implementar tests unitarios usando `mocktail` y `flutter_test`. Priorizar:
1. `chord_transposer.dart` (lógica crítica de transposición)
2. `hymn_repository_impl.dart` (orquestación)
3. `hymn_local_datasource.dart` (queries SQLite)
4. Widgets principales (HomeScreen, HymnDetailScreen)

---

## Sprint 3

### I5 — Conexión automática mDNS
**Estimado**: ~3h
**Dependencias**: I1 + I2 (gRPC funcionando)
**Archivos a modificar**:
- `lib/core/network/mdns_discovery.dart` — Integrar con connection providers
- `lib/presentation/app_controller/screens/home_screen.dart` — UI de "buscando displays"

**Descripción**: Usar `MdnsDiscovery` para encontrar automáticamente displays en la LAN y conectarse al primero disponible. Añadir UI de selección si hay múltiples.

### A1 — Reproductor de audio
**Estimado**: ~4h
**Dependencias**: `audioplayers` ya en pubspec
**Archivos a crear/modificar**:
- `lib/data/datasources/local/audio_local_datasource.dart`
- `lib/domain/repositories/audio_repository.dart`
- `lib/presentation/app_controller/screens/hymn_detail_screen.dart` — Botón de play funcional
- `lib/presentation/state_management/providers/audio_providers.dart`

**Descripción**: Implementar reproducción de pistas de audio MP3/OGG desde assets. Manejar play/pause/stop, integración con himnos.

---

## Sprint 4

### A2 — Transposición con preview
**Estimado**: ~2h
**Dependencias**: A1 (opcional pero recomendado)
**Archivos a modificar**:
- `lib/presentation/app_controller/screens/hymn_detail_screen.dart`

**Descripción**: Mostrar preview en tiempo real de la transposición. Actualmente la transposición aplica al contenido ChordPro; agregar un pequeño teclado visual para probar diferentes tonalidades antes de aplicar.

### M4 — Tema consistente (Material Design 3)
**Estimado**: ~2h
**Archivos a modificar**:
- `lib/core/theme/app_theme.dart` — Revisar y completar el tema
- Todos los screens/widgets que usen colores hardcodeados

**Descripción**: Auditoría completa de uso de colorScheme/textTheme en todos los widgets. Reemplazar `Colors.white`, `Colors.black` con valores del tema. Asegurar que el tema claro también se vea bien. Esta tarea puede comenzar después de M2+M3 para reducir conflictos de merge.

### M5 — Documentación de API interna
**Estimado**: ~2h
**Dependencias**: I1+I2+I3+I4+I5 estable
**Archivos**:
- `doc/api/` — Generar documentación de referencia de la API

---

## Tareas no planificadas (icebox)

| Tarea | Descripción | Razón |
|-------|-------------|-------|
| M8 — Exportar arreglos como PDF | Generar PDF con letra+acordes desde un arreglo guardado | Baja prioridad, no crítica para MVP |
| M9 — Importar/Exportar arreglos JSON | Sincronización entre dispositivos | Requiere backend/sincronización |
| M10 — Multilenguaje (i18n) | Soporte para inglés/portugués | MVP es solo español |
| A3 — Grabación de audio desde la app | Los músicos graban sus versiones | Complejidad alta, depende de permisos nativos |

---

*Plan generado por @arqui. Revisar al inicio de cada sprint para repriorizar.*
