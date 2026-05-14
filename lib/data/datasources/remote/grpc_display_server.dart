import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grpc/grpc.dart';
import 'package:logging/logging.dart';
import 'package:uuid/uuid.dart';

import '../../../presentation/views_projection/providers/live_control_providers.dart';
import '../../../proto/generated/hymn_control.pbgrpc.dart';

/// Servidor gRPC para control remoto de un display.
///
/// Extiende [HymnControlServiceBase] generado por protobuf.
/// Escucha comandos de controladores remotos y los propaga mediante
/// el callback [onCommand] hacia los providers de Riverpod.
class GrpcDisplayServer extends HymnControlServiceBase {
  static final _log = Logger('GrpcDisplayServer');

  /// Puerto por defecto para el servidor gRPC.
  static const int defaultPort = 50051;

  /// Versión actual del protocolo.
  static const int protocolVersion = 1;

  /// Nombre identificador del display en la red.
  final String displayName;

  /// Identificador único de la sesión actual.
  final String sessionId;

  /// Puerto en el que escucha el servidor.
  final int port;

  /// Callback para propagar comandos a los providers.
  /// Recibe una función de actualización del [LiveControlState].
  void Function(LiveControlState Function(LiveControlState) update)? onCommand;

  /// Callback para cargar un himno completo por ID.
  /// Se invoca cuando se recibe un comando [CommandType.JUMP_TO_HYMN].
  /// Debe cargar el himno y sus estrofas, y llamar a [LiveControlNotifier.loadHymn].
  Future<void> Function(int hymnId)? onJumpToHymn;

  Server? _server;
  bool _isRunning = false;

  /// ProviderContainer opcional para acceder al estado real de LiveControl.
  final ProviderContainer? _container;

  /// Indica si el servidor está ejecutándose.
  bool get isRunning => _isRunning;

  GrpcDisplayServer({
    this.displayName = 'Display Principal',
    int? port,
    String? sessionId,
    ProviderContainer? container,
  })  : port = port ?? defaultPort,
        sessionId = sessionId ?? const Uuid().v4(),
        _container = container;

  /// Inicia el servidor gRPC en [port] escuchando en todas las interfaces.
  Future<void> start() async {
    if (_isRunning) {
      _log.warning('El servidor ya está en ejecución.');
      return;
    }

    try {
      _server = Server.create(services: [this]);
      await _server!.serve(
        address: InternetAddress.anyIPv4,
        port: port,
      );
      _isRunning = true;
      _log.info(
        'Servidor gRPC iniciado en 0.0.0.0:$port '
        '(displayName: $displayName, sessionId: $sessionId)',
      );
    } catch (e) {
      _log.severe('Error al iniciar servidor gRPC: $e');
      rethrow;
    }
  }

  /// Detiene el servidor gRPC.
  Future<void> stop() async {
    if (!_isRunning) return;
    _isRunning = false;
    await _server?.shutdown();
    _server = null;
    _log.info('Servidor gRPC detenido.');
  }

  @override
  Future<CommandResponse> sendCommand(
    ServiceCall call,
    CommandRequest request,
  ) async {
    _log.info(
      'Comando recibido: ${request.type} '
      '(stanzaIndex: ${request.hasStanzaIndex() ? request.stanzaIndex : null}, '
      'hymnId: ${request.hasHymnId() ? request.hymnId : null})',
    );

    try {
      switch (request.type) {
        case CommandType.NEXT_STANZA:
          _dispatch(
            (state) => state.copyWith(
              currentIndex:
                  state.hasNext ? state.currentIndex + 1 : state.currentIndex,
              isBlackout: false,
            ),
          );
          break;

        case CommandType.PREV_STANZA:
          _dispatch(
            (state) => state.copyWith(
              currentIndex:
                  state.hasPrev ? state.currentIndex - 1 : state.currentIndex,
              isBlackout: false,
            ),
          );
          break;

        case CommandType.GO_TO_STANZA:
          if (request.hasStanzaIndex()) {
            _dispatch((state) {
              final maxIdx = (state.estrofas.length - 1).clamp(0, 999);
              final idx = request.stanzaIndex.clamp(0, maxIdx);
              return state.copyWith(
                currentIndex: idx,
                isBlackout: false,
              );
            });
          }
          break;

        case CommandType.GO_TO_CHORUS:
          _dispatch((state) {
            final chorusIndex = state.estrofas.indexWhere((e) => e.isChorus);
            if (chorusIndex != -1) {
              return state.copyWith(
                currentIndex: chorusIndex,
                isBlackout: false,
              );
            }
            return state;
          });
          break;

        case CommandType.BLACKOUT:
          _dispatch((state) => state.copyWith(isBlackout: true));
          break;

        case CommandType.CLEAR_BLACKOUT:
          _dispatch(
            (state) => state.copyWith(currentIndex: 0, isBlackout: false),
          );
          break;

        case CommandType.JUMP_TO_HYMN:
          if (request.hasHymnId()) {
            _log.info('Cargando himno ${request.hymnId}...');
            onJumpToHymn?.call(request.hymnId);
          }
          break;

        case CommandType.PING:
          // No modifica estado, solo responder
          break;

        default:
          _log.warning('Tipo de comando no manejado: ${request.type}');
      }

      return CommandResponse(success: true);
    } catch (e) {
      _log.severe('Error procesando comando: $e');
      return CommandResponse(
        success: false,
        errorMessage: 'Error interno: $e',
      );
    }
  }

  @override
  Future<DisplayStatus> getStatus(ServiceCall call, Empty request) async {
    // El estado actual se consulta indirectamente a través del callback.
    // Retornamos un estado por defecto; la sincronización en tiempo real
    // se maneja mediante watchStatus.
    return DisplayStatus(
      currentHymnId: 0,
      currentHymnTitle: '',
      currentStanzaIndex: 0,
      totalStanzas: 0,
      transpositionSemitones: 0,
      isBlackout: false,
      fontSize: 48.0,
      displayName: displayName,
    );
  }

  @override
  Stream<DisplayStatus> watchStatus(ServiceCall call, Empty request) async* {
    // Si no tenemos container, usar el fallback estático
    if (_container == null) {
      yield await getStatus(call, request);
      await for (final _ in Stream.periodic(const Duration(seconds: 5))) {
        if (!_isRunning) break;
        yield await getStatus(call, request);
      }
      return;
    }

    // Emitir estado inicial real desde LiveControl
    yield _buildDisplayStatus();

    // Combinar cambios de estado con timer periódico como fallback
    final controller = StreamController<DisplayStatus>();

    // Escuchar cambios en el provider para emitir en cada cambio
    final sub = _container.listen<LiveControlState>(
      liveControlProvider,
      (previous, next) {
        if (!controller.isClosed) {
          controller.add(_buildDisplayStatus());
        }
      },
    );

    // Timer periódico como fallback adicional
    final timerSub = Stream.periodic(const Duration(seconds: 5)).listen((_) {
      if (!controller.isClosed) {
        controller.add(_buildDisplayStatus());
      }
    });

    // Pasar eventos del controller al generador
    await for (final status in controller.stream) {
      if (!_isRunning) break;
      yield status;
    }

    sub.close();
    await timerSub.cancel();
    await controller.close();
  }

  /// Construye un [DisplayStatus] a partir del estado real de [LiveControlState].
  DisplayStatus _buildDisplayStatus() {
    final state = _container!.read(liveControlProvider);
    return DisplayStatus(
      currentHymnId: state.hymn?.id ?? 0,
      currentHymnTitle: state.hymn?.titulo ?? '',
      currentStanzaIndex: state.currentIndex,
      totalStanzas: state.estrofas.length,
      transpositionSemitones: 0,
      isBlackout: state.isBlackout,
      fontSize: 48.0,
      displayName: displayName,
    );
  }

  @override
  Future<HandshakeResponse> handshake(
    ServiceCall call,
    HandshakeRequest request,
  ) async {
    _log.info(
      'Handshake recibido de ${request.clientName} '
      'v${request.clientVersion} (protocolo ${request.protocolVersion})',
    );

    return HandshakeResponse(
      accepted: true,
      serverName: 'HimnarioID Display',
      serverVersion: '2.0.0',
      displayName: displayName,
      protocolVersion: protocolVersion,
      sessionId: sessionId,
    );
  }

  /// Despacha una actualización de estado vía el callback [onCommand].
  void _dispatch(LiveControlState Function(LiveControlState) update) {
    onCommand?.call(update);
  }
}
