import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/estrofa.dart';
import '../../../domain/entities/himno.dart';
import '../../views_personal/providers/hymn_providers.dart';

/// Vista simplificada para modo Desktop sin Present activo.
///
/// Solo muestra título + estrofa actual con navegación prev/next.
/// Sin FAB, sin audio, sin transposición.
class SimpleProjectionView extends ConsumerStatefulWidget {
  final Himno himno;
  const SimpleProjectionView({super.key, required this.himno});

  @override
  ConsumerState<SimpleProjectionView> createState() =>
      _SimpleProjectionViewState();
}

class _SimpleProjectionViewState extends ConsumerState<SimpleProjectionView> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final versionId = widget.himno.primaryVersionPaisId;

    // ── Sin versiones disponibles ──
    if (versionId < 0) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.himno.titulo)),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.library_music_outlined,
                size: 64,
                color: colorScheme.outline,
              ),
              const SizedBox(height: 16),
              Text(
                'Este himno no tiene versiones disponibles',
                style: textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // ── Cargar estrofas usando ref.watch + AsyncValue.when ──
    final stanzasAsync = ref.watch(stanzasProvider(versionId));

    return stanzasAsync.when(
      loading: () => _buildLoading(context, colorScheme, textTheme),
      error: (error, stack) => _buildError(
        context,
        ref,
        colorScheme,
        textTheme,
        error.toString(),
        versionId,
      ),
      data: (estrofas) {
        if (estrofas.isEmpty) {
          return _buildEmptyStanzas(context, colorScheme, textTheme);
        }
        return _buildContent(
          context,
          colorScheme,
          textTheme,
          estrofas,
        );
      },
    );
  }

  /// Estado de carga: indicador de progreso.
  Widget _buildLoading(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.himno.titulo)),
      body: const Center(child: CircularProgressIndicator()),
    );
  }

  /// Estado de error: muestra el mensaje de error con botón reintentar.
  Widget _buildError(
    BuildContext context,
    WidgetRef ref,
    ColorScheme colorScheme,
    TextTheme textTheme,
    String message,
    int versionId,
  ) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.himno.titulo)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Error al cargar las estrofas',
                style: textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.tonalIcon(
                onPressed: () {
                  ref.invalidate(stanzasProvider(versionId));
                },
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Estado vacío: himno tiene versiones pero sin estrofas.
  Widget _buildEmptyStanzas(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.himno.titulo)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.auto_stories_rounded,
              size: 64,
              color: colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'No hay estrofas disponibles',
              style: textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Contenido normal con navegación entre estrofas.
  Widget _buildContent(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
    List<Estrofa> estrofas,
  ) {
    if (_currentIndex >= estrofas.length) {
      _currentIndex = 0;
    }
    final estrofa = estrofas[_currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.himno.titulo),
        actions: [
          IconButton(
            icon: const Icon(Icons.skip_previous_rounded),
            onPressed: _currentIndex > 0
                ? () => setState(() => _currentIndex--)
                : null,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Center(
              child: Text(
                '${_currentIndex + 1}/${estrofas.length}',
                style: textTheme.titleSmall,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.skip_next_rounded),
            onPressed: _currentIndex < estrofas.length - 1
                ? () => setState(() => _currentIndex++)
                : null,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Chip(
              label: Text(estrofa.tipo.value),
              backgroundColor: colorScheme.secondaryContainer,
            ),
            const SizedBox(height: 16),
            SelectableText(
              estrofa.contenido,
              style: textTheme.bodyLarge?.copyWith(
                fontFamily: 'monospace',
                height: 1.8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
