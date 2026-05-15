import 'package:logging/logging.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../core/database/database_helper.dart';
import '../../../core/enums/himno_tipo.dart';
import '../../../core/errors/exceptions.dart' as exc;

import '../../models/categoria_model.dart';
import '../../models/estrofa_model.dart';
import '../../models/himno_model.dart';
import '../../models/version_pais_model.dart';

/// DataSource local para himnos usando SQLite.
/// Encapsula todas las consultas SQL a la base de datos de himnos.
class HymnLocalDataSource {
  static final _log = Logger('HymnLocalDataSource');

  final DatabaseHelper _dbHelper;

  HymnLocalDataSource({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  /// Obtiene la instancia de BD.
  Future<Database> get _db => _dbHelper.database;

  /// Busca himnos por texto (título o número) con filtro opcional por tipo.
  Future<List<HimnoModel>> searchHymns(String query, {HimnoTipo? tipo}) async {
    try {
      final db = await _db;

      final conditions = <String>[];
      final params = <dynamic>[];

      if (query.isNotEmpty) {
        conditions.add(
          '(h.titulo_principal LIKE ? OR CAST(h.numero_oficial AS TEXT) LIKE ?)',
        );
        final searchTerm = '%$query%';
        params.addAll([searchTerm, searchTerm]);
      }

      if (tipo != null) {
        conditions.add('h.tipo = ?');
        params.add(tipo.value);
      }

      conditions.add('h.activo = 1');

      final where = conditions.join(' AND ');

      final maps = await db.query(
        'Himno h',
        columns: [
          'h.id',
          'h.titulo_principal',
          'h.numero_oficial',
          'h.tipo',
          'h.activo',
        ],
        where: where,
        whereArgs: params,
        orderBy: 'h.numero_oficial ASC',
      );

      final himnos = maps.map((map) => HimnoModel.fromMap(map)).toList();

      // Cargar versiones para cada himno (con JOIN a Pais)
      for (final himno in himnos) {
        final versionMaps = await db.rawQuery(
          'SELECT vp.*, p.nombre AS pais_nombre, p.codigo AS pais_codigo '
          'FROM Version_Pais vp '
          'LEFT JOIN Pais p ON p.id = vp.pais_id '
          'WHERE vp.himno_id = ? AND vp.activo = 1',
          [himno.id],
        );
        himno.versiones =
            versionMaps.map((vm) => VersionPaisModel.fromMap(vm)).toList();

        // Cargar categorías para cada himno
        final catMaps = await db.rawQuery(
          'SELECT c.id, c.nombre FROM Himno_Categoria hc '
          'JOIN Categoria c ON c.id = hc.categoria_id '
          'WHERE hc.himno_id = ?',
          [himno.id],
        );
        himno.categorias = catMaps
            .map((cm) => CategoriaModel(
                  id: cm['id'] as int,
                  nombre: cm['nombre'] as String,
                ))
            .toList();
      }

      _log.info('Búsqueda "$query" encontró ${himnos.length} resultados.');
      return himnos;
    } catch (e) {
      _log.severe('Error en searchHymns: $e');
      throw exc.DatabaseException(
        'Error al buscar himnos: $e',
        query: 'searchHymns',
      );
    }
  }

  /// Obtiene un himno completo por su ID incluyendo versiones, estrofas y categorías.
  Future<HimnoModel> getHymnById(int id) async {
    try {
      final db = await _db;

      final maps = await db.query(
        'Himno',
        where: 'id = ? AND activo = 1',
        whereArgs: [id],
      );

      if (maps.isEmpty) {
        throw const exc.NotFoundException(
          'Himno no encontrado',
          entityType: 'Himno',
        );
      }

      final himno = HimnoModel.fromMap(maps.first);

      // Cargar versiones de país (con JOIN a Pais)
      final versionMaps = await db.rawQuery(
        'SELECT vp.*, p.nombre AS pais_nombre, p.codigo AS pais_codigo '
        'FROM Version_Pais vp '
        'LEFT JOIN Pais p ON p.id = vp.pais_id '
        'WHERE vp.himno_id = ? AND vp.activo = 1',
        [id],
      );
      final versiones =
          versionMaps.map((vm) => VersionPaisModel.fromMap(vm)).toList();

      // Cargar estrofas para cada versión
      for (final version in versiones) {
        final estrofaMaps = await db.query(
          'Estrofa',
          where: 'version_pais_id = ?',
          whereArgs: [version.id],
          orderBy: 'orden ASC',
        );
        version.estrofas =
            estrofaMaps.map((em) => EstrofaModel.fromMap(em)).toList();
      }

      // Cargar categorías
      final catMaps = await db.rawQuery(
        '''
        SELECT c.id, c.nombre
        FROM Categoria c
        INNER JOIN Himno_Categoria hc ON hc.categoria_id = c.id
        WHERE hc.himno_id = ?
      ''',
        [id],
      );
      himno.categorias =
          catMaps.map((cm) => CategoriaModel.fromMap(cm)).toList();

      himno.versiones = versiones;

      _log.info('Himno #$id cargado con ${versiones.length} versión(es).');
      return himno;
    } on exc.NotFoundException {
      rethrow;
    } catch (e) {
      _log.severe('Error en getHymnById: $e');
      throw exc.DatabaseException(
        'Error al obtener himno: $e',
        query: 'getHymnById',
      );
    }
  }

  /// Obtiene las estrofas de una versión de país específica.
  Future<List<EstrofaModel>> getStanzas(int versionPaisId) async {
    try {
      final db = await _db;

      final maps = await db.query(
        'Estrofa',
        where: 'version_pais_id = ?',
        whereArgs: [versionPaisId],
        orderBy: 'orden ASC',
      );

      return maps.map((m) => EstrofaModel.fromMap(m)).toList();
    } catch (e) {
      _log.severe('Error en getStanzas: $e');
      throw exc.DatabaseException(
        'Error al obtener estrofas: $e',
        query: 'getStanzas',
      );
    }
  }

  /// Obtiene todas las categorías disponibles.
  Future<List<CategoriaModel>> getCategories() async {
    try {
      final db = await _db;

      final maps = await db.query(
        'Categoria',
        orderBy: 'nombre ASC',
      );

      return maps.map((m) => CategoriaModel.fromMap(m)).toList();
    } catch (e) {
      _log.severe('Error en getCategories: $e');
      throw exc.DatabaseException(
        'Error al obtener categorías: $e',
        query: 'getCategories',
      );
    }
  }

  /// Obtiene los himnos pertenecientes a una categoría.
  Future<List<HimnoModel>> getHymnsByCategory(int categoriaId) async {
    try {
      final db = await _db;

      final maps = await db.rawQuery(
        '''
        SELECT h.id, h.titulo_principal, h.numero_oficial, h.tipo, h.activo
        FROM Himno h
        INNER JOIN Himno_Categoria hc ON hc.himno_id = h.id
        WHERE hc.categoria_id = ? AND h.activo = 1
        ORDER BY h.numero_oficial ASC
      ''',
        [categoriaId],
      );

      final himnos = maps.map((m) => HimnoModel.fromMap(m)).toList();

      for (final himno in himnos) {
        final versionMaps = await db.rawQuery(
          'SELECT vp.*, p.nombre AS pais_nombre, p.codigo AS pais_codigo '
          'FROM Version_Pais vp '
          'LEFT JOIN Pais p ON p.id = vp.pais_id '
          'WHERE vp.himno_id = ? AND vp.activo = 1',
          [himno.id],
        );
        himno.versiones =
            versionMaps.map((vm) => VersionPaisModel.fromMap(vm)).toList();
      }

      return himnos;
    } catch (e) {
      _log.severe('Error en getHymnsByCategory: $e');
      throw exc.DatabaseException(
        'Error al obtener himnos por categoría: $e',
        query: 'getHymnsByCategory',
      );
    }
  }

  /// Inserta un himno completo con sus versiones, estrofas y categorías
  /// en una sola transacción SQLite.
  ///
  /// [himnoData] mapa con columnas de la tabla Himno (sin id).
  /// [versiones] lista de mapas con datos de Version_Pais (sin himno_id).
  /// [estrofas] lista de mapas con datos de Estrofa. Cada estrofa debe incluir
  ///   una clave `version_idx` (int) que indica el índice (0-based) dentro de
  ///   [versiones] a la que pertenece.
  /// [categoriaIds] IDs de categorías a asociar.
  ///
  /// Retorna el ID del himno recién creado.
  Future<int> insertHymnCompleto(
    Map<String, dynamic> himnoData,
    List<Map<String, dynamic>> versiones,
    List<Map<String, dynamic>> estrofas,
    List<int> categoriaIds,
  ) async {
    try {
      final db = await _db;

      return await db.transaction((txn) async {
        // 1. Insertar el himno
        final himnoId = await txn.insert('Himno', himnoData);

        // 2. Insertar versiones de país y mantener el mapeo índice → id
        final versionIdByIndex = <int, int>{};
        for (int i = 0; i < versiones.length; i++) {
          final v = Map<String, dynamic>.from(versiones[i])
            ..['himno_id'] = himnoId;
          v.putIfAbsent('activo', () => 1);
          final versionId = await txn.insert('Version_Pais', v);
          versionIdByIndex[i] = versionId;
        }

        // 3. Insertar estrofas (cada estrofa tiene `version_idx`)
        for (final e in estrofas) {
          final estrofa = Map<String, dynamic>.from(e);
          final versionIdx = estrofa.remove('version_idx') as int;
          estrofa['version_pais_id'] = versionIdByIndex[versionIdx]!;
          await txn.insert('Estrofa', estrofa);
        }

        // 4. Asociar categorías
        for (final catId in categoriaIds) {
          await txn.insert('Himno_Categoria', {
            'himno_id': himnoId,
            'categoria_id': catId,
          });
        }

        _log.info(
          'Himno #$himnoId creado con ${versiones.length} versión(es), '
          '${estrofas.length} estrofa(s) y ${categoriaIds.length} categoría(s).',
        );

        return himnoId;
      });
    } catch (e) {
      _log.severe('Error en insertHymnCompleto: $e');
      throw exc.DatabaseException(
        'Error al insertar himno completo: $e',
        query: 'insertHymnCompleto',
      );
    }
  }

  /// Actualiza un himno completo con sus versiones, estrofas y categorías
  /// en una sola transacción SQLite.
  ///
  /// Elimina todos los registros hijos existentes (versiones, estrofas,
  /// categorías) y los reinserta con los nuevos datos.
  ///
  /// [himnoId] ID del himno a actualizar.
  /// [himnoData] mapa con las columnas a modificar de la tabla Himno (sin id).
  /// [versiones], [estrofas], [categoriaIds] ídem que en [insertHymnCompleto].
  Future<void> updateHymnCompleto(
    int himnoId,
    Map<String, dynamic> himnoData,
    List<Map<String, dynamic>> versiones,
    List<Map<String, dynamic>> estrofas,
    List<int> categoriaIds,
  ) async {
    try {
      final db = await _db;

      await db.transaction((txn) async {
        // 1. Actualizar el himno
        await txn.update(
          'Himno',
          himnoData,
          where: 'id = ?',
          whereArgs: [himnoId],
        );

        // 2. Eliminar versiones existentes (cascadea estrofas automáticamente)
        await txn.delete(
          'Version_Pais',
          where: 'himno_id = ?',
          whereArgs: [himnoId],
        );

        // 3. Eliminar asociaciones de categorías existentes
        await txn.delete(
          'Himno_Categoria',
          where: 'himno_id = ?',
          whereArgs: [himnoId],
        );

        // 4. Re-insertar versiones de país
        final versionIdByIndex = <int, int>{};
        for (int i = 0; i < versiones.length; i++) {
          final v = Map<String, dynamic>.from(versiones[i])
            ..['himno_id'] = himnoId;
          v.putIfAbsent('activo', () => 1);
          final versionId = await txn.insert('Version_Pais', v);
          versionIdByIndex[i] = versionId;
        }

        // 5. Re-insertar estrofas
        for (final e in estrofas) {
          final estrofa = Map<String, dynamic>.from(e);
          final versionIdx = estrofa.remove('version_idx') as int;
          estrofa['version_pais_id'] = versionIdByIndex[versionIdx]!;
          await txn.insert('Estrofa', estrofa);
        }

        // 6. Re-insertar categorías
        for (final catId in categoriaIds) {
          await txn.insert('Himno_Categoria', {
            'himno_id': himnoId,
            'categoria_id': catId,
          });
        }

        _log.info(
          'Himno #$himnoId actualizado con ${versiones.length} versión(es), '
          '${estrofas.length} estrofa(s) y ${categoriaIds.length} categoría(s).',
        );
      });
    } catch (e) {
      _log.severe('Error en updateHymnCompleto: $e');
      throw exc.DatabaseException(
        'Error al actualizar himno completo: $e',
        query: 'updateHymnCompleto',
      );
    }
  }

  /// Verifica si un himno tiene referencias en otras tablas
  /// (arreglos musicales, pistas de audio, historial de reproducción).
  Future<bool> hymnHasReferences(int himnoId) async {
    try {
      final db = await _db;

      final result = await db.rawQuery('''
        SELECT
          (SELECT COUNT(*) FROM Arreglo_Musical am
           INNER JOIN Version_Pais vp ON vp.id = am.version_pais_id
           WHERE vp.himno_id = ?) +
          (SELECT COUNT(*) FROM Pista_Audio WHERE himno_id = ?) +
          (SELECT COUNT(*) FROM Historial_Reproduccion WHERE himno_id = ?)
        AS total
      ''', [himnoId, himnoId, himnoId],);

      final total = result.first['total'] as int;
      return total > 0;
    } catch (e) {
      _log.severe('Error en hymnHasReferences: $e');
      throw exc.DatabaseException(
        'Error al verificar referencias del himno: $e',
        query: 'hymnHasReferences',
      );
    }
  }

  /// Marca un himno como inactivo (soft-delete).
  Future<void> deleteHymn(int id) async {
    try {
      final db = await _db;
      await db.update(
        'Himno',
        {'activo': 0},
        where: 'id = ?',
        whereArgs: [id],
      );
      _log.info('Himno #$id marcado como inactivo (soft-delete).');
    } catch (e) {
      _log.severe('Error en deleteHymn: $e');
      throw exc.DatabaseException(
        'Error al eliminar himno: $e',
        query: 'deleteHymn',
      );
    }
  }

  /// Crea una nueva categoría y retorna el modelo con el ID asignado.
  Future<CategoriaModel> createCategoria(String nombre) async {
    try {
      final db = await _db;
      final id = await db.insert('Categoria', {'nombre': nombre});
      _log.info('Categoría "$nombre" creada con ID $id.');
      return CategoriaModel(id: id, nombre: nombre);
    } catch (e) {
      _log.severe('Error en createCategoria: $e');
      throw exc.DatabaseException(
        'Error al crear categoría: $e',
        query: 'createCategoria',
      );
    }
  }

  /// Elimina una categoría por su ID.
  Future<void> deleteCategoriaById(int id) async {
    try {
      final db = await _db;
      await db.delete('Categoria', where: 'id = ?', whereArgs: [id]);
      _log.info('Categoría #$id eliminada.');
    } catch (e) {
      _log.severe('Error en deleteCategoria: $e');
      throw exc.DatabaseException(
        'Error al eliminar categoría: $e',
        query: 'deleteCategoria',
      );
    }
  }

  /// Crea un arreglo musical personalizado (fork) con sus estrofas.
  /// Retorna el ID del nuevo arreglo.
  Future<int> createArrangement({
    required int versionPaisId,
    required int usuarioId,
    required String nombreArreglo,
    required String tonalidadBase,
    required List<({String tipo, int orden, String contenido})> estrofas,
  }) async {
    try {
      final db = await _db;

      final arrangementId = await db.insert('Arreglo_Musical', {
        'version_pais_id': versionPaisId,
        'usuario_id': usuarioId,
        'nombre_arreglo': nombreArreglo,
        'tonalidad_base': tonalidadBase,
        'version': 1,
      });

      for (final estrofa in estrofas) {
        await db.insert('Estrofa_Arreglo', {
          'arreglo_musical_id': arrangementId,
          'tipo': estrofa.tipo,
          'orden': estrofa.orden,
          'contenido': estrofa.contenido,
        });
      }

      _log.info(
        'Arreglo "$nombreArreglo" creado con ID $arrangementId '
        '(${estrofas.length} estrofas).',
      );
      return arrangementId;
    } catch (e) {
      _log.severe('Error en createArrangement: $e');
      throw exc.DatabaseException(
        'Error al crear arreglo: $e',
        query: 'createArrangement',
      );
    }
  }
}
