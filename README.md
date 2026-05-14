# HimnarioID_2.0
El desarrollo de esta aplicación se enfoca en brindar un mejor servicio a sus usuarios, haciendo que la experiencia de usuario sea única e impresionante

markdown_content = """# 📖 Proyecto: Himnario Multiplataforma & Sistema de Proyección Inteligente

Este repositorio contiene el código fuente y la arquitectura para la nueva generación del Himnario Web, evolucionado hacia un sistema de proyección controlable remotamente y gestión musical avanzada. 

El sistema está diseñado pensando en alta resiliencia offline (ideal para entornos con conectividad inestable, como suele ocurrir en algunas zonas de El Salvador) y permite que un dispositivo móvil controle la proyección en una PC o TV mediante la red local (LAN).

---

## 🎯 Requerimientos y Objetivos del Sistema

1. **Uso Dual (Personal y Proyección):**
   - **Modo Personal:** Visualización fluida (scroll) de las estrofas y coros, con herramientas flotantes para músicos (transposición, acordes, reproducción de pistas).
   - **Modo Proyección:** Paneles minimalistas de control remoto y visualización de estrofas estáticas para el público.
2. **Roles Dinámicos (Emisor / Receptor):** Cualquier dispositivo en la red puede actuar como el control remoto (Emisor) o como la pantalla de presentación (Receptor) mediante una conexión gRPC over LAN.
3. **Soporte Multi-Ventana (Desktop):** En PC, el sistema puede separar el panel de control (ventana principal) de la proyección visual (ventana secundaria o pantalla extendida).
4. **Módulo Administrativo Integrado:** Un backoffice protegido por credenciales dentro de la misma app para gestionar el CRUD completo de himnos, categorías, pistas y fondos sin depender de software externo.
5. **Resiliencia Offline:** Base de datos embebida (SQLite) y red de área local (mDNS) para funcionar sin conexión a Internet.

---

## 🛠️ Stack Tecnológico

* **Frontend y Lógica de Cliente/Servidor:** Flutter (Dart).
* **Comunicación de Red (LAN):** gRPC con Protocol Buffers.
* **Descubrimiento de Red (Service Discovery):** mDNS (Multicast DNS) para encontrar automáticamente la PC desde el móvil.
* **Motor de Base de Datos:** SQLite (Serverless, local, embebida en la app).
* **Formato de Letra y Acordes:** ChordPro (ej. `[G]Dios es [C]amor`).

---

## 🏗️ Arquitectura de Software y Soluciones Técnicas

### 1. Comunicación (gRPC over LAN)
Se descarta el uso de infrarrojo, Bluetooth y APIs REST. El celular actúa como **Cliente gRPC** y la PC/TV como **Servidor gRPC**. Esto garantiza una latencia mínima usando mensajes binarios (Protobuf), permitiendo enviar comandos ("Siguiente Estrofa") y recibir el estado actual de la pantalla en milisegundos.

### 2. Transposición de Tonalidades
No se guardan acordes en campos separados. Se utiliza el estándar **ChordPro**. 
* **Lógica:** Flutter extrae mediante Regex todo lo que está entre corchetes `[]` en el texto de la base de datos, lo busca en un arreglo circular de notas `['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B']` y lo desplaza los semitonos requeridos en tiempo real antes de renderizar la pantalla.

### 3. Personalización de Arreglos (El patrón "Fork")
Para evitar que un músico modifique el himno oficial de la congregación, se implementa un sistema de derivación (Fork). Los datos oficiales son inmutables. Cuando un usuario quiere alterar acordes, el sistema copia las estrofas a la tabla `Estrofa_Arreglo`, vinculándolas a su ID de `Usuario`. La app cargará esta versión personalizada únicamente para ese usuario.

---

## 🏗️ Novedades de Arquitectura UI (Dev Mode)
Para facilitar el desarrollo en entornos Linux sin necesidad de compilar constantemente a un dispositivo móvil físico, la rama de desarrollo incluye un **Switch `(PC/Celular)`** en la esquina inferior izquierda del Dashboard. 
Este switch inyecta la lógica de la plataforma correspondiente, forzando a la app a redibujarse simulando el comportamiento de escritorio (doble ventana, presentación) o de móvil (scroll, FAB dinámico). *Esta opción será reemplazada en producción por la detección nativa de `Platform.isAndroid` o `Platform.isWindows`.*

---

## 🗄️ Estructura de Base de Datos (SQLite)

La base de datos sigue un modelo fuertemente relacional. *Nota arquitectónica: La tabla de usuarios debe llamarse estrictamente `Usuario`.*

### Tablas Maestras
* **`Himno`**
  * `id` (PK, Integer)
  * `titulo_principal` (Text)
  * `numero_oficial` (Integer, Nullable)
  * `tipo` (Integer: 1=Oficial, 2=Inspirada, 3=Convención)
* **`Version_Pais`**
  * `id` (PK, Integer)
  * `himno_id` (FK -> Himno.id)
  * `pais` (Text)
  * `tonalidad_original` (Text, ej. "G")
* **`Estrofa`** (Oficial)
  * `id` (PK, Integer)
  * `version_pais_id` (FK -> Version_Pais.id)
  * `tipo` (Text: Coro, Estrofa, Puente)
  * `orden` (Integer)
  * `contenido` (Text, formato ChordPro)

### Tablas de Categorización (N:M)
* **`Categoria`**
  * `id` (PK, Integer)
  * `nombre` (Text)
* **`Himno_Categoria`**
  * `himno_id` (FK -> Himno.id)
  * `categoria_id` (FK -> Categoria.id)

### Sistema de Arreglos Personalizados (Forks) y Auditoría
* **`Usuario`**
  * `id` (PK, Integer)
  * `nombre` (Text)
  * `rol` (Text: Admin, Musico, Visualizador)
* **`Arreglo_Musical`**
  * `id` (PK, Integer)
  * `version_pais_id` (FK -> Version_Pais.id)
  * `usuario_id` (FK -> Usuario.id)
  * `nombre_arreglo` (Text)
  * `tonalidad_base` (Text)
* **`Estrofa_Arreglo`** (Personalizada)
  * `id` (PK, Integer)
  * `arreglo_musical_id` (FK -> Arreglo_Musical.id)
  * `tipo` (Text)
  * `orden` (Integer)
  * `contenido` (Text, formato ChordPro con las ediciones del músico)

### Multimedia
* **`Pista_Audio`**
  * `id` (PK, Integer)
  * `himno_id` (FK -> Himno.id)
  * `ruta_archivo` (Text, ruta local)
  * `descripcion` (Text)
  * `usuario_donante_id` (FK -> Usuario.id)

---

## 📂 Estructura de Carpetas Recomendada (Clean Architecture)

Para que el equipo de trabajo o cualquier agente de IA entienda el código, se recomienda la siguiente estructura basada en *Clean Architecture* orientada a Flutter:
[file-tag: README.md]

```text
lib/
│
├── core/                   # Archivos compartidos, utilidades y configuración
│   ├── constants/          # Constantes (colores, arrays musicales de transposición)
│   ├── network/            # Configuración de mDNS y discovery de red
│   └── database/           # Configuración de SQLite y migraciones
│
├── protos/                 # Definiciones de gRPC (.proto) 
│   ├── hymn_control.proto  # Contratos de los mensajes LAN
│   └── generated/          # Código Dart autogenerado por protoc
│
├── data/                   # Capa de datos
│   ├── models/             # Modelos de SQLite (HimnoModel, UsuarioModel...)
│   ├── datasources/        # Consultas crudas a SQLite y llamadas gRPC
│   └── repositories/       # Implementación de los repositorios
│
├── domain/                 # Lógica de negocio pura (independiente del framework)
│   ├── entities/           # Entidades (Himno, ArregloMusical)
│   ├── usecases/           # Casos de uso (ej. TransposeChordsUseCase, CreateForkUseCase)
│   └── repositories/       # Interfaces de repositorios
│
└── presentation/           # Capa visual (Flutter UI)
    ├── app_display/        # UI específica para la PC / TV (Visualización)
    ├── app_controller/     # UI específica para el Celular (Control Remoto)
    ├── shared_widgets/     # Widgets comunes (ej. renderizador de ChordPro)
    └── state_management/   # Gestores de estado (Riverpod, Bloc, o Provider)
