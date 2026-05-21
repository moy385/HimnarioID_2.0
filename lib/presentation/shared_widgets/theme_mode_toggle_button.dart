import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers/theme_mode_provider.dart';

/// Botón flotante en la esquina inferior derecha para alternar entre
/// modo claro, oscuro y seguir el tema del dispositivo.
///
/// Muestra un icono dinámico según el modo actual:
/// - ☀️ `light_mode` → modo claro
/// - 🌙 `dark_mode` → modo oscuro
/// - 🤖 `brightness_auto` → seguir dispositivo
class ThemeModeToggleButton extends ConsumerWidget {
  const ThemeModeToggleButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return Positioned(
      right: 16,
      bottom: 16,
      child: FloatingActionButton.small(
        heroTag: 'theme_mode_toggle',
        onPressed: () => ref.read(themeModeProvider.notifier).cycleMode(),
        tooltip: _tooltip(themeMode),
        child: Icon(_icon(themeMode)),
      ),
    );
  }

  IconData _icon(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return Icons.light_mode;
      case ThemeMode.dark:
        return Icons.dark_mode;
      case ThemeMode.system:
        return Icons.brightness_auto;
    }
  }

  String _tooltip(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Modo claro';
      case ThemeMode.dark:
        return 'Modo oscuro';
      case ThemeMode.system:
        return 'Seguir dispositivo';
    }
  }
}
