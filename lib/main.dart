import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import 'app.dart';
import 'bootstrap/app_container.dart';
import 'bootstrap/app_initializer.dart';
import 'presentation/views_projection/display/projection_app.dart';

/// Punto de entrada principal de HimnarioID 2.0.
///
/// ## Multi-ventana (Bug 3)
/// Cuando se lanza con el argumento `--projection`, la aplicación inicia
/// como una ventana de proyección secundaria (ver [ProjectionApp]).
/// Esto permite que el usuario tenga una ventana de control y una ventana
/// de proyección separadas en el escritorio.
void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Modo Proyección: segunda ventana ──
  if (args.contains('--projection')) {
    final container = ProviderContainer();
    // Inicializar servicios necesarios para la ventana de proyección
    AppContainer().init(container);
    // El subproceso NO necesita servidor gRPC (se comunica por stdin/stdout)
    await AppInitializer.initialize(container: container, skipNetwork: true);

    runApp(
      UncontrolledProviderScope(
        container: container,
        child: const ProjectionApp(),
      ),
    );
    return;
  }

  // ── Modo Principal ──
  // Inicializar window_manager para desktop (no web ni móvil)
  if (!kIsWeb) {
    try {
      await windowManager.ensureInitialized();
    } catch (_) {
      // window_manager no está disponible en esta plataforma
    }
  }

  // Crear el ProviderContainer antes de runApp
  final container = ProviderContainer();

  // Registrar en el singleton global
  AppContainer().init(container);

  // Inicializar servicios asíncronos (BD, mDNS, servidor gRPC, etc.)
  await AppInitializer.initialize(container: container);

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const HimnarioApp(),
    ),
  );
}
