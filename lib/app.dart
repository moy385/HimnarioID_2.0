import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'presentation/app_controller/screens/home_screen.dart';
import 'presentation/app_controller/screens/hymn_detail_screen.dart';
import 'presentation/shared_widgets/hymn_card.dart';

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

      // Rutas de la aplicación
      routes: {
        '/': (context) => const HomeScreen(),
        '/hymn-detail': (context) {
          final himno = ModalRoute.of(context)?.settings.arguments as HymnModel;
          return HymnDetailScreen(himno: himno);
        },
      },

      // Punto de entrada inicial basado en la plataforma
      // Por defecto muestra HomeScreen (controlador móvil)
      home: const HomeScreen(),
    );
  }
}
