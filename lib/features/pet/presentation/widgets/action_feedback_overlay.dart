import 'dart:math';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Overlay efímero que aparece sobre la mascota cuando el jugador realiza
/// una acción (comer, bañar, dormir...). Se autodestruye al terminar la
/// animación llamando a [onCompleted].
///
/// Renderiza varios emojis que se elevan + un letrero centrado.
class ActionFeedbackOverlay extends StatefulWidget {
  final String emoji;
  final String label;
  final Color labelColor;
  final VoidCallback onCompleted;

  const ActionFeedbackOverlay({
    super.key,
    required this.emoji,
    required this.label,
    required this.labelColor,
    required this.onCompleted,
  });

  @override
  State<ActionFeedbackOverlay> createState() => _ActionFeedbackOverlayState();
}

class _ActionFeedbackOverlayState extends State<ActionFeedbackOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    final rand = Random();
    _particles = List.generate(6, (i) {
      return _Particle(
        dx: (rand.nextDouble() - 0.5) * 120,
        startDelay: i * 0.08,
        rotation: (rand.nextDouble() - 0.5) * 0.6,
        scale: 0.8 + rand.nextDouble() * 0.6,
      );
    });

    _controller.forward().whenComplete(widget.onCompleted);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, __) {
          final t = _controller.value;
          return Stack(
            alignment: Alignment.center,
            children: [
              for (final p in _particles) _buildParticle(p, t),
              _buildLabel(t),
            ],
          );
        },
      ),
    );
  }

  Widget _buildParticle(_Particle p, double t) {
    final localT = ((t - p.startDelay) / (1 - p.startDelay)).clamp(0.0, 1.0);
    final opacity = localT < 0.85 ? 1.0 : (1 - localT) / 0.15;
    return Transform.translate(
      offset: Offset(p.dx, -80 * localT),
      child: Transform.rotate(
        angle: p.rotation * localT,
        child: Opacity(
          opacity: opacity.clamp(0.0, 1.0),
          child: Transform.scale(
            scale: p.scale,
            child: Text(widget.emoji, style: const TextStyle(fontSize: 28)),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(double t) {
    final opacity = t < 0.15
        ? t / 0.15
        : t > 0.75
            ? (1 - t) / 0.25
            : 1.0;
    return Opacity(
      opacity: opacity.clamp(0.0, 1.0),
      child: Transform.translate(
        offset: const Offset(0, 60),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.cardBackground.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: widget.labelColor, width: 1.5),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontFamily: 'PressStart2P',
              fontSize: 8,
              color: widget.labelColor,
            ),
          ),
        ),
      ),
    );
  }
}

class _Particle {
  final double dx;
  final double startDelay;
  final double rotation;
  final double scale;

  const _Particle({
    required this.dx,
    required this.startDelay,
    required this.rotation,
    required this.scale,
  });
}
