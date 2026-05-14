import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/datasources/local/catalog_local_datasource.dart';

// ─────────────────────────────────────────────────────────────
// GetAllPaisesUseCase
// ─────────────────────────────────────────────────────────────

/// Caso de uso para obtener la lista de países disponibles,
/// extraída de los valores únicos de [Version_Pais.pais].
class GetAllPaisesUseCase {
  final CatalogLocalDataSource _dataSource;

  GetAllPaisesUseCase(this._dataSource);

  /// Retorna una lista de nombres de países únicos, ordenados alfabéticamente.
  Future<List<String>> execute() async {
    return await _dataSource.getAllPaises();
  }
}

final getAllPaisesUseCaseProvider = Provider<GetAllPaisesUseCase>((ref) {
  final dataSource = CatalogLocalDataSource();
  return GetAllPaisesUseCase(dataSource);
});
