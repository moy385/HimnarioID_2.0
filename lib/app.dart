import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';

/// Widget raíz de la aplicación HimnarioID 2.0
class HimnarioApp extends ConsumerWidget {
  const HimnarioApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'HimnarioID 2.0',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,

      // Punto de entrada inicial basado en la plataforma
      home: const _AppRouter(),
    );
  }
}

/// Enrutador inicial que detecta la plataforma y muestra la pantalla adecuada
class _AppRouter extends ConsumerWidget {
  const _AppRouter();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: Implementar detección de plataforma y enrutamiento
    // - PC/TV -> StandbyScreen (app_display)
    // - Mobile -> HomeScreen (app_controller)
    // - Web -> detección automática
    return const Scaffold(
      body: Center(
        child: Text('HimnarioID 2.0'),
      ),
    );
  }
}
