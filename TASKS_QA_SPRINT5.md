# Tareas para @qa — Sprint 5.2 (Verificación IPC + QA Fixes)

## ⚠️ LEE PRIMERO: SPRINT_5_FIXES.md

Este sprint implementa comunicación entre procesos (IPC) para la segunda ventana de proyección y corrige 5 issues de QA. Tu trabajo es verificar que todo funcione y no haya regresiones.

---

## INSTRUCCIONES GENERALES

Reporta cada verificación con el formato:
```
QA-XXX [Estado]:
- Pasos:
- Resultado esperado:
- Resultado obtenido:
- ¿Pasa? ✅/❌
- Notas:
```

---

## QA-601 [P0]: dart analyze — 0 errors/warnings/info

### Qué verificar
```bash
cd /home/melquisedec/Escritorio/Projects/Personales/HimnarioID_2.0
dart analyze lib/
```

### Criterio
- ✅ 0 errors
- ✅ 0 warnings
- ✅ 0 info

---

## QA-602 [P0]: flutter test — todos los tests pasan

### Qué verificar
```bash
cd /home/melquisedec/Escritorio/Projects/Personales/HimnarioID_2.0
flutter test
```

### Criterio
- ✅ Todos los tests existentes pasan
- ✅ Tests nuevos de SimpleProjectionView pasan

---

## QA-603 [P0]: IPC funcional — 2da ventana recibe himnos

### Qué verificar
Simular el flujo de presentación:

1. Iniciar app en modo desktop (usar DeviceSwitch)
2. Presionar "Presentar" → se abre 2da ventana (proceso separado)
3. En la ventana principal, tocar un himno
4. **La 2da ventana debe mostrar el himno** (título + estrofa)
5. Presionar "Siguiente" en PresentControlBar → la 2da ventana avanza
6. Presionar "Anterior" → la 2da ventana retrocede

### Criterio
- ✅ LOAD_HYMN: la 2da ventana muestra el himno correctamente
- ✅ NEXT_STANZA: la 2da ventana avanza a la siguiente estrofa
- ✅ PREV_STANZA: la 2da ventana retrocede a la estrofa anterior
- ✅ Sin himno: la 2da ventana muestra "Esperando..." (mensaje simple)

---

## QA-604 [P0]: Regresión modo phone

### Qué verificar
1. Iniciar app en modo phone (por defecto)
2. Verificar que HomeScreen se ve con buscador, filtros, lista
3. NO debe aparecer PresentButton (FAB)
4. Tocar himno → navega a HymnDetailScreen completo
5. Candado funciona → Login/Admin
6. Conexión funciona → DiscoverDisplaySheet

### Criterio
- ✅ HomeScreen idéntico a antes de los cambios
- ✅ Sin PresentButton en phone
- ✅ HymnDetailScreen funcional (FAB, transposición, audio)
- ✅ Sin crashes ni errores

---

## QA-605 [P1]: Colors.orange reemplazado

### Qué verificar
```bash
cd /home/melquisedec/Escritorio/Projects/Personales/HimnarioID_2.0
rg 'Colors\.orange' lib/
```

### Criterio
- ✅ No hay ocurrencias de `Colors.orange` en `lib/`
- ✅ La UI de StandbyScreen en modo "Servidor no disponible" usa `colorScheme.tertiary`

---

## QA-606 [P1]: context.mounted check en discover_display_sheet.dart

### Qué verificar
Revisar `lib/presentation/views_projection/controller/widgets/discover_display_sheet.dart:88`

### Criterio
- ✅ `Navigator.pop(context)` está precedido de `if (context.mounted)`

---

## QA-607 [P1]: ref.listenManual reemplazado en minimal_control_screen.dart

### Qué verificar
Revisar `lib/presentation/views_projection/controller/minimal_control_screen.dart`

### Criterio
- ✅ `ref.listenManual` NO está presente en el archivo (o solo aparece en `initState` si se refactorizó)
- ✅ Se usa `ref.listen` dentro de `build()` en su lugar

---

## QA-608 [P2]: Regresión general de UI

### Qué verificar
1. `dart analyze lib/` → 0 issues
2. No hay `Colors.xxx` hardcodeados (excepto `Colors.black` intencional en StandbyScreen/LiveProjectionScreen)
3. Todos los widgets tienen constructores `const` donde es posible
4. Los providers usan Riverpod manual (sin riverpod_annotation)

---

## PROCEDIMIENTO DE EJECUCIÓN

1. **Primero**: `dart analyze lib/` (QA-601)
2. **Segundo**: `flutter test` (QA-602)
3. **Tercero**: Revisión de código (QA-605, QA-606, QA-607, QA-608)
4. **Cuarto**: Pruebas interactivas (QA-603, QA-604)

---

*Fin de TASKS_QA_SPRINT5.md — 14 de mayo de 2026*
