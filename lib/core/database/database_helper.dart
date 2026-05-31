import 'dart:io' show Platform, File, Directory;
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:sqflite/sqflite.dart' as mobile;
import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as desktop;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:logging/logging.dart';

import 'db_version_manager.dart';
/// Logger estructurado para eventos de base de datos.
final _log = Logger('DatabaseHelper');

/// Helper singleton para la gestión de la base de datos SQLite.
/// Encapsula la inicialización, migraciones y acceso a la BD.
class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  /// Creates a helper backed by an already-open database instance (for testing).
  /// The caller is responsible for creating the database with the proper schema.
  factory DatabaseHelper.forTesting(Database database) {
    final helper = DatabaseHelper._();
    helper._database = database;
    return helper;
  }

  Database? _database;

  /// Versión del esquema SQLite (migraciones de tabla/columna).
  ///
  /// SCHEMA_VERSION: controla las migraciones estructurales de la BD
  /// mediante onUpgrade(). Es independiente de la versión del asset
  /// (db_version.json) que controla actualizaciones de seed data.
  static const int SCHEMA_VERSION = 7;

  /// Obtiene la instancia de la base de datos, inicializándola si es necesario.
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Inicializa la base de datos con merge automático desde assets.
  ///
  /// A diferencia del enfoque anterior (backup + reemplazar + restore),
  /// este metodo NUNCA reemplaza la BD local del usuario. En su lugar,
  /// solo AGREGA los himnos nuevos del asset, preservando intactos:
  ///   - Arreglos musicales del usuario (con sus FK)
  ///   - Himnos creados por el usuario
  ///   - Fondos de pantalla personalizados
  ///   - Configuracion, historial, etc.
  ///
  /// Flujo:
  /// 1. Si la BD local no existe → se copia desde assets (primera instalacion).
  /// 2. Se abre con onCreate/onUpgrade (migraciones de esquema).
  /// 3. Si assetVersion > localVersion → solo se mergean los himnos nuevos.
  /// 4. Se escribe db_version.txt.
  Future<Database> _initDatabase() async {
    final stopwatch = Stopwatch()..start();

    // ── Modo desarrollo (desktop + debug): BD directa del proyecto ──
    if (kDebugMode && !Platform.isAndroid && !Platform.isIOS) {
      final projectDb = p.join(
        Directory.current.path,
        'assets/db/himnario_id.db',
      );
      _log.info('Debug mode: using project DB at $projectDb');
      final db = await _openDatabasePlatform(projectDb);
      _log.info(
        'Database opened (schema v$SCHEMA_VERSION) in '
        '${stopwatch.elapsedMilliseconds}ms',
      );
      return db;
    }

    // ── Modo release / mobile ───────────────────────────────────
    final dir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(dir.path, 'himnario_id.db');
    final localFile = File(dbPath);

    // 1. Si no existe BD local, copiar desde assets (primera instalacion)
    if (!localFile.existsSync()) {
      _log.info('No local DB found, copying from assets...');
      try {
        final bytes = await DbVersionManager.assetDbBytes();
        if (bytes.isNotEmpty) {
          await localFile.writeAsBytes(bytes);
          _log.info('Fresh DB copied from assets (${bytes.length} bytes)');

          // Escribir localVersion INMEDIATAMENTE para que needsUpdate()
          // retorne false (assetVersion == localVersion) y se SKIPEE
          // el merge en primera instalacion — es innecesario porque
          // la BD recien copiada ya contiene todos los datos del asset.
          final assetVer = await DbVersionManager.readAssetVersion();
          if (assetVer > 0) {
            await DbVersionManager.writeLocalVersion(dir.path, assetVer);
            _log.info('Local version written early: $assetVer (merge skipped)');
          }
        }
      } catch (_) {
        _log.info('No asset DB available, will create fresh schema');
      }
    }

    // 2. Abrir BD local (con onCreate/onUpgrade para migraciones de esquema)
    final db = await _openDatabasePlatform(dbPath);

    // 3. Merge de himnos nuevos desde el asset (sin tocar datos de usuario)
    final assetVersion = await DbVersionManager.readAssetVersion();
    final localVersion = await DbVersionManager.readLocalVersion(dir.path);

    if (DbVersionManager.needsUpdate(assetVersion, localVersion)) {
      _log.info(
        'Merging seed data: assetVersion=$assetVersion, '
        'localVersion=$localVersion',
      );
      try {
        await _mergeNewHymnsFromAsset(db);
        _log.info('Seed data merged successfully');
      } catch (e) {
        _log.severe('Failed to merge seed data: $e');
        // Si falla el merge, la app continua con los datos que tenga.
        // En el proximo inicio se reintentara.
      }

      // 4. Escribir version local
      if (assetVersion > 0) {
        await DbVersionManager.writeLocalVersion(dir.path, assetVersion);
        _log.info('Local version written: $assetVersion');
      }
    }

    _log.info(
      'Database opened (schema v$SCHEMA_VERSION) in '
      '${stopwatch.elapsedMilliseconds}ms',
    );
    return db;
  }

  /// Mergea datos del asset DB a la BD local del usuario.
  ///
  /// Tres operaciones, en este orden:
  /// 1. **Pais y Categoria** — INSERT de nuevos registros (para integridad FK).
  /// 2. **Himno** — Match por `id` (PRIMARY KEY). Si no coincide el id,
  ///    intenta fallback por `(numero_oficial, tipo)` para compatibilidad
  ///    con BD anteriores a v2.1.2. Si no existe → INSERT con id explicito
  ///    del asset. Si existe → UPDATE en el mismo registro.
  /// 3. **Version_Pais y Estrofa** — UPDATE en el mismo registro cuando
  ///    coincide (himno_id+pais_id o version_pais_id+orden), INSERT si es nuevo.
  ///    Nunca se borran registros locales, para no romper arreglos del usuario.
  ///
  /// Las tablas de usuario (Arreglo_Musical, Estrofa_Arreglo, Usuario,
  /// Fondo_Pantalla, Preferencias, Historial) NO se tocan.
  Future<void> _mergeNewHymnsFromAsset(Database localDb) async {
    final assetBytes = await DbVersionManager.assetDbBytes();
    if (assetBytes.isEmpty) return;

    final tempDir = await getApplicationDocumentsDirectory();
    final tempPath = p.join(tempDir.path, 'himnario_id_asset_temp.db');
    await File(tempPath).writeAsBytes(assetBytes);

    Database? assetDb;
    try {
      assetDb = await _openDatabaseRaw(tempPath);

      // ── 1. Pais y Categoria (nuevos, para integridad FK) ──────
      final assetCountries = await assetDb.query('Pais');
      for (final c in assetCountries) {
        await localDb.insert('Pais', c, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
      final assetCategories = await assetDb.query('Categoria');
      for (final c in assetCategories) {
        await localDb.insert('Categoria', c, conflictAlgorithm: ConflictAlgorithm.ignore);
      }

      // ── 2. Himno ────────────────────────────────────────────────
      final assetHymns = await assetDb.query(
        'Himno',
        where: 'numero_oficial IS NOT NULL',
      );
      if (assetHymns.isEmpty) return;

      int inserted = 0, updated = 0;

      for (final assetHymn in assetHymns) {
        final oldAssetHymnId = assetHymn['id'] as int;
        final numeroOficial = assetHymn['numero_oficial'] as int;
        final tipo = assetHymn['tipo'] as int;

        // 1. Match por id (PRIMARY KEY única, segura incluso para himnos
        //    que comparten numero_oficial+tipo — ej: himno 290 tiene dos
        //    himnos oficiales con distintos paises e ids).
        var localHymns = await localDb.query(
          'Himno',
          where: 'id = ?',
          whereArgs: [oldAssetHymnId],
        );

        // 2. Fallback por (numero_oficial, tipo) para compatibilidad
        //    con BD locales creadas antes de v2.1.2 donde el merge
        //    anterior pudo haber insertado himnos con id diferente.
        if (localHymns.isEmpty) {
          localHymns = await localDb.query(
            'Himno',
            where: 'numero_oficial = ? AND tipo = ?',
            whereArgs: [numeroOficial, tipo],
          );
        }

        int localHymnId;

        if (localHymns.isEmpty) {
          // Himno NUEVO → INSERT con id explicito del asset
          // para que futuros merges matcheen correctamente por id.
          localHymnId = await localDb.insert('Himno', {
            'id': oldAssetHymnId,
            'titulo_principal': assetHymn['titulo_principal'],
            'numero_oficial': numeroOficial,
            'tipo': tipo,
            'activo': assetHymn['activo'],
            if (assetHymn['evento'] != null) 'evento': assetHymn['evento'],
          });
          inserted++;
        } else {
          // Himno EXISTENTE → UPDATE (correcciones: titulo, acordes, etc.)
          localHymnId = localHymns.first['id'] as int;
          await localDb.update(
            'Himno',
            {
              'titulo_principal': assetHymn['titulo_principal'],
              'tipo': tipo,
              'activo': assetHymn['activo'],
              if (assetHymn['evento'] != null) 'evento': assetHymn['evento'],
            },
            where: 'id = ?',
            whereArgs: [localHymnId],
          );
          updated++;
        }

        // ── 3. Version_Pais ───────────────────────────────────────
        // Mapeo: id del asset → id local (para estrofas)
        final versionMap = <int, int>{};

        final assetVersions = await assetDb.query(
          'Version_Pais',
          where: 'himno_id = ?',
          whereArgs: [oldAssetHymnId],
        );

        for (final assetVersion in assetVersions) {
          final paisId = assetVersion['pais_id'] as int;
          final oldAssetVersionId = assetVersion['id'] as int;

          final localVersions = await localDb.query(
            'Version_Pais',
            where: 'himno_id = ? AND pais_id = ?',
            whereArgs: [localHymnId, paisId],
          );

          if (localVersions.isEmpty) {
            // Version NUEVA → INSERT
            final newVersionId = await localDb.insert('Version_Pais', {
              'himno_id': localHymnId,
              'pais_id': paisId,
              'tonalidad_original': assetVersion['tonalidad_original'],
              'activo': assetVersion['activo'],
            });
            versionMap[oldAssetVersionId] = newVersionId;
          } else {
            // Version EXISTENTE → UPDATE (tonalidad, activo)
            final localVersionId = localVersions.first['id'] as int;
            await localDb.update(
              'Version_Pais',
              {
                'tonalidad_original': assetVersion['tonalidad_original'],
                'activo': assetVersion['activo'],
              },
              where: 'id = ?',
              whereArgs: [localVersionId],
            );
            versionMap[oldAssetVersionId] = localVersionId;
          }
        }

        // ── Estrofa ───────────────────────────────────────────────
        for (final entry in versionMap.entries) {
          final oldAssetVersionId = entry.key;
          final localVersionId = entry.value;

          final assetStanzas = await assetDb.query(
            'Estrofa',
            where: 'version_pais_id = ?',
            whereArgs: [oldAssetVersionId],
            orderBy: 'orden ASC',
          );

          for (final assetStanza in assetStanzas) {
            final orden = assetStanza['orden'] as int;

            final localStanzas = await localDb.query(
              'Estrofa',
              where: 'version_pais_id = ? AND orden = ?',
              whereArgs: [localVersionId, orden],
            );

            if (localStanzas.isEmpty) {
              // Estrofa NUEVA → INSERT
              await localDb.insert('Estrofa', {
                'version_pais_id': localVersionId,
                'tipo': assetStanza['tipo'],
                'orden': orden,
                'contenido': assetStanza['contenido'],
              });
            } else {
              // Estrofa EXISTENTE → UPDATE (contenido corregido)
              await localDb.update(
                'Estrofa',
                {
                  'tipo': assetStanza['tipo'],
                  'contenido': assetStanza['contenido'],
                },
                where: 'version_pais_id = ? AND orden = ?',
                whereArgs: [localVersionId, orden],
              );
            }
          }
        }

        // ── Himno_Categoria ───────────────────────────────────────
        final assetCats = await assetDb.query(
          'Himno_Categoria',
          where: 'himno_id = ?',
          whereArgs: [oldAssetHymnId],
        );
        for (final ac in assetCats) {
          await localDb.insert(
            'Himno_Categoria',
            {'himno_id': localHymnId, 'categoria_id': ac['categoria_id']},
            conflictAlgorithm: ConflictAlgorithm.ignore,
          );
        }
      }

      _log.info(
        'Merge complete: $inserted inserted, $updated updated, '
        '${assetHymns.length} total hymns processed',
      );
    } finally {
      await assetDb?.close();
      try {
        await File(tempPath).delete();
      } catch (_) {}
    }
  }

  /// Abre una base de datos SQLite sin gestión de versiones.
  ///
  /// Útil para operaciones de backup/restore donde no se necesita
  /// onCreate/onUpgrade. Activa PRAGMA foreign_keys para mantener
  /// integridad referencial durante el restore.
  Future<Database> _openDatabaseRaw(String path) async {
    final Database db;
    if (Platform.isAndroid || Platform.isIOS) {
      db = await mobile.openDatabase(path);
    } else {
      desktop.sqfliteFfiInit();
      db = await desktop.databaseFactoryFfi.openDatabase(path);
    }
    await db.execute('PRAGMA foreign_keys = ON;');
    return db;
  }

  /// Abre una base de datos SQLite con gestión completa de versiones
  /// (onCreate + onUpgrade), seleccionando automáticamente el backend
  /// adecuado según la plataforma.
  Future<Database> _openDatabasePlatform(String path) async {
    if (Platform.isAndroid || Platform.isIOS) {
      return await mobile.openDatabase(
        path,
        version: SCHEMA_VERSION,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
    } else {
      desktop.sqfliteFfiInit();
      return await desktop.databaseFactoryFfi.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: SCHEMA_VERSION,
          onCreate: _onCreate,
          onUpgrade: _onUpgrade,
        ),
      );
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('PRAGMA foreign_keys = ON;');
    // ─── TABLAS ───────────────────────────────────────────────────
    await db.execute('''
      CREATE TABLE Himno (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        titulo_principal TEXT NOT NULL,
        numero_oficial INTEGER,
        tipo INTEGER NOT NULL CHECK(tipo IN (1, 2, 3)),
        evento TEXT,
        activo INTEGER NOT NULL DEFAULT 1,
        fecha_creacion TEXT NOT NULL DEFAULT (datetime('now'))
      );
    ''');

    await db.execute('''
      CREATE TABLE Pais (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL UNIQUE,
        codigo TEXT
      );
    ''');

    await db.execute('''
      CREATE TABLE Version_Pais (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        himno_id INTEGER NOT NULL,
        pais_id INTEGER NOT NULL REFERENCES Pais(id),
        tonalidad_original TEXT NOT NULL DEFAULT 'C',
        activo INTEGER NOT NULL DEFAULT 1,
        FOREIGN KEY (himno_id) REFERENCES Himno(id) ON DELETE CASCADE
      );
    ''');

    await db.execute('''
      CREATE TABLE Estrofa (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        version_pais_id INTEGER NOT NULL,
        tipo TEXT NOT NULL CHECK(tipo IN ('Coro', 'Estrofa', 'Puente', 'Intro', 'Final')),
        orden INTEGER NOT NULL,
        contenido TEXT NOT NULL,
        FOREIGN KEY (version_pais_id) REFERENCES Version_Pais(id) ON DELETE CASCADE
      );
    ''');

    await db.execute('''
      CREATE TABLE Categoria (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL UNIQUE
      );
    ''');

    await db.execute('''
      CREATE TABLE Himno_Categoria (
        himno_id INTEGER NOT NULL,
        categoria_id INTEGER NOT NULL,
        PRIMARY KEY (himno_id, categoria_id),
        FOREIGN KEY (himno_id) REFERENCES Himno(id) ON DELETE CASCADE,
        FOREIGN KEY (categoria_id) REFERENCES Categoria(id) ON DELETE CASCADE
      );
    ''');

    await db.execute('''
      CREATE TABLE Usuario (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL UNIQUE,
        password_hash TEXT NOT NULL,
        nombre TEXT NOT NULL,
        rol TEXT NOT NULL DEFAULT 'Musico' CHECK(rol IN ('Admin', 'Musico', 'Visualizador')),
        fecha_registro TEXT NOT NULL DEFAULT (datetime('now'))
      );
    ''');

    await db.execute('''
      CREATE TABLE Arreglo_Musical (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        version_pais_id INTEGER NOT NULL,
        usuario_id INTEGER NOT NULL,
        nombre_arreglo TEXT NOT NULL,
        tonalidad_base TEXT NOT NULL,
        version INTEGER NOT NULL DEFAULT 1,
        fecha_creacion TEXT NOT NULL DEFAULT (datetime('now')),
        fecha_modificacion TEXT NOT NULL DEFAULT (datetime('now')),
        FOREIGN KEY (version_pais_id) REFERENCES Version_Pais(id) ON DELETE CASCADE,
        FOREIGN KEY (usuario_id) REFERENCES Usuario(id) ON DELETE CASCADE
      );
    ''');

    await db.execute('''
      CREATE TABLE Estrofa_Arreglo (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        arreglo_musical_id INTEGER NOT NULL,
        tipo TEXT NOT NULL CHECK(tipo IN ('Coro', 'Estrofa', 'Puente', 'Intro', 'Final')),
        orden INTEGER NOT NULL,
        contenido TEXT NOT NULL,
        FOREIGN KEY (arreglo_musical_id) REFERENCES Arreglo_Musical(id) ON DELETE CASCADE
      );
    ''');

    await db.execute('''
      CREATE TABLE Pista_Audio (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        himno_id INTEGER NOT NULL,
        ruta_archivo TEXT NOT NULL,
        descripcion TEXT,
        origen TEXT NOT NULL DEFAULT 'local',
        duracion_segundos REAL,
        formato TEXT,
        usuario_donante_id INTEGER,
        FOREIGN KEY (himno_id) REFERENCES Himno(id) ON DELETE CASCADE,
        FOREIGN KEY (usuario_donante_id) REFERENCES Usuario(id) ON DELETE SET NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE Configuracion (
        clave TEXT PRIMARY KEY,
        valor TEXT NOT NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE Fondo_Pantalla (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        tipo TEXT NOT NULL CHECK(tipo IN ('imagen', 'color_solido')),
        ruta_archivo TEXT,
        color_hex TEXT,
        es_predeterminado INTEGER NOT NULL DEFAULT 0,
        activo INTEGER NOT NULL DEFAULT 1
      );
    ''');

    await db.execute('''
      CREATE TABLE Historial_Reproduccion (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        himno_id INTEGER NOT NULL,
        version_pais_id INTEGER,
        timestamp TEXT NOT NULL DEFAULT (datetime('now')),
        FOREIGN KEY (himno_id) REFERENCES Himno(id) ON DELETE CASCADE
      );
    ''');

    // ─── Himno_Busqueda (índice plano de búsqueda) ───
    await db.execute('''
      CREATE TABLE IF NOT EXISTS Himno_Busqueda (
        himno_id INTEGER PRIMARY KEY,
        titulo_normalizado TEXT NOT NULL DEFAULT '',
        contenido_normalizado TEXT NOT NULL DEFAULT '',
        FOREIGN KEY (himno_id) REFERENCES Himno(id) ON DELETE CASCADE
      );
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_busqueda_titulo ON Himno_Busqueda(titulo_normalizado);',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_busqueda_contenido ON Himno_Busqueda(contenido_normalizado);',
    );

    // Crear índices
    await db.execute('CREATE INDEX idx_himno_numero ON Himno(numero_oficial);');
    await db
        .execute('CREATE INDEX idx_version_himno ON Version_Pais(himno_id);');
    await db.execute(
      'CREATE UNIQUE INDEX idx_version_pais_unica ON Version_Pais(himno_id, pais_id);',
    );
    await db.execute(
      'CREATE INDEX idx_estrofa_version ON Estrofa(version_pais_id, orden);',
    );
    await db.execute(
      'CREATE INDEX idx_arreglo_usuario ON Arreglo_Musical(usuario_id);',
    );
    await db.execute(
      'CREATE INDEX idx_estrofa_arreglo ON Estrofa_Arreglo(arreglo_musical_id, orden);',
    );
    await db.execute('CREATE INDEX idx_pista_himno ON Pista_Audio(himno_id);');
    await db.execute(
      'CREATE INDEX idx_historial_timestamp ON Historial_Reproduccion(timestamp DESC);',
    );
    await db.execute('CREATE INDEX idx_himno_activo ON Himno(activo);');
    await db.execute(
      'CREATE INDEX idx_hc_categoria ON Himno_Categoria(categoria_id);',
    );

    // Crear vistas
    await db.execute('''
      CREATE VIEW IF NOT EXISTS v_himno_resumen AS
      SELECT
        h.id,
        h.titulo_principal,
        h.numero_oficial,
        h.tipo,
        h.activo,
        p.nombre AS pais,
        vp.tonalidad_original
      FROM Himno h
      LEFT JOIN Version_Pais vp ON vp.himno_id = h.id AND vp.activo = 1
      LEFT JOIN Pais p ON p.id = vp.pais_id
      ORDER BY h.numero_oficial;
    ''');

    await db.execute('''
      CREATE VIEW IF NOT EXISTS v_himno_estrofas AS
      SELECT
        vp.himno_id,
        vp.id AS version_pais_id,
        COUNT(e.id) AS total_estrofas,
        SUM(CASE WHEN e.tipo = 'Coro' THEN 1 ELSE 0 END) AS total_coros
      FROM Version_Pais vp
      LEFT JOIN Estrofa e ON e.version_pais_id = vp.id
      GROUP BY vp.himno_id, vp.id;
    ''');

  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Migración de versión 1 a 2:
      // Agregar columnas username y password_hash a Usuario
      await db.execute('ALTER TABLE Usuario ADD COLUMN username TEXT');
      await db.execute('ALTER TABLE Usuario ADD COLUMN password_hash TEXT');

      // Crear tabla Fondo_Pantalla
      await db.execute('''
        CREATE TABLE IF NOT EXISTS Fondo_Pantalla (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          nombre TEXT NOT NULL,
          tipo TEXT NOT NULL CHECK(tipo IN ('imagen', 'color_solido')),
          ruta_archivo TEXT,
          color_hex TEXT,
          es_predeterminado INTEGER NOT NULL DEFAULT 0,
          activo INTEGER NOT NULL DEFAULT 1
        );
      ''');
    }

    if (oldVersion < 3) {
      // Migración de versión 2 a 3:
      // 1. Crear tabla Pais y poblar con países existentes
      await db.execute('''
        CREATE TABLE IF NOT EXISTS Pais (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          nombre TEXT NOT NULL UNIQUE,
          codigo TEXT
        );
      ''');

      await db.execute('''
        INSERT OR IGNORE INTO Pais (nombre)
        SELECT DISTINCT pais FROM Version_Pais;
      ''');

      // 2. Agregar columna pais_id a Version_Pais
      await db.execute('ALTER TABLE Version_Pais ADD COLUMN pais_id INTEGER');

      // 3. Migrar datos: asociar cada fila al país correspondiente
      await db.execute('''
        UPDATE Version_Pais
        SET pais_id = (SELECT id FROM Pais WHERE Pais.nombre = Version_Pais.pais)
        WHERE pais_id IS NULL;
      ''');

      // 4. Reemplazar índice único (pasa de pais TEXT a pais_id INTEGER)
      await db.execute('DROP INDEX IF EXISTS idx_version_pais_unica');
      await db.execute('''
        CREATE UNIQUE INDEX idx_version_pais_unica ON Version_Pais(himno_id, pais_id);
      ''');

      // 5. Eliminar la columna vieja pais (TEXT NOT NULL) que ya no se usa
      //    SQLite 3.35.0+ soporta DROP COLUMN
      await db.execute('DROP INDEX IF EXISTS idx_version_himno');
      try {
        await db.execute('ALTER TABLE Version_Pais DROP COLUMN pais');
      } catch (_) {
        // Si la versión de SQLite no soporta DROP COLUMN, se ignora
        // La columna obsoleta se mantendrá pero no se usará en el código nuevo
      }
      await db.execute('CREATE INDEX IF NOT EXISTS idx_version_himno ON Version_Pais(himno_id)');

      // 6. Recrear vistas afectadas
      await db.execute('DROP VIEW IF EXISTS v_himno_resumen');
      await db.execute('''
        CREATE VIEW IF NOT EXISTS v_himno_resumen AS
        SELECT
          h.id,
          h.titulo_principal,
          h.numero_oficial,
          h.tipo,
          h.activo,
          p.nombre AS pais,
          vp.tonalidad_original
        FROM Himno h
        LEFT JOIN Version_Pais vp ON vp.himno_id = h.id AND vp.activo = 1
        LEFT JOIN Pais p ON p.id = vp.pais_id
        ORDER BY h.numero_oficial;
      ''');

      await db.execute('DROP VIEW IF EXISTS v_himno_estrofas');
      await db.execute('''
        CREATE VIEW IF NOT EXISTS v_himno_estrofas AS
        SELECT
          vp.himno_id,
          vp.id AS version_pais_id,
          COUNT(e.id) AS total_estrofas,
          SUM(CASE WHEN e.tipo = 'Coro' THEN 1 ELSE 0 END) AS total_coros
        FROM Version_Pais vp
        LEFT JOIN Estrofa e ON e.version_pais_id = vp.id
        GROUP BY vp.himno_id, vp.id;
      ''');
    }

    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS Himno_Busqueda (
          himno_id INTEGER PRIMARY KEY,
          titulo_normalizado TEXT NOT NULL DEFAULT '',
          contenido_normalizado TEXT NOT NULL DEFAULT '',
          FOREIGN KEY (himno_id) REFERENCES Himno(id) ON DELETE CASCADE
        );
      ''');
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_busqueda_titulo ON Himno_Busqueda(titulo_normalizado);',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_busqueda_contenido ON Himno_Busqueda(contenido_normalizado);',
      );
    }

    if (oldVersion < 5) {
      // Migración de versión 4 a 5:
      // Agregar columna evento a Himno (para registrar a qué evento pertenece el himno)
      try {
        await db.execute('ALTER TABLE Himno ADD COLUMN evento TEXT');
      } catch (_) {
        // Si la columna ya existe (ej: BD ya modificada directamente), ignorar
      }
    }

    if (oldVersion < 6) {
      // Migración de versión 5 a 6:
      // Eliminar 'video' del CHECK constraint de Fondo_Pantalla.tipo
      // (FondoPantallaTipo.video fue eliminado del enum Dart)
      // SQLite no permite ALTER CHECK, así que se recrea la tabla.
      await db.execute('DELETE FROM Fondo_Pantalla WHERE tipo = \'video\'');
      await db.execute('''
        CREATE TABLE Fondo_Pantalla_v6 (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          nombre TEXT NOT NULL,
          tipo TEXT NOT NULL CHECK(tipo IN ('imagen', 'color_solido')),
          ruta_archivo TEXT,
          color_hex TEXT,
          es_predeterminado INTEGER NOT NULL DEFAULT 0,
          activo INTEGER NOT NULL DEFAULT 1
        );
      ''');
      await db.execute(
        'INSERT INTO Fondo_Pantalla_v6 SELECT * FROM Fondo_Pantalla',
      );
      await db.execute('DROP TABLE Fondo_Pantalla');
      await db.execute('ALTER TABLE Fondo_Pantalla_v6 RENAME TO Fondo_Pantalla');
    }

    if (oldVersion < 7) {
      // Forzar reindexación del contenido de búsqueda para ignorar acordes ChordPro.
      // La tabla Himno_Busqueda se reconstruye automáticamente en el próximo
      // searchHymns() vía _doInitializeSearchIndex().
      await db.execute('DELETE FROM Himno_Busqueda');
    }
  }

  /// Guarda un valor en la tabla Configuracion.
  /// Si la clave ya existe, la actualiza.
  Future<void> setConfig(String key, String value) async {
    final db = await database;
    await db.insert(
      'Configuracion',
      {'clave': key, 'valor': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Lee un valor de la tabla Configuracion.
  /// Retorna `null` si la clave no existe.
  Future<String?> getConfig(String key) async {
    final db = await database;
    final result = await db.query(
      'Configuracion',
      where: 'clave = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (result.isEmpty) return null;
    return result.first['valor'] as String;
  }
}
