# Tareas para @design — Sprint 5.2 (QA Fixes)

## ⚠️ LEE PRIMERO: SPRINT_5_FIXES.md (sección 3 - Problema 2)

Este sprint corrige colores hardcodeados y mejora la UI de StandbyScreen.

---

## TAREA-DESIGN-601 [P1 — ALTO] Reemplazar Colors.orange con colorScheme

### Archivo
`lib/presentation/views_projection/display/standby_screen.dart`
**Líneas**: 151, 163, 169

### Contexto
La función `_buildServerInfo()` muestra un estado "Servidor gRPC no disponible" usando `Colors.orange` hardcodeado. Esto viola la regla de Material Design 3 de usar `colorScheme`.

### Qué hacer
Reemplazar `Colors.orange` con `colorScheme.tertiary` (para indicar advertencia/estado no-disponible):

```dart
// Línea 151 — borde del container (antes: Colors.orange.withValues(alpha: 0.4))
color: colorScheme.tertiary.withValues(alpha: 0.4),

// Línea 163 — icono cloud_off (antes: Colors.orange)
color: colorScheme.tertiary,

// Línea 169 — texto "Servidor gRPC no disponible" (antes: Colors.orange)
color: colorScheme.tertiary,
```

### Reglas de estilo
- Usar `colorScheme.tertiary` para estados de warning/advertencia (no es error, pero tampoco es normal)
- El fondo de StandbyScreen es **intencionalmente negro** (`Colors.black`) porque es para proyector — NO cambiar el fondo
- Verificar contraste: `colorScheme.tertiary` debe ser visible contra fondo negro
- Ejecutar `dart analyze lib/` después del cambio para verificar 0 errores

### Antes vs Después

**Antes** (hardcodeado):
```dart
// Línea 149-172:
decoration: BoxDecoration(
  border: Border.all(
    color: Colors.orange.withValues(alpha: 0.4),  // ❌ hardcodeado
  ),
  borderRadius: BorderRadius.circular(12),
),
child: Column(
  children: [
    Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.cloud_off_rounded,
          size: 18,
          color: Colors.orange,  // ❌ hardcodeado
        ),
        const SizedBox(width: 8),
        Text(
          'Servidor gRPC no disponible',
          style: textTheme.bodyMedium?.copyWith(
            color: Colors.orange,  // ❌ hardcodeado
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
```

**Después** (con colorScheme):
```dart
// Línea 149-172:
decoration: BoxDecoration(
  border: Border.all(
    color: colorScheme.tertiary.withValues(alpha: 0.4),  // ✅ desde theme
  ),
  borderRadius: BorderRadius.circular(12),
),
child: Column(
  children: [
    Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.cloud_off_rounded,
          size: 18,
          color: colorScheme.tertiary,  // ✅ desde theme
        ),
        const SizedBox(width: 8),
        Text(
          'Servidor gRPC no disponible',
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.tertiary,  // ✅ desde theme
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
```

### Verificación
```bash
cd /home/melquisedec/Escritorio/Projects/Personales/HimnarioID_2.0
dart analyze lib/    # 0 errors, 0 warnings, 0 info
# Verificar que no haya más Colors.orange en el archivo:
rg 'Colors\.orange' lib/presentation/views_projection/display/standby_screen.dart
# No debe encontrar nada
```

---

## TAREA-DESIGN-602 [P2 — MEDIO] Revisión visual general de StandbyScreen

### Archivo
`lib/presentation/views_projection/display/standby_screen.dart`

### Qué hacer (opcional, si hay tiempo)
- Verificar que todos los colores usen `colorScheme` y no estén hardcodeados (excepto `Colors.black` intencional)
- Verificar que los tamaños de fuente usen `textTheme`
- Verificar contraste de colores contra fondo negro

### Reglas
- **NO cambiar el fondo negro** — es intencional para proyector
- **NO cambiar el layout** — solo revisar uso de colores
- Si encuentras otro color hardcodeado, reemplazarlo con `colorScheme`

---

## VERIFICACIÓN FINAL

```bash
cd /home/melquisedec/Escritorio/Projects/Personales/HimnarioID_2.0
dart analyze lib/                  # 0 errors, 0 warnings, 0 info
rg 'Colors\.' lib/                # Solo Colors.black debe aparecer (intencional)
```

---

*Fin de TASKS_DESIGN_SPRINT5.md — 14 de mayo de 2026*
