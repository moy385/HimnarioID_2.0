import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/fondo_pantalla.dart';
import '../../../core/enums/fondo_pantalla_tipo.dart';
import '../../views_admin/providers/admin_providers.dart'
    show getAllFondosUseCaseProvider;

/// Provider que retorna solo los fondos de tipo colorSolido activos
/// desde la base de datos, para mostrarlos en el sheet de brocha.
final fondosColorSolidoProvider = FutureProvider<List<FondoPantalla>>((ref) async {
  final useCase = ref.read(getAllFondosUseCaseProvider);
  final all = await useCase.execute();
  return all
      .where((f) => f.tipo == FondoPantallaTipo.colorSolido && f.activo)
      .toList();
});
