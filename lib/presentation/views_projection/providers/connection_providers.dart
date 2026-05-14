import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../../../core/errors/exceptions.dart';
import '../../../core/network/connection_state.dart';
import '../../../data/datasources/remote/grpc_control_datasource.dart';
import '../../../data/repositories/control_repository_impl.dart';
import '../../../domain/repositories/control_repository.dart';

/// Provider del datasource de control remoto.
final controlDataSourceProvider = Provider<GrpcControlDataSource>((ref) {
  return GrpcControlDataSource();
});

/// Provider del repositorio de control remoto.
final controlRepositoryProvider = Provider<ControlRepository>((ref) {
  final dataSource = ref.read(controlDataSourceProvider);
  return ControlRepositoryImpl(dataSource: dataSource);
});

/// Provider del estado de conexión usando [ConnectionNotifier].
final connectionStateProvider =
    StateNotifierProvider<ConnectionNotifier, ConnectionState>((ref) {
  return ConnectionNotifier(ref.read(controlDataSourceProvider), ref);
});

/// Provider con la información del dispositivo conectado.
final connectedDeviceProvider = Provider<DeviceInfo?>((ref) {
  final state = ref.watch(connectionStateProvider);
  if (state is Connected) {
    return state.device;
  }
  return null;
});

/// Provider del rol de conexión (Emisor/Receptor).
final connectionRoleProvider =
    StateProvider<ConnectionRole>((ref) => ConnectionRole.none);

/// Provider de solo lectura para verificar si hay conexión activa.
final isConnectedProvider = Provider<bool>((ref) {
  return ref.watch(connectionStateProvider) is Connected;
});

/// Notifier que maneja la conexión con un display remoto.
///
/// Expone [connectToDevice] y [disconnect] para ser usados desde la UI.
class ConnectionNotifier extends StateNotifier<ConnectionState> {
  static final _log = Logger('ConnectionNotifier');

  final GrpcControlDataSource _dataSource;
  final Ref _ref;

  ConnectionNotifier(this._dataSource, this._ref) : super(const Disconnected());

  /// Intenta conectar con un dispositivo remoto.
  /// Retorna `true` si la conexión fue exitosa.
  Future<bool> connectToDevice(DeviceInfo device) async {
    state = const Connecting();
    _log.info('Conectando a ${device.ip}:${device.port}...');

    try {
      await _dataSource.connect(device.ip, device.port);
      state = Connected(device);
      _log.info('Conexión exitosa a ${device.name}');
      return true;
    } on NetworkException catch (e) {
      state = ConnectionError(e.message);
      _log.severe('Error de conexión: ${e.message}');
      return false;
    } catch (e) {
      state = ConnectionError('Error inesperado: $e');
      _log.severe('Error inesperado al conectar: $e');
      return false;
    }
  }

  /// Desconecta del dispositivo actual y resetea el rol a [ConnectionRole.none].
  Future<void> disconnect() async {
    await _dataSource.disconnect();
    state = const Disconnected();
    _ref.read(connectionRoleProvider.notifier).state = ConnectionRole.none;
    _log.info('Desconectado. Rol reseteado a none.');
  }
}
