# Propuesta de Rediseño de Interfaz — HimnarioID 2.0

> **Fecha:** 21 de mayo de 2026
> **Elaborado por:** @arqui (arquitectura) y @design (UX/UI)
> **Propósito:** Investigación y propuesta de mejora visual sin implementación — documento de referencia para planificar sprints futuros.

---

## Resumen Ejecutivo

HimnarioID 2.0 es una aplicación técnicamente sólida con Material Design 3, Riverpod para estado, soporte multiplataforma (móvil/desktop), temas claro/oscuro/proyección, y una arquitectura limpia con separación de responsabilidades. Sin embargo, se identificaron **7 hallazgos críticos** que afectan la experiencia de usuario.

| Hallazgo | Impacto | Área |
|----------|---------|------|
| Inconsistencia visual entre pantallas (personal vs admin) | Alto | Consistencia |
| Densidad excesiva en HomeScreen sin jerarquía visual clara | Alto | Home |
| Brush Sheet sobrecargado sin agrupación visual | Medio | Sheets |
| Flujo de navegación roto (pushReplacement sin historial) | Alto | Navegación |
| Sin adaptación responsive en pantallas admin | Medio | Responsive |
| Tarjeta de himno duplicada (HymnCard vs _HymnListTile) | Medio | Consistencia |
| Sin micro-interacciones ni retroalimentación visual | Bajo | UX |

---

## 1. Análisis de la UI Actual

### 1.1 HomeScreen — Dashboard Principal

**Fortalezas:**
- ✅ Uso correcto de `colorScheme` y `textTheme` de M3
- ✅ Manejo de estados async (loading/error/data con retry)
- ✅ Scrollbar alfabético cuando se ordena por título
- ✅ Integración con modo proyección
- ✅ Debounce en búsqueda (400ms)

**Debilidades:**
- ❌ Layout plano: `Column` con padding fijo + `SingleChildScrollView` + `Expanded(ListView)`. Sin jerarquía visual entre búsqueda y filtros.
- ❌ SearchBar custom no usa el widget `SearchBar` de M3 (que tiene `leading`, `trailing`, `hintStyle` integrados)
- ❌ Filtros duplicados: Código de `_buildFilterChip` en HomeScreen y ConnectedDashboard es prácticamente idéntico
- ❌ Sin botón de cambio de vista (lista vs cuadrícula)
- ❌ Sin resultados recientes ni búsqueda persistente
- ❌ `padding: const EdgeInsets.all(16)` no escala con tamaño de pantalla

### 1.2 HymnDetailScreen — Detalle del Himno

**Fortalezas:**
- ✅ Sistema de transposición funcional con ChordTransposer y ChordOverlayText
- ✅ StanzaLayoutEngine para layout responsivo de letra con acordes
- ✅ BottomBar con transposición + botón play integrado
- ✅ Fondo configurable por imagen/color
- ✅ Versión desktop centrada a 800px con Scrollbar

**Debilidades:**
- ❌ Cabecera del himno plana: solo título + chips, sin metadatos (número, tonalidad, país)
- ❌ Estrofas en tarjetas con opacidad — borde del coro muy sutil
- ❌ Barra inferior fija ocupa espacio incluso sin uso
- ❌ AudioPlayerBar dentro del mismo scaffold: transición abrupta
- ❌ FAB Menu: cálculo de altura frágil, etiquetas sin fade
- ❌ Sin navegación rápida entre estrofas (mini-mapa)

### 1.3 Control Sheets (Brocha, Solfa, Nota, Lupa)

**Fortalezas:**
- ✅ Versión desktop (Dialog) y móvil (BottomSheet) con código compartido
- ✅ Sincronización en tiempo real con proyección
- ✅ Selector de fondos por tipo con preview
- ✅ Selector de fuentes con preview visual
- ✅ Manejo de fondos remotos en modo emisor

**Debilidades:**
- ❌ Brocha extremadamente larga: ~30 widgets hijos sin colapso
- ❌ Sin organización por secciones colapsables (ExpansionTile)
- ❌ Cambios sin preview in-place
- ❌ Tamaño fijo en desktop que no considera pantallas pequeñas
- ❌ Handle duplicado en cada sheet
- ❌ Solfa: valor numérico sin indicación visual

### 1.4 HymnCard — Tarjeta de Himno

**Fortalezas:**
- ✅ Diseño limpio con surfaceContainerLow, primaryContainer para número
- ✅ Chips de categorías con Wrap (responsive)
- ✅ Bandera del país integrada con FlagUtils
- ✅ InkWell con borderRadius para ripple

**Debilidades:**
- ❌ Sin variante compacta para móvil
- ❌ Admin usa otro diseño completamente diferente (_HymnListTile)
- ❌ Chevron derecho ocupa espacio sin valor informativo
- ❌ Sin indicación de himno "actual" en proyección

### 1.5 Admin (CatalogPanelScreen + HymnFormScreen)

**Fortalezas:**
- ✅ NavigationDrawer para categorías principales
- ✅ TabBar para sub-secciones en Catálogos
- ✅ Validación completa en formulario de himno
- ✅ ReorderableListView para estrofas

**Debilidades:**
- ❌ Drawer vs TabBar inconsistencia (dos patrones distintos)
- ❌ Encabezado duplicado y poco descriptivo
- ❌ Sin confirmación al salir del formulario
- ❌ Formulario de himno sin vista previa de acordes renderizados
- ❌ Sin M3 InputDecorator completo

### 1.6 MinimalControlScreen — Control Remoto

**Fortalezas:**
- ✅ Diseño minimalista acorde al propósito
- ✅ Botones grandes (iconSize 48)
- ✅ Integración con sheets de Brocha, Nota, Lupa

**Debilidades:**
- ❌ Espaciado excesivo (Spacer + SizedBox)
- ❌ Sin indicación de progreso (estrofa actual / total)
- ❌ Botones de función sin contexto explicativo

### 1.7 Temas (app_theme.dart)

**Fortalezas:**
- ✅ useMaterial3: true habilitado
- ✅ colorSchemeSeed para paleta automática
- ✅ Tema claro, oscuro y proyección bien diferenciados

**Debilidades:**
- ❌ Colores estáticos definidos pero no aplicados explícitamente
- ❌ Sin TextTheme personalizado en light/dark
- ❌ Sin colorScheme explícito (solo usa seed)

---

## 2. Propuestas de Mejora

---

### 🏆 Propuesta 1: Rediseño del HomeScreen con Arquitectura de Superficie

**Prioridad:** P1 (Alta) — **Esfuerzo:** Alto (3-5 días)  
**Impacto:** Crítico — es la pantalla que ven todos los usuarios

#### Problema que resuelve
El HomeScreen actual es una columna lineal sin jerarquía visual. En móvil compite por espacio limitado; en desktop se ve subutilizado.

#### Descripción visual

```
┌─────────────────────────────────────┐
│  🔍 Buscar himno por título...    │ ← M3 SearchBar expandido
│  [TODOS] [OFICIALES] [INSPIRADAS] │ ← Chips compactos con scroll
│  [ORDENAR ▼] [CATEGORÍA ▼]       │ ← Botones de acción secundarios
│─────────────────────────────────────│
│                                     │
│  ┌───┐  ┌───┐  ┌───┐             │ ← Grid de colecciones
│  │ 🎵 │  │ 🎵 │  │ 🎵 │             │    (si no hay búsqueda activa)
│  │Tod.│  │Ofi.│  │Conv│             │    3 columnas, iconos + conteo
│  │ 45 │  │123 │  │ 12 │             │
│  └───┘  └───┘  └───┘             │
│                                     │
│  Resultados (127 himnos)           │ ← Subtítulo con conteo
│  ┌──────────────────────────────┐  │
│  │ 45  Salmo 127                │  │ ← HymnCard compacto
│  │     Feliz el que teme a Dios │  │
│  └──────────────────────────────┘  │
│                                     │
│  [📋] [🔲] toggle vista           │ ← FloatingActionButton
└─────────────────────────────────────┘
```

#### Cambios concretos
1. **M3 SearchBar**: Reemplazar `HymnSearchBar` custom por `SearchBar` de Material 3
2. **Chips colapsables**: Mover filtros dentro de `PopupMenuButton`, mostrar solo 2-3 chips visibles
3. **Grid de colecciones**: Cuando no hay búsqueda activa, mostrar grid de categorías con iconos + conteo (inspirado en Apple Music)
4. **Resultados con conteo**: Subtítulo animado "127 himnos encontrados"
5. **Toggle vista lista/cuadrícula**: Botón para cambiar entre ListView y GridView
6. **Animaciones**: `AnimatedList` + `AnimatedContainer` en chips

---

### 🏆 Propuesta 2: Brush Sheet Rediseñado con Secciones Colapsables

**Prioridad:** P1 (Alta) — **Esfuerzo:** Medio (2-3 días)  
**Impacto:** Alto — sheet más usado por músicos

#### Problema que resuelve
El Brush Sheet tiene ~7 secciones no colapsables. El usuario no puede previsualizar cambios sin cerrar el sheet.

#### Descripción visual

```
┌────────────────────────────────────┐
│  🖌️ Apariencia      [⟳ Restaurar] │ ← Header con reset
├────────────────────────────────────┤
│  ▼ FONDO                          │ ← ExpansionTile
│  [■] [■] [■] [■] [■]  ┌──────┐  │    Grid 4 columnas
│                         │preview│  │    + preview
│                         └──────┘  │
├────────────────────────────────────┤
│  ▼ TEXTO                    (colapsado)
├────────────────────────────────────┤
│  ▼ ACORDES                  (colapsado)
├────────────────────────────────────┤
│  ▼ PROYECCIÓN              (colapsado)
└────────────────────────────────────┘
```

#### Cambios concretos
1. **ExpansionTile** para cada categoría (Fondo, Texto, Acordes, Proyección)
2. **Mini preview en vivo** al final del sheet (~200px)
3. **Slider con labels**: valor numérico en tiempo real
4. **Botón "Restablecer"** en el header

---

### 🏆 Propuesta 3: Sistema de Navegación Unificado

**Prioridad:** P1 (Alta) — **Esfuerzo:** Alto (3-4 días)  
**Impacto:** Alto — arregla navegación rota

#### Problema que resuelve
La navegación entre Home y Admin usa `pushReplacement` (pérdida del back stack). El admin usa Drawer + TabBar (dos patrones).

#### Cambios concretos
1. **NavigationBar (M3 Bottom Navigation):** Inicio, Himno Actual, Admin, Ajustes
2. **IndexedStack** para preservar estado de cada pestaña
3. **NavigationRail** en desktop como alternativa
4. **Ocultar navegación** durante presentación (muestra PresentControlBar)

---

### 🏆 Propuesta 4: Unificación del Sistema de Tarjetas

**Prioridad:** P2 (Media) — **Esfuerzo:** Bajo (1 día)  
**Impacto:** Medio — consistencia visual

#### Problema que resuelve
`HymnCard` (personal) y `_HymnListTile` (admin) son representaciones diferentes del mismo objeto.

#### Cambios concretos
1. **`HymnCard` parametrizado** con `variant: card | list | compact`
2. **`_HymnListTile` eliminado** del admin, reemplazado por `HymnCard`
3. **Hero tag** para transición animada entre tarjeta y detalle

---

### 🏆 Propuesta 5: Experiencia de Lectura Mejorada con Mini-mapa

**Prioridad:** P2 (Media) — **Esfuerzo:** Medio (2 días)  
**Impacto:** Alto — experiencia core de la app

#### Problema que resuelve
En himnos largos (10+ estrofas), el usuario debe scrollear mucho. No hay navegación rápida entre estrofas.

#### Cambios concretos
1. **Mini-mapa de estrofas**: Barra vertical delgada en borde derecho. Cada estrofa = segmento horizontal. Coros de distinto color. Tap → salta a esa estrofa.
2. **Gestos**: Deslizar horizontalmente para siguiente/anterior estrofa
3. **Accent bar** en coros: barra vertical izquierda de 3px con chordColor
4. **Bottom bar compacta y ocultable**

---

### 🏆 Propuesta 6: Mejora de Temas y Tipografía

**Prioridad:** P3 (Baja) — **Esfuerzo:** Bajo  
**Impacto:** Medio

#### Cambios concretos
1. Definir `ColorScheme.fromSeed(...)` explícito con `primary`, `secondary`, `tertiary`
2. `TextTheme` personalizado con fuentes del himnario
3. Asegurar contraste óptimo para lectura de letra y acordes

### 🏆 Propuesta 7: Micro-interacciones

**Prioridad:** P3 (Baja) — **Esfuerzo:** Bajo  
**Impacto:** Bajo

#### Cambios concretos
1. Feedback háptico en botones principales
2. Fade entre transiciones de pantalla
3. Esqueletos (shimmer) en carga de listas

---

## 3. Priorización y Orden de Implementación Sugerido

| Fase | Propuesta | Esfuerzo | Dependencias |
|------|-----------|----------|-------------|
| **Sprint 1** | Propuesta 2: Brush Sheet rediseñado | Medio | Ninguna |
| **Sprint 1** | Propuesta 4: Unificar HymnCard | Bajo | Ninguna |
| **Sprint 2** | Propuesta 1: HomeScreen rediseñado | Alto | Refactor hymn_list_provider |
| **Sprint 2** | Propuesta 5: Mini-mapa + gestos | Medio | Ninguna |
| **Sprint 3** | Propuesta 3: Navegación unificada | Alto | Refactor app shell |
| **Sprint 4** | Propuesta 6: Temas y tipografía | Bajo | Ninguna |
| **Sprint 4** | Propuesta 7: Micro-interacciones | Bajo | Ninguna |

---

## 4. Mockups Conceptuales

### Mockup 1: HomeScreen Rediseñado

**Header (AppBar):**
- Título "HimnarioID" con `headlineSmall`, peso semibold
- Derecha: botón de conexión con badge (verde=conectado, rojo=error, gris=desconectado)

**Cuerpo:**
- **SearchBar M3**: `hintText: "Buscar himno por número o título..."`, `leading: Icon(Icons.search_rounded)`, `trailing: [PopupMenuButton]`. Al hacer foco, historial de búsqueda.
- **Filtros compactos**: `FilterChip` con `visualDensity.compact`, 3 visibles + overflow.
- **Resultados**: `AnimatedSwitcher` con fade. `HymnCard` con `Hero`.

**Desktop (ancho > 600):**
- Layout 2 columnas: izquierda lista (50%), derecha preview del himno seleccionado (50%)
- Scrollbar alfabético en columna izquierda

### Mockup 2: Brush Sheet Rediseñado

**Mobile (BottomSheet):**
- `DraggableScrollableSheet` con `initialChildSize: 0.6`, `minChildSize: 0.3`, `maxChildSize: 0.9`
- Header: ícono + "Apariencia" + botón "Restablecer"
- Secciones colapsables con `ExpansionPanelList.radio`:
  1. Fondo (expandido por defecto): Grid 3 columnas thumbnails 70x70
  2. Texto: Slider + colores + fuente + negritas
  3. Acordes: Toggle + colores
  4. Proyección: Sliders (solo desktop)
- Mini preview al final: 120px mostrando "Salmo 127" con estilos actuales

**Desktop (Dialog):**
- `AlertDialog` con `maxWidth: 640`, `maxHeight: 800`
- Mismo contenido sin drag handle, preview más grande

### Mockup 3: HymnDetailScreen con Mini-mapa

**Layout:**
- AppBar con número + título + botón presentar (desktop)
- ScrollView con estrofas
- Mini-mapa: columna derecha 16px, segmentos 4px, coros en tertiary, actual en primary
- Tap segmento → scroll a esa estrofa
- Bottom bar compacta (48px): "Tono: G" con [-][+][▶]. Expandible a 80px.

### Mockup 4: Admin Layout Responsive

**Mobile (< 600px):**
- NavigationBar (Bottom) con: Himnos | Catálogos | Fondos
- Formulario de himno ocupa pantalla completa

**Tablet/Desktop (>= 600px):**
- NavigationRail izquierda con iconos + labels
- Contenido: 2 columnas (lista + formulario/preview)

---

## 5. Referencias de Diseño

- **Material Design 3**: https://m3.material.io/
- **SearchBar widget**: https://api.flutter.dev/flutter/material/SearchBar-class.html
- **NavigationBar**: https://api.flutter.dev/flutter/material/NavigationBar-class.html
- **NavigationRail**: https://api.flutter.dev/flutter/material/NavigationRail-class.html
- **DraggableScrollableSheet**: https://api.flutter.dev/flutter/widgets/DraggableScrollableSheet-class.html

---

*Documento generado por @arqui y @design — HimnarioID 2.0 UI/UX Research. 21 de mayo de 2026.*
