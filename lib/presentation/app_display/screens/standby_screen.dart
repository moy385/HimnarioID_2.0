import 'package:flutter/material.dart';

/// Pantalla de Standby (Espera) para Display
/// Se muestra cuando no hay conexión con el controlador
class StandbyScreen extends StatelessWidget {
  final String? networkName;

  const StandbyScreen({
    super.key,
    this.networkName,
  });

  @override
  Widget build(BuildContext context) {
    // Usar tema de proyección (fondo negro, texto blanco)
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo o icono de himnario
            Icon(
              Icons.music_note_rounded,
              size: 120,
              color: Colors.white.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 48),

            // Título principal
            Text(
              'HimnarioID',
              style: textTheme.displayLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w300,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 16),

            // Subtítulo
            Text(
              'Esperando conexión del controlador...',
              style: textTheme.titleLarge?.copyWith(
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 48),

            // Indicador de espera animado
            _buildLoadingIndicator(),
            const SizedBox(height: 48),

            // Información de red
            if (networkName != null) ...[
              const Divider(
                color: Colors.white24,
                indent: 80,
                endIndent: 80,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.wifi_rounded,
                    color: Colors.white.withValues(alpha: 0.5),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Red: $networkName',
                    style: textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return SizedBox(
      width: 200,
      child: LinearProgressIndicator(
        backgroundColor: Colors.white.withValues(alpha: 0.1),
        valueColor: AlwaysStoppedAnimation<Color>(
          Colors.white.withValues(alpha: 0.7),
        ),
      ),
    );
  }
}