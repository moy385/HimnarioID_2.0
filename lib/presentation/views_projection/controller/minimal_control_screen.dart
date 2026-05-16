import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared_widgets/control_sheets.dart';
import '../providers/connection_providers.dart';
import '../providers/live_control_providers.dart';
import '../../views_personal/providers/audio_providers.dart';
import '../../views_personal/providers/hymn_providers.dart';

/// Panel de control minimalista para modo Emisor.
///
/// Se abre al seleccionar un himno en [ConnectedDashboard].
/// Sin scroll de letra, solo controles de navegación y función.
/// Los cambios se envían al provider local y por gRPC al Receptor.
class MinimalControlScreen extends ConsumerWidget {
  final int hymnId;

  const MinimalControlScreen({super.key, required this.hymnId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final isConnected = ref.watch(isConnectedProvider);
    final liveState = ref.watch(liveControlProvider);

    // Cargar el himno si aún no está cargado o es otro himno
    ref.listen(hymnDetailProvider(hymnId), (prev, next) {
      next.whenData((himno) {
        final currentHymn = ref.read(liveControlProvider).hymn;
        if (currentHymn == null || currentHymn.id != hymnId) {
          ref.read(stanzasProvider(himno.primaryVersionPaisId)).whenData(
                (estrofas) {
              ref
                  .read(liveControlProvider.notifier)
                  .loadHymn(himno, estrofas);
            },
              );
        }
      });
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(liveState.hymn?.titulo ?? 'Control de Proyección'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // Indicador de conexión
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            color: colorScheme.primaryContainer,
            child: Row(
              children: [
                Icon(
                  Icons.cast,
                  size: 16,
                  color: colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 8),
                Text(
                  isConnected ? 'Modo Emisor - Conectado' : 'Sin conexión',
                  style: TextStyle(color: colorScheme.onPrimaryContainer),
                ),
                if (liveState.currentSlide != null) ...[
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.onPrimaryContainer
                          .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${liveState.currentSlide!.displayLabel} '
                      '${liveState.currentSlideIndex + 1}',
                      style: textTheme.labelSmall?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          const Spacer(),

          // Botones de navegación grandes
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ControlButton(
                icon: Icons.skip_previous,
                label: 'Anterior',
                onPressed: liveState.hasPrevSlide
                    ? () {
                  ref
                      .read(liveControlProvider.notifier)
                      .prevSlide();
                }
                    : null,
              ),
              const SizedBox(width: 32),
              _ControlButton(
                icon: Icons.skip_next,
                label: 'Siguiente',
                onPressed: liveState.hasNextSlide
                    ? () {
                  ref
                      .read(liveControlProvider.notifier)
                      .nextSlide();
                }
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 48),

          // Botones de función
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              _FunctionButton(
                icon: Icons.brush,
                label: 'Brocha',
                onPressed: () => showBrushSheet(
                  context,
                  ref: ref,
                ),
              ),
              _FunctionButton(
                icon: Icons.music_note,
                label: 'Solfa',
                onPressed: () => showSolfaSheet(
                  context,
                  ref: ref,
                  showChords: true,
                  onShowChordsChanged: (_) {},
                ),
              ),
              _FunctionButton(
                icon: Icons.audiotrack,
                label: 'Nota',
                onPressed: () => showNoteSheet(
                  context,
                  ref: ref,
                  himnoId: hymnId,
                  currentPistaId: null,
                  onPlayPista: (pistaId) =>
                      ref.read(audioRepositoryProvider).play(pistaId),
                  onStop: () => ref.read(audioRepositoryProvider).stop(),
                ),
              ),
              _FunctionButton(
                icon: Icons.search,
                label: 'Lupa',
                onPressed: () async {
                  final result = await showSearchSheet(
                    context,
                    ref: ref,
                    currentHimnoId: hymnId,
                  );
                  if (result != null && result > 0 && result != hymnId) {
                    if (!context.mounted) return;
                    Navigator.pushReplacementNamed(
                      context,
                      '/live-control',
                      arguments: result,
                    );
                  }
                },
              ),
            ],
          ),

          const Spacer(),

          // Botón salir
          Padding(
            padding: const EdgeInsets.all(16),
            child: OutlinedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.exit_to_app),
              label: const Text('Salir'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  const _ControlButton({
    required this.icon,
    required this.label,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDisabled = onPressed == null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          iconSize: 48,
          onPressed: onPressed,
          icon: Icon(icon),
          style: IconButton.styleFrom(
            foregroundColor: isDisabled
                ? colorScheme.onSurface.withValues(alpha: 0.38)
                : colorScheme.onSurface,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: isDisabled
                ? colorScheme.onSurface.withValues(alpha: 0.38)
                : colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _FunctionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  const _FunctionButton({
    required this.icon,
    required this.label,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDisabled = onPressed == null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        IconButton(
          iconSize: 32,
          onPressed: onPressed,
          icon: Icon(icon),
          style: IconButton.styleFrom(
            foregroundColor: isDisabled
                ? colorScheme.onSurface.withValues(alpha: 0.38)
                : colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: isDisabled
                ? colorScheme.onSurface.withValues(alpha: 0.38)
                : colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
