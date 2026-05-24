# Guía de Build iOS — HimnarioID 2.0

> **Propósito**: Documentar el proceso completo para generar un `.ipa` (iOS App Store / Ad-hoc / Development) a partir del código fuente de HimnarioID 2.0.
>
> **Actualizado**: 22 de mayo de 2026

---

## ⚠️ Prerrequisito fundamental

**NO se puede buildear iOS desde Linux.** Se requiere **macOS** con **Xcode 16+** instalado.

Opciones disponibles:
| Opción | Descripción | Costo |
|--------|-------------|-------|
| 🥇 **Mac física** | MacBook, Mac mini, iMac con macOS Sonoma+ | Ya la tienes |
| 🥈 **GitHub Actions** | Runner `macos-latest` en CI/CD | Gratis (2000 min/mes) |
| 🥉 **Mac virtual** | MacStadium, MacinCloud, AWS Mac | $20-50/mes |

Además del hardware, necesitas:
- **Apple Developer Account** ($99/año) — para firmar el .ipa y probar en dispositivo real
- **Xcode 16+** — desde Mac App Store o https://developer.apple.com/xcode/
- **CocoaPods** — se instala automáticamente con `sudo gem install cocoapods`

---

## 📁 Estructura iOS del proyecto

```
ios/
├── Podfile                          ← Configuración de CocoaPods (incluye patch gRPC para Xcode 16+)
├── Flutter/
│   ├── Generated.xcconfig           ← Generado por flutter pub get
│   ├── flutter_export_environment.sh
│   └── ephemeral/                   ← Cache temporal
└── Runner/
    ├── AppDelegate.swift            ← Punto de entrada de la app (Swift)
    ├── GeneratedPluginRegistrant.h  ← Registro automático de plugins
    ├── GeneratedPluginRegistrant.m
    ├── Info.plist                   ← Permisos y configuración de la app
    └── Assets.xcassets/
        └── AppIcon.appiconset/
            └── Contents.json        ← Placeholder para iconos (hay que sustituir)
```

### Archivos creados manualmente

| Archivo | Propósito |
|---------|-----------|
| `ios/Podfile` | Patch gRPC-Core para Xcode 16+ (C++17). Sin esto, el build falla con errores de compilación en C++. |
| `ios/Runner/Info.plist` | Permisos: `NSLocalNetworkUsageDescription` (mDNS), `NSBonjourServices` (`_himnario._tcp`), `NSPhotoLibraryUsageDescription` (fondos), `UIBackgroundModes: audio`, `NSAllowsLocalNetworking` (gRPC LAN). |
| `ios/Runner/AppDelegate.swift` | `FlutterAppDelegate` estándar con registro de plugins. |
| `ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json` | Placeholder de iconos. Los archivos .png reales deben agregarse antes del build de producción. |

---

## 🚀 Método 1: Build local en macOS (recomendado)

### 1. Regenerar carpeta ios/ (solo la primera vez)

```bash
# Desde la raíz del proyecto
cd /ruta/a/HimnarioID_2.0

# Backup por si acaso
cp -r ios/ ios_backup_$(date +%Y%m%d)

# Regenerar archivos de iOS que falten (NO borra los existentes)
flutter create --platforms=ios --project-name=himnario_id_2 .
```

> **Importante**: `flutter create` es **idempotente** — no borra archivos existentes. Solo crea los que faltan (Main.storyboard, LaunchScreen.storyboard, etc.). Nuestros archivos personalizados (Podfile, Info.plist, AppDelegate.swift) ya están en su lugar.

### 2. Instalar dependencias

```bash
flutter pub get
cd ios && pod install && cd ..
```

> **Si `pod install` falla con errores de gRPC**: es porque el patch en el Podfile no se está aplicando. Verifica que el post_install en `ios/Podfile` tenga la configuración de `gRPC-Core` y `abseil` con `c++17`.

### 3. Configurar firma (signing) en Xcode

```bash
# Abrir el proyecto en Xcode
open ios/Runner.xcworkspace
```

En Xcode:
1. Selecciona `Runner` en el navegador de proyectos (izquierda)
2. Ve a **Signing & Capabilities**
3. Marca **"Automatically manage signing"** (o configura manual)
4. Selecciona tu **Team** (Apple Developer account)
5. El **Bundle Identifier** será `com.himnarioid.app` (o el que hayas registrado)

### 4a. Build para simulador (gratis, sin Developer Account)

```bash
flutter build ios --debug --simulator
# Output: build/ios/iphonesimulator/Runner.app
```

> Esto corre en el simulador de iOS. No requiere cuenta de desarrollador.

### 4b. Build para dispositivo (requiere Developer Account)

```bash
# Build del .app firmado
flutter build ios --release

# Output: build/ios/iphoneos/Runner.app
```

### 4c. Exportar .ipa desde Xcode (método manual)

1. En Xcode: **Product → Archive**
2. En la ventana Organizer: selecciona el archive más reciente
3. Click **"Distribute App"**
4. Elige método:
   - **Development** — para pruebas en dispositivos registrados
   - **Ad Hoc** — para distribuir a testers (hasta 100 dispositivos)
   - **App Store Connect** — para subir a App Store
5. Sigue los pasos → Xcode genera el `.ipa`

### 4d. Exportar .ipa desde terminal (método automatizado)

```bash
# 1. Crear archive
flutter build ios --release --no-codesign

# 2. Archivar con xcodebuild
xcodebuild -workspace ios/Runner.xcworkspace \
  -scheme Runner \
  -sdk iphoneos \
  -configuration Release \
  -archivePath build/ios/Runner.xcarchive \
  clean archive

# 3. Exportar .ipa
xcodebuild -exportArchive \
  -archivePath build/ios/Runner.xcarchive \
  -exportOptionsPlist ExportOptions.plist \
  -exportPath build/ios/ipa
```

> Necesitas crear `ExportOptions.plist` (ver sección 6).

---

## 🤖 Método 2: Build con GitHub Actions (CI/CD)

### Workflow disponible

El archivo `.github/workflows/build_ios.yml` ya está configurado en el repositorio.

### 2a. Build sin firma (unsigned .app)

1. Ve a tu repositorio en GitHub
2. **Actions → Build iOS (.ipa) → Run workflow**
3. Deja `codesign` en **false**
4. Click **Run workflow**

El workflow produce:
- `flutter analyze lib/` ✅
- `flutter test` ✅
- `flutter build ios --release --no-codesign` ✅
- Artefacto: `MQ_App-ios-unsigned_<version>.zip` (contiene `Runner.app`)

Para firmar localmente ese `.app`:
```bash
# Descargar y extraer el artefacto
# Firmar manualmente con tu certificado
codesign --force --sign "iPhone Developer: Tu Nombre (XXXXXXXX)" \
  --entitlements Runner.entitlements \
  Runner.app
```

### 2b. Build con firma (signed .ipa)

Antes de ejecutar, configura estos **secretos** en GitHub:

| Secreto | Valor | Cómo obtenerlo |
|---------|-------|----------------|
| `IOS_BUILD_CERTIFICATE_P12` | Certificado de desarrollo/distribución en base64 | `base64 -i Certificados.p12` |
| `IOS_BUILD_CERTIFICATE_PASSWORD` | Contraseña del .p12 | La que pusiste al exportar |
| `IOS_BUILD_PROVISION_PROFILE` | Provisioning profile en base64 | `base64 -i profile.mobileprovision` |
| `IOS_KEYCHAIN_PASSWORD` | Contraseña temporal para el keychain | Cualquier string seguro |
| `IOS_TEAM_ID` | Tu Team ID de Apple | En developer.apple.com → Membership |

#### Cómo generar certificados y profiles

```bash
# 1. Exportar certificado desde Keychain Access
#    Abrir Keychain Access → Mis Certificados
#    Seleccionar "iPhone Developer: ..."
#    Archivo → Exportar Items → .p12 (con contraseña)

# 2. Codificar a base64
base64 -i Certificados.p12 | pbcopy
# Pega esto en GitHub Secret: IOS_BUILD_CERTIFICATE_P12

# 3. Descargar provisioning profile desde developer.apple.com
#    Certificates, Identifiers & Profiles → Profiles → Download

# 4. Codificar a base64
base64 -i profile.mobileprovision | pbcopy
# Pega esto en GitHub Secret: IOS_BUILD_PROVISION_PROFILE
```

Luego ejecuta el workflow con `codesign: true` y selecciona el método de exportación.

---

## 📝 ExportOptions.plist

Archivo de configuración necesario para exportar el .ipa desde terminal:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>development</string>
    <key>teamID</key>
    <string>TU_TEAM_ID</string>
    <key>signingStyle</key>
    <string>manual</string>
    <key>stripSwiftSymbols</key>
    <true/>
    <key>compileBitcode</key>
    <false/>
</dict>
</plist>
```

Opciones de `method`:
| Valor | Uso |
|-------|-----|
| `development` | Pruebas en dispositivos registrados |
| `ad-hoc` | Distribución a testers (hasta 100 dispositivos) |
| `app-store` | Subida a App Store Connect |
| `enterprise` | Distribución interna (Enterprise account) |

---

## 🔧 Solución de problemas comunes

### Error: `gRPC-Core` no compila

```
error: 'std::...' file not found
```

**Causa**: Xcode 16+ usa Clang con C++14 por defecto. gRPC-Core requiere C++17.

**Solución**: El Podfile ya incluye el patch. Si persiste, verifica que el `post_install` en `ios/Podfile` tenga:

```ruby
if target.name == 'gRPC-Core'
  config.build_settings['CLANG_CXX_LANGUAGE_STANDARD'] = 'c++17'
  config.build_settings['CLANG_CXX_LIBRARY'] = 'libc++'
  config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] << 'GRPC_CORE=1'
end
```

### Error: `window_manager` plugin no encontrado

```
Failed to find plugin window_manager
```

**Causa**: `window_manager` es desktop-only pero el registro automático intenta cargarlo.

**Solución**: Ya está manejado en el código — `fullscreen_handler.dart` tiene guards de plataforma (`Platform.isIOS`, `Platform.isAndroid`, `kIsWeb`). El plugin no aparece en `GeneratedPluginRegistrant.m` porque solo se registra cuando `flutter pub get` detecta la plataforma.

### Error: `permission_handler` sin configuración

```
[access] This app has crashed because it attempted to access privacy-sensitive data
```

**Causa**: Falta la descripción de uso en Info.plist.

**Solución**: Ya está incluida en `ios/Runner/Info.plist`:
- `NSLocalNetworkUsageDescription` — para mDNS
- `NSPhotoLibraryUsageDescription` — para fondos
- `UIBackgroundModes: audio` — para reproducción en segundo plano

### Error: App Store reject por `NSAppTransportSecurity`

**Causa**: `NSAllowsLocalNetworking` permite conexiones HTTP locales.

**Solución**: Esto es aceptable para App Store si se justifica (comunicación LAN con displays). Incluir en los comentarios de revisión: "La app necesita comunicación local para el control remoto de displays de proyección en la misma red Wi-Fi."

### Error: Build falla con `Sandbox: rsync`

```
Sandbox: rsync (Xcode) deny(1) file-write-create
```

**Causa**: Xcode 16+ sandbox blocking CocoaPods scripts.

**Solución**:
```bash
# En el Podfile, agrega esta línea al post_install:
post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    target.build_configurations.each do |config|
      # Deshabilitar sandbox para pods
      config.build_settings['ENABLE_USER_SCRIPT_SANDBOXING'] = 'NO'
    end
  end
end
```

---

## 📱 Probar en dispositivo real

```bash
# 1. Conectar iPhone por USB
# 2. Abrir Xcode y seleccionar tu dispositivo como destino
# 3. Build & Run (⌘R)

# O desde terminal:
flutter run --release
```

> Para la primera ejecución, Xcode te pedirá:
> 1. Confiar en el desarrollador (Settings → General → VPN & Device Management)
> 2. Agregar tu Apple ID en Xcode → Settings → Accounts
> 3. Seleccionar tu Team en Signing & Capabilities

---

## 📊 Checklist pre-build

- [ ] ¿Tienes macOS con Xcode 16+?
- [ ] ¿Tienes Apple Developer Account ($99/año)?
- [ ] ¿Ejecutaste `pod install` en `ios/`?
- [ ] ¿Los iconos de la app están en `Assets.xcassets/AppIcon.appiconset/`?
- [ ] ¿El Bundle Identifier está registrado en developer.apple.com?
- [ ] ¿El provisioning profile incluye los dispositivos de prueba?
- [ ] ¿El `fullscreen_handler.dart` tiene guards de plataforma? (✅ ya incluido)
- [ ] ¿`flutter analyze` pasa sin errores?
- [ ] ¿`flutter test` pasa?

---

## 🔄 Flujo de trabajo recomendado

```
┌─────────────────────────────────────────────────────┐
│ 1. Hacer cambios en el código (Linux o cualquier OS) │
│    git add, git commit, git push                     │
└──────────────────────┬──────────────────────────────┘
                       ▼
┌─────────────────────────────────────────────────────┐
│ 2. GitHub Actions build iOS (unsigned)               │
│    Genera .app automáticamente                       │
└──────────────────────┬──────────────────────────────┘
                       ▼
┌─────────────────────────────────────────────────────┐
│ 3. Descargar .app desde GitHub Actions               │
└──────────────────────┬──────────────────────────────┘
                       ▼
┌─────────────────────────────────────────────────────┐
│ 4. En macOS: firmar y exportar .ipa                  │
│    Usando Xcode o命令行                               │
└──────────────────────┬──────────────────────────────┘
                       ▼
┌─────────────────────────────────────────────────────┐
│ 5. Instalar .ipa en dispositivo                      │
│    (AirDrop, MDM, App Center, TestFlight)            │
└─────────────────────────────────────────────────────┘
```

Este flujo permite:
- ✅ Desarrollar en cualquier OS (Linux, Windows, macOS)
- ✅ Build automatizado en la nube
- ✅ Firmar localmente (sin exponer certificados en GitHub)
- ✅ Probar en dispositivo real

---

## 📌 Notas finales

1. **gRPC en IPv6**: iOS favorece IPv6. Nuestra implementación de gRPC usa `IpLookupType.any` que soporta IPv6 e IPv4 automáticamente. ✅
2. **mDNS/Bonjour**: El discovery LAN usa `nsd_ios` en iOS (ya registrado en `GeneratedPluginRegistrant.m`). ✅
3. **Background audio**: Configurado en Info.plist con `UIBackgroundModes: audio`. ✅
4. **Fondos de imagen**: Usan `getApplicationDocumentsDirectory()` que respeta el sandbox de iOS. ✅
5. **SystemChrome.immersiveSticky**: Funciona en iOS pero las system gestures (swipe desde bordes) tienen prioridad sobre el gesture detector de la app. El usuario puede hacer swipe desde abajo para salir del modo fullscreen. ✅
