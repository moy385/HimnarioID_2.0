import 'package:flutter/material.dart';

/// Pantalla de Proyección en Vivo (Live Projection)
/// Muestra el himno actual con transiciones suaves entre estrofas
class LiveProjectionScreen extends StatefulWidget {
  final String himnoTitulo;
  final String himnoNumero;
  final String estrofaActual;
  final bool isVisible;
  final Color? backgroundColor;
  final double fontSize;

  const LiveProjectionScreen({
    super.key,
    required this.himnoTitulo,
    required this.himnoNumero,
    required this.estrofaActual,
    this.isVisible = true,
    this.backgroundColor,
    this.fontSize = 36,
  });

  @override
  State<LiveProjectionScreen> createState() => _LiveProjectionScreenState();
}

class _LiveProjectionScreenState extends State<LiveProjectionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.forward();
  }

  @override
  void didUpdateWidget(LiveProjectionScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Animar cuando cambia la estrofa
    if (oldWidget.estrofaActual != widget.estrofaActual) {
      _animationController.reset();
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = widget.backgroundColor ?? Colors.black;
    final textTheme = Theme.of(context).textTheme;

    // Si no hay visibilidad (blackout), mostrar pantalla negra
    if (!widget.isVisible) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: const SizedBox.expand(),
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: 80,
            vertical: 60,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Número del himno (opcional, puede ocultarse en configuración)
              Text(
                '#${widget.himnoNumero}',
                style: textTheme.displayLarge?.copyWith(
                  color: Colors.white.withValues(alpha: 0.3),
                  fontWeight: FontWeight.bold,
                  fontSize: widget.fontSize * 0.6,
                ),
              ),
              const SizedBox(height: 16),

              // Título del himno
              Text(
                widget.himnoTitulo,
                style: textTheme.displayLarge?.copyWith(
                  color: Colors.white,
                  fontSize: widget.fontSize * 1.2,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              // Divisor
              Container(
                width: 200,
                height: 2,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.white.withValues(alpha: 0.5),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 48),

              // Contenido de la estrofa
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    widget.estrofaActual,
                    style: textTheme.bodyLarge?.copyWith(
                      color: Colors.white,
                      fontSize: widget.fontSize,
                      height: 1.8,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}