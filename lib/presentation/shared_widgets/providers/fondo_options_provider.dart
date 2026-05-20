import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/fondo_pantalla.dart';
import '../../../core/enums/fondo_pantalla_tipo.dart';
import '../../views_admin/providers/admin_providers.dart'
    show getAllFondosUseCaseProvider;

/// Provider que retorna TODOS los fondos activos (cualquier tipo).
/// Usar este en lugar de [fondosColorSolidoProvider].
final fondosActivosProvider = FutureProvider<List<FondoPantalla>>((ref) async {
  final useCase = ref.read(getAllFondosUseCaseProvider);
  final all = await useCase.execute();
  return all.where((f) => f.activo).toList();
});

/// Provider que retorna solo fondos de tipo colorSolido.
/// @deprecated Usar [fondosActivosProvider] que incluye todos los tipos.
final fondosColorSolidoProvider = FutureProvider<List<FondoPantalla>>((ref) async {
  final all = await ref.watch(fondosActivosProvider.future);
  return all.where((f) => f.tipo == FondoPantallaTipo.colorSolido).toList();
});
