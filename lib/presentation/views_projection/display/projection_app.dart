import 'dart:async';
import 'dart:convert';
import 'dart:io' show stdin;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/enums/estrofa_tipo.dart';
import '../../../core/enums/himno_tipo.dart';
import '../../../domain/entities/estrofa.dart';
import '../../../domain/entities/himno.dart';
import '../providers/live_control_providers.dart';
import 'live_projection_screen.dart';

/// Punto de entrada para la segunda ventana de proyección.
///
/// Corre como una instancia Flutter separada lanzada vía [Process.start]
/// con el argumento `--projection`. Muestra [LiveProjectionScreen] cuando
/// hay un himno activo, o un texto de espera.
///
/// ## Comunicación entre ventanas
/// Recibe mensajes JSON desde el proceso padre a través de stdin.
/// Cada mensaje es una línea JSON independiente:
/// - `LOAD_HYMN`: Carga un himno completo con sus estrofas
/// - `NEXT_STANZA`: Avanza a la siguiente estrofa
/// - `PREV_STANZA`: Retrocede a la estrofa anterior
/// - `GO_TO_STANZA`: Va a una estrofa específica por índice
/// - `SET_CONFIG`: Actualiza configuración visual
/// - `BLACKOUT`: Activa/desactiva el modo blackout
class ProjectionApp extends ConsumerStatefulWidget {
  const ProjectionApp({super.key});

  @override
  ConsumerState<ProjectionApp> createState() => _ProjectionAppState();
}

class _ProjectionAppState extends ConsumerState<ProjectionApp> {
  StreamSubscription<String>? _stdinSubscription;

  @override
  void initState() {
    super.initState();
    _setupStdinListener();
  }

  /// Configura la escucha de stdin para recibir mensajes JSON
  /// del proceso padre.
  void _setupStdinListener() {
    try {
      _stdinSubscription = stdin
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(_handleMessage);
    } catch (_) {
      // Sin stdin disponible (web, test, etc.) — modo lectura sola
    }
  }

  /// Procesa un mensaje JSON recibido por stdin.
  void _handleMessage(String line) {
    try {
      final message = jsonDecode(line) as Map<String, dynamic>;
      final notifier = ref.read(liveControlProvider.notifier);
      switch (message['type'] as String?) {
        case 'LOAD_HYMN':
          _handleLoadHymn(notifier, message);
        case 'NEXT_STANZA':
          notifier.nextStanza();
        case 'PREV_STANZA':
          notifier.prevStanza();
        case 'GO_TO_STANZA':
          final index = message['index'] as int;
          notifier.goToStanza(index);
        case 'SET_CONFIG':
          // Configuración visual (opcional)
        case 'BLACKOUT':
          final enabled = message['enabled'] as bool;
          if (enabled) {
            notifier.blackout();
          } else {
            notifier.toggleBlackout();
          }
      }
    } catch (_) {
      // Ignorar mensajes mal formados
    }
  }

  /// Procesa un mensaje LOAD_HYMN: construye Himno y Estrofas
  /// a partir de los campos planos en el JSON.
  void _handleLoadHymn(
    LiveControlNotifier notifier,
    Map<String, dynamic> message,
  ) {
    final hymn = Himno(
      id: message['himno_id'] as int,
      titulo: message['titulo'] as String,
      numero: message['numero'] as int?,
      tipo: HimnoTipo.values.firstWhere(
        (e) => e.name == (message['tipo'] as String? ?? 'oficial'),
        orElse: () => HimnoTipo.oficial,
      ),
    );

    final estrofasJson = message['estrofas'] as List<dynamic>? ?? [];
    final estrofas = estrofasJson.map((e) {
      final m = e as Map<String, dynamic>;
      return Estrofa(
        id: m['id'] as int,
        versionPaisId: m['version_pais_id'] as int,
        tipo: EstrofaTipo.values.firstWhere(
          (t) => t.name == (m['tipo'] as String? ?? 'estrofa'),
          orElse: () => EstrofaTipo.estrofa,
        ),
        orden: m['orden'] as int,
        contenido: m['contenido'] as String,
      );
    }).toList();

    notifier.loadHymn(hymn, estrofas);
  }

  @override
  void dispose() {
    _stdinSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final liveState = ref.watch(liveControlProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'HimnarioID - Proyección',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: Colors.black,
      ),
      home: Scaffold(
        backgroundColor: Colors.black,
        body: liveState.hymn == null
            ? const Center(
                child: Text(
                  'Esperando proyección...',
                  style: TextStyle(color: Colors.white54),
                ),
              )
            : const LiveProjectionScreen(),
      ),
    );
  }
}
