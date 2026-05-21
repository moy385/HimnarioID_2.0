import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';

/// Widget que captura la tecla F11 para alternar pantalla completa.
///
/// Envuelve el árbol de widgets y registra un handler global de teclado
/// mediante [HardwareKeyboard]. Al presionar F11, alterna el estado
/// de fullscreen usando [windowManager.setFullScreen].
///
/// Solo funciona en desktop (Windows, Linux, macOS).
/// En web el navegador captura F11 antes que Flutter.
class FullscreenHandler extends StatefulWidget {
  final Widget child;

  const FullscreenHandler({super.key, required this.child});

  @override
  State<FullscreenHandler> createState() => _FullscreenHandlerState();
}

class _FullscreenHandlerState extends State<FullscreenHandler> {
  bool _handlerRegistered = false;

  @override
  void initState() {
    super.initState();
    _registerHandler();
  }

  void _registerHandler() {
    // En web el navegador captura F11 antes que Flutter.
    if (kIsWeb) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_handlerRegistered) {
        ServicesBinding.instance.keyboard.addHandler(_onKeyEvent);
        _handlerRegistered = true;
      }
    });
  }

  bool _onKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.f11) {
      _toggleFullScreen();
      return true;
    }
    return false;
  }

  Future<void> _toggleFullScreen() async {
    try {
      final isFullScreen = await windowManager.isFullScreen();
      await windowManager.setFullScreen(!isFullScreen);
    } catch (_) {
      // Silencioso — window_manager no disponible en esta plataforma.
    }
  }

  @override
  void dispose() {
    if (_handlerRegistered) {
      ServicesBinding.instance.keyboard.removeHandler(_onKeyEvent);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
