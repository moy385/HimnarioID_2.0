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
| `build_linux.yml` | `no matches found for MQ_App-linux-x64.tar.gz` en upload | El tar.gz se crea en `build/` pero el upload lo busca en la raiz. Usar `tar -czf MQ_App-linux-x64.tar.gz -C build/linux/x64/release bundle/` en vez de `cd` |
| `build_macos.yml` | `--no-codesign` no existe | Quitar el flag `--no-codesign`. En Flutter 3.41+ el build sin codesign es el default. |
| `build_macos.yml` | `Runner.app: No such file or directory` | El app ya no se llama `Runner.app`, ahora es `himnario_id_2.app` (Flutter 3.41.9+ cambio de default). Actualizar `APP_BUNDLE`. |
| `build_macos.yml` | `create-dmg` falla con "Could not find N" | `create-dmg` es problematico en CI. Usar solo `hdiutil` como fallback directo. |
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

### 5. Probar builds UNO POR UNO (workflow_dispatch)

No hagas tag push todavia. Primero prueba cada build individualmente con `workflow_dispatch`
para verificar que compilan bien. Esto evita saturarse con 3 builds fallando a la vez.

```bash
# Probar Windows
gh workflow run build_windows.yml --ref feature/nueva-interfaz-paleta-corporativa -f version=2.0.1

# Esperar a que termine y verificar
gh run list --workflow build_windows.yml --limit 1 --json status,conclusion

# Si pasa, probar Linux
gh workflow run build_linux.yml --ref feature/nueva-interfaz-paleta-corporativa -f version=2.0.1

# Esperar y verificar...

# Si pasa, probar macOS
gh workflow run build_macos.yml --ref feature/nueva-interfaz-paleta-corporativa -f version=2.0.1
```

> :warning: En `workflow_dispatch` el step de upload a GitHub Release **se salta**
> (porque `github.ref` no es un tag). Solo se prueba la compilacion.

### 6. Descargar artifacts de los builds exitosos

```bash
# Windows
gh run download <run-id> --dir /tmp/artifacts
# Linux
gh run download <run-id> --dir /tmp/artifacts
# macOS
gh run download <run-id> --dir /tmp/artifacts
```

### 7. Crear tag + release

```bash
git tag v2.0.1
git push origin v2.0.1
gh release create v2.0.1 --latest --title "MQ App v2.0.1" --notes "Release v2.0.1"
```

> :warning: **NO confiar en los workflows de tag push para subir assets.** El upload via
> `gh release upload` en tag push falla porque GitHub crea el release draft de forma
> asincrona y el workflow se ejecuta antes de que exista. Es mas confiable subir manualmente.

### 8. Build APKs Android (local)

```bash
./scripts/build_apk.sh 2.0.1
```

Esto genera:
- `build/app/outputs/flutter-apk/mq-app-arm64-v8a-2.0.1.apk`
- `build/app/outputs/flutter-apk/mq-app-armeabi-v7a-2.0.1.apk`
- `build/app/outputs/flutter-apk/mq-app-x86_64-2.0.1.apk`

### 9. Subir TODOS los assets al release (manual)

```bash
# APKs Android
cd build/app/outputs/flutter-apk
gh release upload v2.0.1 mq-app-arm64-v8a-2.0.1.apk --clobber
gh release upload v2.0.1 mq-app-armeabi-v7a-2.0.1.apk --clobber
gh release upload v2.0.1 mq-app-x86_64-2.0.1.apk --clobber

# Desktop (artifacts de CI descargados en paso 6)
gh release upload v2.0.1 /tmp/artifacts/*/MQ_App-windows-x64.zip --clobber
gh release upload v2.0.1 /tmp/artifacts/*/MQ_App-linux-x64.tar.gz --clobber
gh release upload v2.0.1 /tmp/artifacts/*/MQ_App-macos-x64.dmg --clobber
```

### 10. Verificar landing page

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
| `MQ_App-windows-x64.zip` | Windows | CI workflow_dispatch + descargar artifact |
| `MQ_App-linux-x64.tar.gz` | Linux | CI workflow_dispatch + descargar artifact |
| `MQ_App-macos-x64.dmg` | macOS | CI workflow_dispatch + descargar artifact |

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

### "El upload a GitHub Release falla con 'release not found' en tag push"

Esto ocurre porque cuando se pushea un tag, GitHub crea el release draft de forma
**asincrona**. El workflow corre antes de que el release exista oficialmente, y
`gh release upload` falla porque no encuentra el release.

**Solucion**: No confiar en el tag push para subir assets. Usar workflow_dispatch para
probar la compilacion, descargar artifacts manualmente, y subirlos con `gh release upload`.

### "El build compila en workflow_dispatch pero falla en tag push"

Es el mismo problema de arriba. El build en si compila bien (el mismo commit).
La unica diferencia es que en tag push se ejecuta el step de "Upload to GitHub Release"
(el `if: startsWith(github.ref, 'refs/tags/')` lo activa), y ese step falla porque el
release no existe aun.

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
