# Reporte Técnico — Sprint 4 Planning

**Agente**: arqui (tech-stack-architect)  
**Fecha**: 13 de mayo de 2026  
**Proyecto**: HimnarioID 2.0 — `/home/melquisedec/Escritorio/Projects/Personales/HimnarioID_2.0`

---

## 1. ANÁLISIS DE BRECHAS

### Resumen de cobertura

| Estado | Cantidad | Descripción |
|--------|----------|-------------|
| ✅ Completas | 18/32 | Funcionalidades que ya cumplen la visión |
| 🟡 Parciales | 8/32 | Implementadas con diferencias notables |
| ❌ No implementadas | 6/32 | Funcionalidades faltantes (4 P0, 2 P1) |

### Brechas P0 (Críticas — Bloquean demo)

| ID | Visión | Realidad | Impacto |
|----|--------|----------|---------|
| **B01** | Ícono candado top-left | No existe en HomeScreen | Sin acceso a admin desde home |
| **B02** | Conexión → 2 opciones (Emisor/Receptor) | DiscoverDisplaySheet solo escanea dispositivos | Flujo de conexión incompleto |
| **B03** | Presentar abre ventana independiente negra | DesktopWindowService es stub | No se puede proyectar en 2da pantalla |
| **B04** | Al presentar + himno → 2da ventana + panel control | No hay integración Present-navegación | Experiencia PC rota |

### Brechas P1 (Altas)

| ID | Visión | Realidad | Impacto |
|----|--------|----------|---------|
| **B05** | Panel emisor: brocha/solfa/nota/lupa funcionales | Son placeholders vacíos | Emisor no puede controlar nada |
| **B06** | Sin Present: himno solo con avanzar/retroceder | HymnDetailScreen completo (con FAB, audio, etc.) | UX incorrecta en PC sin proyector |
| **B07** | Subir imágenes/videos para fondos | Solo campo de texto para ruta | Admin no puede gestionar fondos visualmente |
| **B08** | "Crear arreglo" en Solfa | Solo en AppBar PopupMenu | Descubribilidad reducida |

### Brechas P2-P3 (Medias/Bajas)

| ID | Visión | Realidad |
|----|--------|----------|
| **B09** | Menú hamburguesa admin con hoja+lápiz y herramientas | AdminPanelScreen usa ListView simple |
| **B10** | Detección automática plataforma en producción | Stub comentado en DualModeNotifier |

---

## 2. PLAN DE ACCIÓN CREADO

### Archivos generados en la raíz del proyecto

| Archivo | Contenido |
|---------|-----------|
| `SPRINT_4_PLAN.md` | Análisis completo, mapa de rutas, 11 tareas detalladas, reglas para agentes |
| `TASKS_DEV.md` | 11 tareas @dev con código base, imports, verificación |
| `TASKS_DESIGN.md` | 2 tareas @design con especificaciones UI y reglas de estilo |
| `TASKS_QA.md` | 10 suites de test con criterios de aceptación |

### Mapa de rutas (3 sub-sprints)

```
Sprint 4.1 (Core — P0/P1):
├── T-001: Candado en HomeScreen                    @dev
├── T-002: Selector Emisor/Receptor                 @dev + @design
├── T-003: DesktopWindowService real                @dev
├── T-004: Integración Present + navegación         @dev
├── T-005: MinimalControlScreen funcional           @dev
└── T-006: SimpleProjectionView                     @dev

Sprint 4.2 (Features — P1/P2):
├── T-007: File Picker Fondos                       @dev
├── T-008: "Crear Arreglo" en Solfa                 @dev
├── T-009: Admin Hamburger Menu                     @design
└── T-010: Refactor ConnectionRole                  @dev

Sprint 4.3 (Polish — P3):
├── T-011: Detección plataforma                     @dev
├── QA-010: Regresión general                       @qa
└── dart analyze cleanup                            @dev
```

---

## 3. TAREAS DELEGADAS

### @dev (Full-Stack Implementer) — 11 tareas

| Tarea | Archivos clave | Prioridad | Líneas de código estimadas |
|-------|---------------|-----------|---------------------------|
| T-001: Candado HomeScreen | `home_screen.dart` | P0 | +15 |
| T-002: Selector Emisor/Receptor | `discover_display_sheet.dart`, `connection_state.dart` | P0 | +120 |
| T-003: DesktopWindowService real | `window_service.dart` | P0 | +60 |
| T-004: Present + navegación | `home_screen.dart`, `present_button.dart` | P0 | +80 |
| T-005: MinimalControlScreen funcional | `minimal_control_screen.dart`, `control_sheets.dart` | P1 | +100 |
| T-006: SimpleProjectionView | `simple_projection_view.dart` | P1 | +80 |
| T-007: File Picker Fondos | `fondo_tab.dart`, `pubspec.yaml` | P1 | +30 |
| T-008: "Crear Arreglo" en Solfa | `hymn_detail_screen.dart` | P1 | +15 |
| T-010: Refactor ConnectionRole | `connection_state.dart` | P2 | +40 |
| T-011: Detección plataforma | `dual_mode_providers.dart` | P3 | +15 |

### @design (Frontend-UX Engineer) — 2 tareas

| Tarea | Archivos clave | Prioridad |
|-------|---------------|-----------|
| T-002-DESIGN: UI Selector Emisor/Receptor | `discover_display_sheet.dart` | P0 |
| T-009-DESIGN: Admin Hamburger Menu | `admin_panel_screen.dart` | P2 |

### @qa (QA-Security Expert) — 10 suites de test

| Suite | Tareas cubiertas | Prioridad |
|-------|-----------------|-----------|
| QA-001: Tests Candado | T-001 | P0 |
| QA-002: Tests Selector Rol | T-002 | P0 |
| QA-003: Tests WindowService | T-003 | P0 |
| QA-004: Tests Present+Navegación | T-004 | P0 |
| QA-005: Tests MinimalControl | T-005 | P1 |
| QA-006: Tests SimpleProjectionView | T-006 | P1 |
| QA-007: Tests File Picker | T-007 | P1 |
| QA-008: Tests Solfa Arreglo | T-008 | P1 |
| QA-009: Tests Admin Menu | T-009 | P2 |
| QA-010: Regresión + dart analyze | Todas | P0 |

---

## 4. ESTADO FINAL DEL PROYECTO (POST-SPRINT 4)

### Funcionalidades completadas versus visión del usuario

```
Visión: 32 puntos de funcionalidad
Sprint 3: 18 completos (56%)
Sprint 4: +14 completos (44%)
Total post-Sprint 4: 32/32 (100%)
```

### Mapa de cobertura final

```
App Celular:
├── Buscador + filtros          ✅ (Sprint 3)
├── Ícono conexión top-right    ✅ (Sprint 3)
├── Ícono candado top-left      ✅ (Sprint 4 — T-001)
├── HymnDetailScreen            ✅ (Sprint 3)
├── FAB dinámico (brocha/nota/solfa/lupa)  ✅ (Sprint 3 + T-005/T-008)
└── Conexión → Emisor/Receptor  ✅ (Sprint 4 — T-002)

App PC:
├── HomeScreen + PresentButton  ✅ (Sprint 3)
├── Presentar → 2da ventana     ✅ (Sprint 4 — T-003)
├── Present + himno → control   ✅ (Sprint 4 — T-004)
├── SimpleProjectionView        ✅ (Sprint 4 — T-006)
├── Emisor/Receptor conexión    ✅ (Sprint 4 — T-002/T-010)
└── Modo Receptor (standby)     ✅ (Sprint 3)

Admin:
├── Login (admin/admin123)      ✅ (Sprint 3)
├── Candado → Login/Admin       ✅ (Sprint 4 — T-001)
├── CRUD Himnos (buscar/agregar/editar/eliminar) ✅ (Sprint 3)
├── CRUD Catálogos (país/categ/pistas/fondos) ✅ (Sprint 3 + T-007)
├── Upload imágenes/videos      ✅ (Sprint 4 — T-007)
└── Hamburger menu              ✅ (Sprint 4 — T-009)

Dual Mode:
├── Switch PC/Celular debug     ✅ (Sprint 3)
├── Cambio interfaz según modo  ✅ (Sprint 3 + T-004/T-006)
└── Detección plataforma prod   ✅ (Sprint 4 — T-011)
```

### Calidad

```
dart analyze lib/      → 0 errors, 0 warnings, 0 info ✅
flutter test           → 216 + 50 nuevos tests = ~266 tests ✅
```

---

## 5. RECOMENDACIONES ADICIONALES

### Para la implementación

1. **Orden de implementación**: Seguir estrictamente el orden Sprint 4.1 → 4.2 → 4.3. Las tareas P0 deben completarse antes de cualquier P1/P2.

2. **Refactor de sheets**: Extraer los sheets (brocha, solfa, nota, lupa) de `HymnDetailScreen` a `shared_widgets/control_sheets.dart` **antes** de implementar T-005. Esto evita duplicación de código.

3. **DesktopWindowService**: Si `window_manager` no funciona para crear ventanas secundarias en Linux, implementar WebWindowService como alternativa usando `window.open()` + `BroadcastChannel` para la demo.

4. **Persistencia de estado**: El estado `isPresenting` debe persistirse en un provider Riverpod para que sobreviva a navegaciones.

### Para la revisión de código

- `dart analyze` después de cada commit
- Verificar que no haya `Colors.xxx` hardcodeados — siempre usar `colorScheme.xxx`
- Verificar constructores `const` en todos los widgets posibles
- Verificar que los providers nuevos no creen memory leaks (usar `autoDispose` cuando corresponda)

---

**Fin del reporte. Los archivos de tareas están listos en la raíz del proyecto para que @dev, @design y @qa comiencen la implementación.**
