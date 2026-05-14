import 'package:flutter/material.dart' hide ConnectionState;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/connection_state.dart';
import '../../display/receptor_binding.dart';
import '../../providers/connection_providers.dart';
import '../../providers/discovery_providers.dart';

/// BottomSheet modal para descubrir y conectar displays en la red vía mDNS.
///
/// Muestra primero la selección de rol (Emisor/Receptor) y, al elegir
/// Emisor, la vista de escaneo con la lista de dispositivos encontrados.
///
/// ## Estados manejados
/// - Selección de rol: dos cards grandes (Emisor / Receptor)
/// - Escaneando: indicador de progreso con texto "Buscando displays..."
/// - Dispositivos encontrados: lista con nombre, IP y puerto
/// - Conectado: indicador verde y opción de desconectar
/// - Error: mensaje de error con opción de reintentar
/// - Vacío: mensaje informativo cuando no hay resultados
class DiscoverDisplaySheet extends ConsumerStatefulWidget {
  const DiscoverDisplaySheet({super.key});

  @override
  ConsumerState<DiscoverDisplaySheet> createState() =>
      _DiscoverDisplaySheetState();
}

class _DiscoverDisplaySheetState extends ConsumerState<DiscoverDisplaySheet> {
  /// IP del dispositivo al que se está conectando actualmente.
  /// Se mantiene tras un error para que el tile muestre "Reintentar".
  String? _connectingIp;

  /// Intenta conectar con el dispositivo seleccionado.
  Future<void> _connectToDevice(DeviceInfo device) async {
    setState(() {
      _connectingIp = device.ip;
    });

    final success = await ref
        .read(connectionStateProvider.notifier)
        .connectToDevice(device);

    if (!mounted) return;

    if (success) {
      setState(() {
        _connectingIp = null;
      });
    }
    // Si falla, _connectingIp se mantiene para que el tile muestre
    // "Reintentar" en lugar de "Conectar".
  }

  /// Desconecta del dispositivo actual.
  Future<void> _disconnect() async {
    await ref.read(connectionStateProvider.notifier).disconnect();
    if (!mounted) return;
    setState(() {
      _connectingIp = null;
    });
  }

  /// Maneja la selección del rol Emisor.
  void _selectEmitter() {
    ref.read(connectionRoleProvider.notifier).state = ConnectionRole.emitter;
  }

  /// Maneja la selección del rol Receptor.
  ///
  /// Valida que el servidor gRPC esté disponible antes de activar el modo
  /// Receptor. Si no hay servidor (web, móvil, o servidor detenido), muestra
  /// un mensaje informativo en un SnackBar.
  void _selectReceiver() {
    final server = ref.read(grpcDisplayServerProvider);
    if (server == null || !server.isRunning) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Modo Receptor no disponible en esta plataforma. '
            'Usa un PC con Linux, macOS o Windows.',
          ),
        ),
      );
      return;
    }
    ref.read(connectionRoleProvider.notifier).state = ConnectionRole.receiver;
    if (context.mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final discoveryState = ref.watch(discoveredDevicesProvider);
    final connectionState = ref.watch(connectionStateProvider);
    final role = ref.watch(connectionRoleProvider);

    final isConnected = connectionState is Connected;
    final connectedDevice = isConnected ? connectionState.device : null;
    final showScanView = role == ConnectionRole.emitter || isConnected;

    return DraggableScrollableSheet(
      initialChildSize: showScanView ? 0.65 : 0.55,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(20),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle de arrastre
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 4),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Conectar Display',
                        style: textTheme.titleLarge,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                      style: IconButton.styleFrom(
                        foregroundColor: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Contenido
              Expanded(
                child: showScanView
                    ? ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.all(24),
                        children: [
                          // Sección de escaneo
                          _buildScanSection(
                            colorScheme,
                            textTheme,
                            discoveryState,
                          ),

                          // Lista de dispositivos encontrados
                          if (discoveryState.devices.isNotEmpty) ...[
                            const SizedBox(height: 24),
                            Text(
                              'Dispositivos encontrados',
                              style: textTheme.titleSmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ...discoveryState.devices.map(
                              (device) => _buildDeviceTile(
                                colorScheme,
                                textTheme,
                                device,
                                connectedDevice,
                                connectionState,
                              ),
                            ),
                          ],

                          // Estado vacío sin escaneo activo ni error
                          if (!discoveryState.isScanning &&
                              discoveryState.devices.isEmpty &&
                              discoveryState.error == null)
                            _buildEmptyState(colorScheme, textTheme),

                          // Banner de error
                          if (discoveryState.error != null)
                            _buildErrorBanner(
                              colorScheme,
                              textTheme,
                              discoveryState.error!,
                            ),
                        ],
                      )
                    : _buildRoleSelection(
                        colorScheme,
                        textTheme,
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Pantalla de selección de rol (Emisor / Receptor).
  ///
  /// Muestra dos cards grandes con iconos y descripciones. Al seleccionar
  /// Emisor se transiciona a la vista de escaneo; al seleccionar Receptor
  /// se cierra el sheet y se activa el modo receptor.
  Widget _buildRoleSelection(
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Card: Soy Emisor
          _roleCard(
            icon: Icons.cast_rounded,
            title: 'Soy Emisor',
            description: 'Controlar la proyección\ndesde mi dispositivo',
            backgroundColor: colorScheme.primaryContainer,
            foregroundColor: colorScheme.onPrimaryContainer,
            textTheme: textTheme,
            onTap: _selectEmitter,
          ),
          const SizedBox(height: 16),

          // Card: Soy Receptor
          _roleCard(
            icon: Icons.tv_rounded,
            title: 'Soy Receptor',
            description: 'Mostrar en esta pantalla\nlo que el emisor envía',
            backgroundColor: colorScheme.secondaryContainer,
            foregroundColor: colorScheme.onSecondaryContainer,
            textTheme: textTheme,
            onTap: _selectReceiver,
          ),
        ],
      ),
    );
  }

  /// Sección superior: botón "Buscar displays" o indicador de escaneo.
  Widget _buildScanSection(
    ColorScheme colorScheme,
    TextTheme textTheme,
    DiscoveryState state,
  ) {
    if (state.isScanning) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(width: 16),
            Text(
              'Buscando displays...',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: () {
          ref.read(discoveredDevicesProvider.notifier).startScanning();
        },
        icon: const Icon(Icons.search_rounded),
        label: const Text('Buscar displays'),
      ),
    );
  }

  /// Tile individual para un dispositivo descubierto.
  ///
  /// Muestra icono, nombre, IP:puerto y un botón de acción contextual
  /// (Conectar / Conectado / Reintentar).
  Widget _buildDeviceTile(
    ColorScheme colorScheme,
    TextTheme textTheme,
    DeviceInfo device,
    DeviceInfo? connectedDevice,
    ConnectionState connectionState,
  ) {
    final isThisConnected = connectedDevice != null &&
        connectedDevice.ip == device.ip &&
        connectedDevice.port == device.port;

    final isThisConnecting =
        _connectingIp == device.ip && connectionState is Connecting;

    final isThisError =
        _connectingIp == device.ip && connectionState is ConnectionError;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isThisConnected
            ? colorScheme.primaryContainer.withValues(alpha: 0.3)
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: isThisConnected
            ? Border.all(
                color: colorScheme.primary.withValues(alpha: 0.5),
              )
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: isThisConnected ? null : () => _connectToDevice(device),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icono del dispositivo
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isThisConnected
                        ? colorScheme.primary
                        : colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isThisConnected
                        ? Icons.cast_connected_rounded
                        : Icons.tv_rounded,
                    color: isThisConnected
                        ? colorScheme.onPrimary
                        : colorScheme.onSecondaryContainer,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),

                // Nombre, IP y puerto
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        device.name,
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${device.ip}:${device.port}',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // Botón de acción contextual
                _buildDeviceAction(
                  colorScheme,
                  isThisConnected,
                  isThisConnecting,
                  isThisError,
                  device,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Botón de acción para el tile del dispositivo.
  ///
  /// Retorna el widget apropiado según el estado:
  /// - Conectado: "Desconectar" (rojo)
  /// - Conectando: spinner
  /// - Error: "Reintentar" (rojo)
  /// - Default: "Conectar" (tonal)
  Widget _buildDeviceAction(
    ColorScheme colorScheme,
    bool isThisConnected,
    bool isThisConnecting,
    bool isThisError,
    DeviceInfo device,
  ) {
    if (isThisConnected) {
      return TextButton(
        onPressed: () => _disconnect(),
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.error,
          padding: const EdgeInsets.symmetric(horizontal: 12),
        ),
        child: const Text('Desconectar'),
      );
    }

    if (isThisConnecting) {
      return SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: colorScheme.primary,
        ),
      );
    }

    if (isThisError) {
      return TextButton(
        onPressed: () => _connectToDevice(device),
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.error,
          padding: const EdgeInsets.symmetric(horizontal: 12),
        ),
        child: const Text('Reintentar'),
      );
    }

    return FilledButton.tonalIcon(
      onPressed: () => _connectToDevice(device),
      icon: const Icon(Icons.link_rounded, size: 18),
      label: const Text('Conectar'),
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16),
      ),
    );
  }

  /// Estado vacío: no hay dispositivos y no hay escaneo activo.
  Widget _buildEmptyState(ColorScheme colorScheme, TextTheme textTheme) {
    return Padding(
      padding: const EdgeInsets.only(top: 48),
      child: Column(
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 64,
            color: colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No se encontraron displays',
            style: textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Aseg\u00farate de que el display est\u00e9 encendido\n'
            'y conectado a la misma red.',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Card de selección de rol para el sheet de conexión.
  Widget _roleCard({
    required IconData icon,
    required String title,
    required String description,
    required Color backgroundColor,
    required Color foregroundColor,
    required TextTheme textTheme,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: foregroundColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    icon,
                    color: foregroundColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: textTheme.titleMedium?.copyWith(
                          color: foregroundColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: textTheme.bodyMedium?.copyWith(
                          color: foregroundColor.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: foregroundColor.withValues(alpha: 0.6),
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Banner de error con opción de reintentar escaneo.
  Widget _buildErrorBanner(
    ColorScheme colorScheme,
    TextTheme textTheme,
    String errorMessage,
  ) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: colorScheme.onErrorContainer,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Error de escaneo',
                  style: textTheme.labelMedium?.copyWith(
                    color: colorScheme.onErrorContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  errorMessage,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onErrorContainer,
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    ref
                        .read(discoveredDevicesProvider.notifier)
                        .clearError();
                    ref
                        .read(discoveredDevicesProvider.notifier)
                        .startScanning();
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: colorScheme.onErrorContainer,
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 32),
                  ),
                  child: const Text('Reintentar escaneo'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
