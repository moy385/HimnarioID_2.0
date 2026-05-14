import 'package:logging/logging.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../core/database/database_helper.dart';
import '../../../core/errors/exceptions.dart' as exc;
import '../../models/categoria_model.dart';
import '../../models/pista_audio_model.dart';
import '../../models/fondo_pantalla_model.dart';

/// DataSource local para operaciones CRUD sobre tablas de catálogo
/// (Categoria, Pista_Audio, Fondo_Pantalla) y consulta de países
/// desde Version_Pais.
class CatalogLocalDataSource {
  static final _log = Logger('CatalogLocalDataSource');

  final DatabaseHelper _dbHelper;

  CatalogLocalDataSource({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  /// Obtiene la instancia de BD.
  Future<Database> get _db => _dbHelper.database;

  // ─── CATEGORÍAS ─────────────────────────────────────────────

  /// Obtiene todas las categorías ordenadas alfabéticamente.
  Future<List<CategoriaModel>> getAllCategorias() async {
    try {
      final db = await _db;
      final result = await db.query('Categoria', orderBy: 'nombre ASC');
      return result.map((m) => CategoriaModel.fromMap(m)).toList();
    } catch (e) {
      _log.severe('Error en getAllCategorias: $e');
      throw exc.DatabaseException(
        'Error al obtener categorías: $e',
        query: 'getAllCategorias',
      );
    }
  }

  /// Inserta una nueva categoría con el [nombre] dado.
  /// Retorna el ID autogenerado.
  Future<int> insertCategoria(String nombre) async {
    try {
      final db = await _db;
      final id = await db.insert('Categoria', {'nombre': nombre});
      _log.info('Categoría "$nombre" creada con ID: $id');
      return id;
    } catch (e) {
      _log.severe('Error en insertCategoria: $e');
      throw exc.DatabaseException(
        'Error al insertar categoría: $e',
        query: 'insertCategoria',
      );
    }
  }

  /// Elimina una categoría por su [id].
  /// Las relaciones en Himno_Categoria se eliminan en cascada por la FK.
  Future<void> deleteCategoria(int id) async {
    try {
      final db = await _db;
      final rows = await db.delete(
        'Categoria',
        where: 'id = ?',
        whereArgs: [id],
      );
      if (rows > 0) {
        _log.info('Categoría #$id eliminada.');
      } else {
        _log.warning('Categoría #$id no encontrada para eliminar.');
      }
    } catch (e) {
      _log.severe('Error en deleteCategoria: $e');
      throw exc.DatabaseException(
        'Error al eliminar categoría: $e',
        query: 'deleteCategoria',
      );
    }
  }

  // ─── PAÍSES (desde Version_Pais) ────────────────────────────

  /// Obtiene la lista de países únicos registrados en la tabla
  /// Version_Pais, ordenados alfabéticamente.
  Future<List<String>> getAllPaises() async {
    try {
      final db = await _db;
      final result = await db.rawQuery(
        'SELECT DISTINCT pais FROM Version_Pais ORDER BY pais ASC',
      );
      return result.map((m) => m['pais'] as String).toList();
    } catch (e) {
      _log.severe('Error en getAllPaises: $e');
      throw exc.DatabaseException(
        'Error al obtener países: $e',
        query: 'getAllPaises',
      );
    }
  }

  // ─── PISTAS DE AUDIO ──────────────────────────────────────

  /// Obtiene todas las pistas de audio asociadas a un himno.
  Future<List<PistaAudioModel>> getPistasByHimno(int himnoId) async {
    try {
      final db = await _db;
      final result = await db.query(
        'Pista_Audio',
        where: 'himno_id = ?',
        whereArgs: [himnoId],
        orderBy: 'id ASC',
      );
      return result.map((m) => PistaAudioModel.fromMap(m)).toList();
    } catch (e) {
      _log.severe('Error en getPistasByHimno: $e');
      throw exc.DatabaseException(
        'Error al obtener pistas del himno: $e',
        query: 'getPistasByHimno',
      );
    }
  }

  /// Inserta una nueva pista de audio.
  /// Retorna el ID autogenerado.
  Future<int> insertPista(PistaAudioModel pista) async {
    try {
      final db = await _db;
      final id = await db.insert('Pista_Audio', {
        'himno_id': pista.himnoId,
        'ruta_archivo': pista.rutaArchivo,
        'descripcion': pista.descripcion,
        'duracion_segundos': pista.duracionSegundos,
        'formato': pista.formato,
        'origen': pista.origen,
      });
      _log.info('Pista #$id insertada para himno #${pista.himnoId}.');
      return id;
    } catch (e) {
      _log.severe('Error en insertPista: $e');
      throw exc.DatabaseException(
        'Error al insertar pista: $e',
        query: 'insertPista',
      );
    }
  }

  /// Elimina una pista de audio por su [id].
  Future<void> deletePista(int id) async {
    try {
      final db = await _db;
      final rows = await db.delete(
        'Pista_Audio',
        where: 'id = ?',
        whereArgs: [id],
      );
      if (rows > 0) {
        _log.info('Pista #$id eliminada.');
      } else {
        _log.warning('Pista #$id no encontrada para eliminar.');
      }
    } catch (e) {
      _log.severe('Error en deletePista: $e');
      throw exc.DatabaseException(
        'Error al eliminar pista: $e',
        query: 'deletePista',
      );
    }
  }

  // ─── FONDOS DE PANTALLA ─────────────────────────────────────

  /// Obtiene todos los fondos de pantalla ordenados por nombre.
  Future<List<FondoPantallaModel>> getAllFondos() async {
    try {
      final db = await _db;
      final result = await db.query('Fondo_Pantalla', orderBy: 'nombre ASC');
      return result.map((m) => FondoPantallaModel.fromMap(m)).toList();
    } catch (e) {
      _log.severe('Error en getAllFondos: $e');
      throw exc.DatabaseException(
        'Error al obtener fondos de pantalla: $e',
        query: 'getAllFondos',
      );
    }
  }

  /// Obtiene un fondo de pantalla por su [id].
  /// Retorna `null` si no existe.
  Future<FondoPantallaModel?> getFondoById(int id) async {
    try {
      final db = await _db;
      final result = await db.query(
        'Fondo_Pantalla',
        where: 'id = ?',
        whereArgs: [id],
      );
      if (result.isEmpty) return null;
      return FondoPantallaModel.fromMap(result.first);
    } catch (e) {
      _log.severe('Error en getFondoById: $e');
      throw exc.DatabaseException(
        'Error al obtener fondo por ID: $e',
        query: 'getFondoById',
      );
    }
  }

  /// Obtiene el fondo de pantalla predeterminado (activo).
  /// Retorna `null` si no hay ninguno configurado.
  Future<FondoPantallaModel?> getDefaultFondo() async {
    try {
      final db = await _db;
      final result = await db.query(
        'Fondo_Pantalla',
        where: 'es_predeterminado = 1 AND activo = 1',
        limit: 1,
      );
      if (result.isEmpty) return null;
      return FondoPantallaModel.fromMap(result.first);
    } catch (e) {
      _log.severe('Error en getDefaultFondo: $e');
      throw exc.DatabaseException(
        'Error al obtener fondo predeterminado: $e',
        query: 'getDefaultFondo',
      );
    }
  }

  /// Inserta un nuevo fondo de pantalla.
  /// Retorna el ID autogenerado.
  Future<int> insertFondo(FondoPantallaModel fondo) async {
    try {
      final db = await _db;
      final id = await db.insert('Fondo_Pantalla', {
        'nombre': fondo.nombre,
        'tipo': fondo.tipo,
        'ruta_archivo': fondo.ruta_archivo,
        'color_hex': fondo.color_hex,
        'es_predeterminado': fondo.es_predeterminado,
        'activo': fondo.activo,
      });
      _log.info('Fondo #$id creado: "${fondo.nombre}".');
      return id;
    } catch (e) {
      _log.severe('Error en insertFondo: $e');
      throw exc.DatabaseException(
        'Error al insertar fondo: $e',
        query: 'insertFondo',
      );
    }
  }

  /// Actualiza los datos de un fondo de pantalla existente.
  Future<void> updateFondo(FondoPantallaModel fondo) async {
    try {
      final db = await _db;
      final rows = await db.update(
        'Fondo_Pantalla',
        {
          'nombre': fondo.nombre,
          'tipo': fondo.tipo,
          'ruta_archivo': fondo.ruta_archivo,
          'color_hex': fondo.color_hex,
          'es_predeterminado': fondo.es_predeterminado,
          'activo': fondo.activo,
        },
        where: 'id = ?',
        whereArgs: [fondo.id],
      );
      if (rows > 0) {
        _log.info('Fondo #${fondo.id} actualizado.');
      } else {
        _log.warning('Fondo #${fondo.id} no encontrado para actualizar.');
      }
    } catch (e) {
      _log.severe('Error en updateFondo: $e');
      throw exc.DatabaseException(
        'Error al actualizar fondo: $e',
        query: 'updateFondo',
      );
    }
  }

  /// Elimina un fondo de pantalla por su [id].
  Future<void> deleteFondo(int id) async {
    try {
      final db = await _db;
      final rows = await db.delete(
        'Fondo_Pantalla',
        where: 'id = ?',
        whereArgs: [id],
      );
      if (rows > 0) {
        _log.info('Fondo #$id eliminado.');
      } else {
        _log.warning('Fondo #$id no encontrado para eliminar.');
      }
    } catch (e) {
      _log.severe('Error en deleteFondo: $e');
      throw exc.DatabaseException(
        'Error al eliminar fondo: $e',
        query: 'deleteFondo',
      );
    }
  }
}
