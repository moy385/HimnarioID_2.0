import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../views_admin/providers/admin_providers.dart'
    show getAllPaisesUseCaseProvider;

// ─────────────────────────────────────────────────────────────
// Provider local: lista de países
// ─────────────────────────────────────────────────────────────

final _paisListProvider = FutureProvider.autoDispose<List<String>>((ref) {
  return ref.watch(getAllPaisesUseCaseProvider).execute();
});

// ─────────────────────────────────────────────────────────────

/// Tab de administración de países.
///
/// Solo visualización: los países provienen de la tabla Version_Pais
/// (se crean al agregar versiones de himnos). No tiene CRUD directo.
class PaisTab extends ConsumerWidget {
  const PaisTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paisesAsync = ref.watch(_paisListProvider);
    final theme = Theme.of(context);

    return paisesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error: $err')),
      data: (paises) {
        if (paises.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.public_off,
                  size: 48,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 16),
                Text(
                  'No hay países registrados',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Los países se crean al agregar versiones de himnos.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                '${paises.length} país(es) registrado(s)',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: paises.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: theme.colorScheme.secondaryContainer,
                      child: Icon(
                        Icons.flag_outlined,
                        color: theme.colorScheme.onSecondaryContainer,
                      ),
                    ),
                    title: Text(paises[index]),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
