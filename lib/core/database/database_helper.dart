import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

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

  /// Obtiene la instancia de la base de datos, inicializándola si es necesario.
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    // Inicializar FFI para desktop (Linux/Windows/Mac)
    sqfliteFfiInit();

    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, 'himnario_id.db');

    // Usar databaseFactoryFfi como factory para crear la BD
    final factory = databaseFactoryFfi;
    return await factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 2,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      ),
    );
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
        activo INTEGER NOT NULL DEFAULT 1,
        fecha_creacion TEXT NOT NULL DEFAULT (datetime('now'))
      );
    ''');

    await db.execute('''
      CREATE TABLE Version_Pais (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        himno_id INTEGER NOT NULL,
        pais TEXT NOT NULL,
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
        tipo TEXT NOT NULL CHECK(tipo IN ('imagen', 'video', 'color_solido')),
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

    // Crear índices
    await db.execute('CREATE INDEX idx_himno_numero ON Himno(numero_oficial);');
    await db
        .execute('CREATE INDEX idx_version_himno ON Version_Pais(himno_id);');
    await db.execute(
      'CREATE UNIQUE INDEX idx_version_pais_unica ON Version_Pais(himno_id, pais);',
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
        vp.pais,
        vp.tonalidad_original
      FROM Himno h
      LEFT JOIN Version_Pais vp ON vp.himno_id = h.id AND vp.activo = 1
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
          tipo TEXT NOT NULL CHECK(tipo IN ('imagen', 'video', 'color_solido')),
          ruta_archivo TEXT,
          color_hex TEXT,
          es_predeterminado INTEGER NOT NULL DEFAULT 0,
          activo INTEGER NOT NULL DEFAULT 1
        );
      ''');
    }
  }
}
