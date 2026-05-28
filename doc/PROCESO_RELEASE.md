# Proceso de Release

> :warning: **Importante**: NO hacer merge a `main` sin autorización del usuario.
> Todo release se hace desde la branch activa (`feature/nueva-interfaz-paleta-corporativa`).

---

## Pasos para publicar un nuevo release

### 1. Crear documentacion

Este archivo es el primero. Asegurate de leerlo antes de seguir.

### 2. Arreglar los workflows de CI (si es necesario)

Los archivos estan en `.github/workflows/`. Errores comunes:

| Workflow | Error conocido | Fix |
|----------|---------------|-----|
| `build_linux.yml` | `gstreamer-1.0 not found` | Agregar `libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev` al `apt-get install` |
| `build_macos.yml` | `--no-codesign` no existe | Quitar el flag `--no-codesign` |
| `build_linux.yml` / `build_macos.yml` | Swift Package Manager / plugin incompatibility con Flutter 3.44+ | Pinear `flutter-version: '3.41.9'` en el step de `subosito/flutter-action` |

Siempre verifica que los workflows pasen antes de crear el tag.

### 3. Actualizar version

Editar `pubspec.yaml`:

```yaml
version: 2.0.1+1
#        ^^^^^-- subir el numero de version
#             ^^-- opcional: subir el build number
```

### 4. Commit + push

```bash
git add -A
git commit -m "chore: bump version to 2.0.1"
git push origin feature/nueva-interfaz-paleta-corporativa
```

### 5. Crear tag

```bash
# Desde la feature branch
git checkout feature/nueva-interfaz-paleta-corporativa
git tag v2.0.1
git push origin v2.0.1
```

Esto activa los workflows `build_linux.yml`, `build_macos.yml` y `build_windows.yml` (todos tienen `on: push: tags: 'v*.*.*'`).

### 6. Monitorear los builds

```bash
gh run list --limit 10
```

Verificar que pasen:
- **Windows build**: `MQ_App-windows-x64_v2.0.1.zip` se sube automaticamente al release
- **Linux build**: `MQ_App-linux-x64.tar.gz` se sube automaticamente al release
- **macOS build**: `MQ_App-macos-x64.dmg` se sube automaticamente al release

> :warning: Si un build falla, arreglar el workflow, hacer commit en la feature branch, y volver al paso 4.
> Los assets ya subidos no se pierden (gh release upload usa --clobber).

### 7. Build APKs Android (local)

```bash
./scripts/build_apk.sh 2.0.1
```

Esto genera:
- `build/app/outputs/flutter-apk/mq-app-arm64-v8a-2.0.1.apk`
- `build/app/outputs/flutter-apk/mq-app-armeabi-v7a-2.0.1.apk`
- `build/app/outputs/flutter-apk/mq-app-x86_64-2.0.1.apk`

### 8. Subir APKs al release

```bash
cd build/app/outputs/flutter-apk
gh release upload v2.0.1 mq-app-arm64-v8a-2.0.1.apk --clobber
gh release upload v2.0.1 mq-app-armeabi-v7a-2.0.1.apk --clobber
gh release upload v2.0.1 mq-app-x86_64-2.0.1.apk --clobber
```

### 9. Verificar landing page

La landing page (melquisedec-ark.github.io) usa la API de GitHub para listar los assets del ultimo release:

```javascript
// main.js linea relevante:
const url = 'https://api.github.com/repos/moy385/HimnarioID_2.0/releases/latest';
```

Solo hay que refrescar la pagina. Los nombres de los assets deben coincidir con los que busca la landing page.

---

## Assets esperados en el release

| Asset | Plataforma | Se genera via |
|-------|-----------|---------------|
| `mq-app-arm64-v8a-<version>.apk` | Android (celulares modernos) | `scripts/build_apk.sh` (local) |
| `mq-app-armeabi-v7a-<version>.apk` | Android (celulares antiguos) | `scripts/build_apk.sh` (local) |
| `mq-app-x86_64-<version>.apk` | Android (emuladores) | `scripts/build_apk.sh` (local) |
| `MQ_App-windows-x64.zip` | Windows | CI workflow (tag push) |
| `MQ_App-linux-x64.tar.gz` | Linux | CI workflow (tag push) |
| `MQ_App-macos-x64.dmg` | macOS | CI workflow (tag push) |

---

## Errores frecuentes

### "No puedo hacer merge a main"

No hagas merge. Todo el codigo de la app se queda en la feature branch.
Los workflows de CI se ejecutan desde la feature branch (ya estan ahi).
El tag se crea en la feature branch.

### "El build de Linux falla por gstreamer"

Agregar al workflow:
```yaml
sudo apt-get install -y ... libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev
```

### "El build de macOS falla por --no-codesign"

El flag `--no-codesign` no existe en Flutter 3.44+. Simplemente quitarlo:
```yaml
run: flutter build macos --release
```

### "Windows build no se ejecuta"

Los workflows de Windows requieren `windows-latest` runner. El tag push lo activa.
Si no se ejecuto, verificar que el tag tenga `v` al inicio (ej: `v2.0.1`).

---

## Comandos utiles

```bash
# Ver assets de un release
gh release view v2.0.1 --json assets

# Subir asset a release existente
gh release upload v2.0.1 archivo.zip --clobber

# Eliminar asset de un release
gh release delete-asset v2.0.1 nombre-del-asset

# Trigger manual de Windows (sin tag)
gh workflow run build_windows.yml --ref feature/nueva-interfaz-paleta-corporativa -f version=2.0.1
```
