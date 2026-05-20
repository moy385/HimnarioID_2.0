import 'dart:io';

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:video_player/video_player.dart';

/// Widget que reproduce un video como fondo de pantalla.
///
/// El video se reproduce en loop, sin audio, ocupando todo el espacio
/// disponible con [BoxFit.cover]. Incluye un overlay oscuro para
/// legibilidad del texto.
///
/// Si el video no se puede cargar (archivo inexistente, formato inválido),
/// degrada gracefulmente a un fondo negro sólido.
class FondoVideoBackground extends StatefulWidget {
  final String rutaArchivo;
  final Widget child;

  const FondoVideoBackground({
    super.key,
    required this.rutaArchivo,
    required this.child,
  });

  @override
  State<FondoVideoBackground> createState() => _FondoVideoBackgroundState();
}

class _FondoVideoBackgroundState extends State<FondoVideoBackground> {
  static final _log = Logger('FondoVideoBackground');

  VideoPlayerController? _controller;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  void _initVideo() {
    final uri = Uri.tryParse(widget.rutaArchivo);

    // ── Detectar si es content:// URI (Android scoped storage) ──
    if (uri != null && uri.scheme == 'content') {
      _log.info('Inicializando video desde content URI: ${widget.rutaArchivo}');
      _controller = VideoPlayerController.contentUri(uri);
    } else {
      final file = File(widget.rutaArchivo);
      if (!file.existsSync()) {
        _log.warning('Archivo de video no encontrado: ${widget.rutaArchivo}');
        if (mounted) setState(() => _hasError = true);
        return;
      }
      _controller = VideoPlayerController.file(file);
    }

    _controller!.initialize().then((_) {
      if (mounted) {
        _controller!.setLooping(true);
        _controller!.setVolume(0);
        _controller!.play();
        setState(() {});
      }
    }).catchError((e) {
      _log.severe('Error al inicializar video: $e');
      if (mounted) setState(() => _hasError = true);
    });
  }

  @override
  void didUpdateWidget(FondoVideoBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rutaArchivo != widget.rutaArchivo) {
      _controller?.dispose();
      _controller = null;
      _hasError = false;
      _initVideo();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError || _controller == null || !_controller!.value.isInitialized) {
      // Fallback: fondo negro si el video no se pudo cargar
      return Stack(
        children: [
          Container(color: Colors.black87),
          Positioned.fill(child: widget.child),
        ],
      );
    }

    return _VideoBackground(
      controller: _controller!,
      child: Stack(
        children: [
          // Overlay oscuro sutil para legibilidad
          Container(color: Colors.black26),
          // Contenido centrado
          Positioned.fill(child: widget.child),
        ],
      ),
    );
  }
}

/// Renderiza el [VideoPlayer] cubriendo todo el espacio disponible
/// con [BoxFit.cover], manteniendo la relación de aspecto original.
class _VideoBackground extends StatelessWidget {
  final VideoPlayerController controller;
  final Widget child;

  const _VideoBackground({
    required this.controller,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final videoSize = controller.value.size;
    if (videoSize == Size.zero) return child;

    return Stack(
      children: [
        // Video escalado para cubrir toda el area
        Positioned.fill(
          child: FittedBox(
            fit: BoxFit.cover,
            clipBehavior: Clip.hardEdge,
            child: SizedBox(
              width: videoSize.width,
              height: videoSize.height,
              child: VideoPlayer(controller),
            ),
          ),
        ),
        // Contenido encima
        Positioned.fill(child: child),
      ],
    );
  }
}
