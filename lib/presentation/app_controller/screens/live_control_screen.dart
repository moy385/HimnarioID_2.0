import 'package:flutter/material.dart';

/// Pantalla de Control en Vivo (Live Control)
/// Botonera táctica diseñada para operar sin mirar la pantalla
class LiveControlScreen extends StatefulWidget {
  const LiveControlScreen({super.key});

  @override
  State<LiveControlScreen> createState() => _LiveControlScreenState();
}

class _LiveControlScreenState extends State<LiveControlScreen> {
  int _currentStanzaIndex = 0;
  bool _isStanzaVisible = true;

  // Estructura de estrofas del himno
  final List<String> _estrofas = [
    'Estrofa 1',
    'Coro',
    'Estrofa 2',
    'Coro',
    'Estrofa 3',
    'Puente',
    'Estrofa Final',
  ];

  void _nextStanza() {
    if (_currentStanzaIndex < _estrofas.length - 1) {
      setState(() {
        _currentStanzaIndex++;
        _isStanzaVisible = true;
      });
      _showFeedback(context, 'Siguiente: ${_estrofas[_currentStanzaIndex]}');
    }
  }

  void _prevStanza() {
    if (_currentStanzaIndex > 0) {
      setState(() {
        _currentStanzaIndex--;
        _isStanzaVisible = true;
      });
      _showFeedback(context, 'Anterior: ${_estrofas[_currentStanzaIndex]}');
    }
  }

  void _goToChorus() {
    // Buscar el coro más cercano (asumiendo que está en posición 1, 3, 5...)
    final chorusIndex = _estrofas.indexWhere(
      (e) => e.toLowerCase().contains('coro'),
    );
    if (chorusIndex != -1 && chorusIndex != _currentStanzaIndex) {
      setState(() {
        _currentStanzaIndex = chorusIndex;
        _isStanzaVisible = true;
      });
      _showFeedback(context, 'Ir al Coro');
    }
  }

  void _goToStart() {
    setState(() {
      _currentStanzaIndex = 0;
      _isStanzaVisible = true;
    });
    _showFeedback(context, 'Ir al Inicio');
  }

  void _blackout() {
    setState(() {
      _isStanzaVisible = false;
    });
    _showFeedback(context, 'Pantalla apagada');
  }

  void _showFeedback(BuildContext context, String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(milliseconds: 500),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Control en Vivo'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Indicador de estrofa actual
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _estrofas[_currentStanzaIndex],
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
          _buildPreviewPanel(context),

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
                      onTap: _nextStanza,
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
                            onTap: _prevStanza,
                            backgroundColor: colorScheme.surfaceContainerHighest,
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
                                  onTap: _goToChorus,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Expanded(
                                child: _buildQuickButton(
                                  context,
                                  label: 'Ir al Inicio',
                                  onTap: _goToStart,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Expanded(
                                child: _buildQuickButton(
                                  context,
                                  label: 'Apagar',
                                  onTap: _blackout,
                                  isDestructive: true,
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

  Widget _buildPreviewPanel(BuildContext context) {
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
                      Text(
                        _estrofas[_currentStanzaIndex],
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
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
                      Text(
                        _currentStanzaIndex < _estrofas.length - 1
                            ? _estrofas[_currentStanzaIndex + 1]
                            : 'Fin',
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Botón de configuración
              const SizedBox(width: 12),
              IconButton(
                onPressed: () => _showConfigSheet(context),
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

  void _showConfigSheet(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Configuración de Presentación',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 24),

              // Selector de fondo
              Text(
                'Fondo',
                style: Theme.of(context).textTheme.labelMedium,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Negro'),
                    selected: true,
                    onSelected: (_) {},
                  ),
                  ChoiceChip(
                    label: const Text('Color'),
                    selected: false,
                    onSelected: (_) {},
                  ),
                  ChoiceChip(
                    label: const Text('Imagen'),
                    selected: false,
                    onSelected: (_) {},
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Selector de tamaño de fuente
              Text(
                'Tamaño de Fuente',
                style: Theme.of(context).textTheme.labelMedium,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Pequeño'),
                    selected: false,
                    onSelected: (_) {},
                  ),
                  ChoiceChip(
                    label: const Text('Mediano'),
                    selected: true,
                    onSelected: (_) {},
                  ),
                  ChoiceChip(
                    label: const Text('Grande'),
                    selected: false,
                    onSelected: (_) {},
                  ),
                  ChoiceChip(
                    label: const Text('Extra Grande'),
                    selected: false,
                    onSelected: (_) {},
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Selector de velocidad de transición
              Text(
                'Velocidad de Transición',
                style: Theme.of(context).textTheme.labelMedium,
              ),
              const SizedBox(height: 8),
              Slider(
                value: 0.5,
                onChanged: (_) {},
              ),
            ],
          ),
        );
      },
    );
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
                style: TextStyle(
                  color: foregroundColor,
                  fontSize: 24,
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
              style: TextStyle(
                color: foregroundColor,
                fontSize: 16,
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
            style: TextStyle(
              color: isDestructive
                  ? colorScheme.onErrorContainer
                  : colorScheme.onSecondaryContainer,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}