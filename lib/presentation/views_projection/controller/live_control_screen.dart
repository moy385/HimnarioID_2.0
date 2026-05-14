import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/window_manager/window_providers.dart';
import '../../../domain/repositories/control_repository.dart';
import '../providers/connection_providers.dart';
import '../providers/live_control_providers.dart';
import '../providers/presentation_providers.dart';
import '../providers/projection_providers.dart';

/// Pantalla de Control en Vivo (Live Control).
/// Botonera táctica diseñada para operar sin mirar la pantalla.
/// Totalmente conectada a los providers de Riverpod.
/// Cada botón envía comandos vía [ControlRepository] además de actualizar
/// el estado local.
class LiveControlScreen extends ConsumerWidget {
  const LiveControlScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final liveState = ref.watch(liveControlProvider);
    final isConnected = ref.watch(isConnectedProvider);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(liveState.hymn?.titulo ?? 'Control en Vivo'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _handleClose(context, ref),
        ),
        actions: [
          // Indicador de conexión
          Icon(
            isConnected ? Icons.cast_connected_rounded : Icons.cast_rounded,
            color: isConnected ? colorScheme.primary : colorScheme.error,
            size: 20,
          ),
          const SizedBox(width: 8),
          // Indicador de estrofa actual
          if (liveState.currentStanza != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${liveState.currentStanza!.tipo} ${liveState.currentIndex + 1}',
                style: textTheme.labelMedium?.copyWith(
                  color: colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Panel de vista previa y configuración
          _buildPreviewPanel(context, ref, liveState),

          // Botonera principal
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Botón GIGANTE de Siguiente (40% de la pantalla)
                  Expanded(
                    flex: 4,
                    child: _buildGiantButton(
                      context,
                      icon: Icons.arrow_forward_rounded,
                      label: 'SIGUIENTE',
                      onTap: () {
                        _sendCommand(
                          ref,
                          () => ref
                              .read(liveControlProvider.notifier)
                              .nextStanza(),
                          (repo) => repo.sendNextStanza(),
                        );
                      },
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Fila de botones: Anterior + Accesos rápidos
                  Expanded(
                    flex: 2,
                    child: Row(
                      children: [
                        // Botón Anterior
                        Expanded(
                          child: _buildLargeButton(
                            context,
                            icon: Icons.arrow_back_rounded,
                            label: 'Anterior',
                            onTap: () {
                              _sendCommand(
                                ref,
                                () => ref
                                    .read(liveControlProvider.notifier)
                                    .prevStanza(),
                                (repo) => repo.sendPrevStanza(),
                              );
                            },
                            backgroundColor:
                                colorScheme.surfaceContainerHighest,
                            foregroundColor: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Botones de acceso rápido
                        Expanded(
                          flex: 3,
                          child: Column(
                            children: [
                              Expanded(
                                child: _buildQuickButton(
                                  context,
                                  label: 'Ir al Coro',
                                  onTap: () {
                                    _sendCommand(
                                      ref,
                                      () => ref
                                          .read(liveControlProvider.notifier)
                                          .goToChorus(),
                                      (repo) => repo.sendGoToStanza(
                                        _findChorusIndex(ref),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 8),
                              Expanded(
                                child: _buildQuickButton(
                                  context,
                                  label: 'Ir al Inicio',
                                  onTap: () {
                                    _sendCommand(
                                      ref,
                                      () => ref
                                          .read(liveControlProvider.notifier)
                                          .goToStart(),
                                      (repo) => repo.sendGoToStanza(0),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 8),
                              Expanded(
                                child: _buildQuickButton(
                                  context,
                                  label: liveState.isBlackout
                                      ? 'Encender'
                                      : 'Apagar',
                                  onTap: () {
                                    _sendCommand(
                                      ref,
                                      () => ref
                                          .read(liveControlProvider.notifier)
                                          .toggleBlackout(),
                                      (repo) => repo.sendBlackout(
                                        !liveState.isBlackout,
                                      ),
                                    );
                                  },
                                  isDestructive: !liveState.isBlackout,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Maneja el cierre de la pantalla de control.
  ///
  /// Si el modo presentación está activo ([isPresentingProvider] es `true`),
  /// detiene la presentación (cierra la ventana de proyección y resetea el
  /// estado). En caso contrario, simplemente retrocede en la navegación.
  void _handleClose(BuildContext context, WidgetRef ref) {
    final isPresenting = ref.read(isPresentingProvider);
    if (isPresenting) {
      ref.read(windowServiceProvider).closeProjectionWindow();
      ref.read(isPresentingProvider.notifier).state = false;
    } else {
      Navigator.pop(context);
    }
  }

  /// Envía un comando tanto al estado local como al repositorio remoto.
  void _sendCommand(
    WidgetRef ref,
    VoidCallback localAction,
    Future<bool> Function(ControlRepository repo) remoteAction,
  ) {
    // Actualizar estado local
    localAction();

    // Enviar al repositorio remoto si hay conexión
    final isConnected = ref.read(isConnectedProvider);
    if (isConnected) {
      final repo = ref.read(controlRepositoryProvider);
      remoteAction(repo).then((success) {
        if (!success) {
          // Fallback: el estado local ya se actualizó
        }
      });
    }
  }

  /// Encuentra el índice del primer coro en la lista de estrofas.
  int _findChorusIndex(WidgetRef ref) {
    final estrofas = ref.read(estrofasProvider);
    final chorusIndex = estrofas.indexWhere((e) => e.isChorus);
    return chorusIndex >= 0 ? chorusIndex : 0;
  }

  Widget _buildPreviewPanel(
    BuildContext context,
    WidgetRef ref,
    LiveControlState liveState,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Vista Previa',
            style: textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              // Estrofa actual
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Actual',
                        style: textTheme.labelSmall?.copyWith(
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        liveState.currentStanza?.tipo.value ?? '—',
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (liveState.currentStanza != null)
                        Text(
                          liveState.currentStanza!.contenido.split('\n').first,
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onPrimaryContainer,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Siguiente estrofa
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Siguiente',
                        style: textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        liveState.nextStanza?.tipo.value ?? 'Fin',
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (liveState.nextStanza != null)
                        Text(
                          liveState.nextStanza!.contenido.split('\n').first,
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ),
              // Botón de configuración
              const SizedBox(width: 12),
              IconButton(
                onPressed: () => _showConfigSheet(context, ref),
                icon: const Icon(Icons.tune_rounded),
                style: IconButton.styleFrom(
                  backgroundColor: colorScheme.surfaceContainerHighest,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showConfigSheet(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (modalContext) {
        // Usar un Consumer para que el sheet se actualice en tiempo real
        return Consumer(
          builder: (sheetContext, ref, _) {
            final currentConfig = ref.watch(projectionConfigProvider);

            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Configuración de Presentación',
                    style: Theme.of(sheetContext).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 24),

                  // Selector de fondo
                  Text(
                    'Fondo',
                    style: Theme.of(sheetContext).textTheme.labelMedium,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: ProjectionBackground.values.map((bg) {
                      return ChoiceChip(
                        label: Text(_backgroundLabel(bg)),
                        selected: currentConfig.background == bg,
                        onSelected: (_) {
                          ref
                              .read(projectionConfigProvider.notifier)
                              .setBackground(bg);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Selector de tamaño de fuente
                  Text(
                    'Tamaño de Fuente',
                    style: Theme.of(sheetContext).textTheme.labelMedium,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: ProjectionFontSize.values.map((fs) {
                      return ChoiceChip(
                        label: Text(_fontSizeLabel(fs)),
                        selected: currentConfig.fontSize == fs,
                        onSelected: (_) {
                          ref
                              .read(projectionConfigProvider.notifier)
                              .setFontSize(fs);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Selector de velocidad de transición
                  Text(
                    'Velocidad de Transición',
                    style: Theme.of(sheetContext).textTheme.labelMedium,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text('Lenta'),
                      Expanded(
                        child: Slider(
                          value: currentConfig.transitionSpeed,
                          onChanged: (value) {
                            ref
                                .read(projectionConfigProvider.notifier)
                                .setTransitionSpeed(value);
                          },
                        ),
                      ),
                      const Text('Rápida'),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _backgroundLabel(ProjectionBackground bg) {
    switch (bg) {
      case ProjectionBackground.black:
        return 'Negro';
      case ProjectionBackground.color:
        return 'Color';
      case ProjectionBackground.image:
        return 'Imagen';
    }
  }

  String _fontSizeLabel(ProjectionFontSize fs) {
    switch (fs) {
      case ProjectionFontSize.small:
        return 'Pequeño';
      case ProjectionFontSize.medium:
        return 'Mediano';
      case ProjectionFontSize.large:
        return 'Grande';
      case ProjectionFontSize.extraLarge:
        return 'Extra Grande';
    }
  }

  Widget _buildGiantButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color backgroundColor,
    required Color foregroundColor,
  }) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                backgroundColor,
                backgroundColor.withValues(alpha: 0.8),
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 64,
                color: foregroundColor,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: foregroundColor,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLargeButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color backgroundColor,
    required Color foregroundColor,
  }) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: foregroundColor, size: 28),
            const SizedBox(width: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: foregroundColor,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickButton(
    BuildContext context, {
    required String label,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: isDestructive
          ? colorScheme.errorContainer
          : colorScheme.secondaryContainer,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Center(
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: isDestructive
                      ? colorScheme.onErrorContainer
                      : colorScheme.onSecondaryContainer,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ),
    );
  }
}
