import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

enum SkyJumpState { waiting, playing, gameOver }

class _Platform {
  Offset position;
  final double width;
  _Platform(this.position, this.width);
}

/// Inspirado en Doodle Jump: la mascota salta automáticamente y rebota
/// al chocar con plataformas. El jugador la mueve con tap izquierdo /
/// derecho (la mitad de la pantalla determina la dirección). El juego
/// se acaba cuando la mascota cae por debajo del viewport.
class SkyJumpGame extends FlameGame with TapCallbacks, DragCallbacks {
  final void Function(int score) onGameOver;

  SkyJumpGame({required this.onGameOver});

  SkyJumpState gameState = SkyJumpState.waiting;
  int score = 0;
  double _cameraOffset = 0; // cuánto ha subido el mundo en total

  // Mascota
  late double petX;
  late double petY; // coordenada en el "mundo" (no en pantalla)
  double _velY = 0;
  static const _gravity = 1200.0;
  static const _jumpVelocity = -620.0;
  static const _petSize = 36.0;
  static const _horizontalSpeed = 220.0;

  // Plataformas (coordenadas en el mundo, se desplazan al subir camera)
  final _rng = Random();
  final List<_Platform> _platforms = [];
  static const _platformWidth = 70.0;
  static const _platformHeight = 12.0;

  // Input lateral: -1 izq, 0 quieto, 1 der
  int _horizontalInput = 0;

  late TextComponent _scoreText;
  late TextComponent _instructionText;

  @override
  Color backgroundColor() => const Color(0xFF1A1A2E);

  @override
  Future<void> onLoad() async {
    petX = size.x / 2;
    petY = size.y * 0.75;
    _velY = _jumpVelocity;

    // Plataforma inicial debajo de la mascota
    _platforms.add(_Platform(
      Offset(size.x / 2 - _platformWidth / 2, size.y * 0.85),
      _platformWidth,
    ));

    // Plataformas iniciales repartidas hacia arriba
    var y = size.y * 0.85;
    while (y > -200) {
      y -= 70 + _rng.nextDouble() * 60;
      _platforms.add(_Platform(
        Offset(_rng.nextDouble() * (size.x - _platformWidth), y),
        _platformWidth,
      ));
    }

    _scoreText = TextComponent(
      text: 'Score: 0',
      position: Vector2(size.x / 2, 28),
      anchor: Anchor.topCenter,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontFamily: 'PressStart2P',
        ),
      ),
    );
    add(_scoreText);

    _instructionText = TextComponent(
      text: 'TAP izq/der para moverte',
      position: Vector2(size.x / 2, size.y * 0.45),
      anchor: Anchor.topCenter,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFF9E9E9E),
          fontSize: 10,
          fontFamily: 'PressStart2P',
        ),
      ),
    );
    add(_instructionText);
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (gameState == SkyJumpState.waiting) {
      gameState = SkyJumpState.playing;
      _instructionText.removeFromParent();
    }
    if (gameState != SkyJumpState.playing) return;
    _horizontalInput = event.localPosition.x < size.x / 2 ? -1 : 1;
  }

  @override
  void onTapUp(TapUpEvent event) {
    _horizontalInput = 0;
  }

  @override
  void onTapCancel(TapCancelEvent event) {
    _horizontalInput = 0;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (gameState != SkyJumpState.playing) return;

    // Movimiento horizontal con wrap (sale por un lado, aparece por el otro)
    petX += _horizontalInput * _horizontalSpeed * dt;
    if (petX < -_petSize / 2) petX = size.x + _petSize / 2;
    if (petX > size.x + _petSize / 2) petX = -_petSize / 2;

    // Física vertical
    _velY += _gravity * dt;
    petY += _velY * dt;

    // Colisión: solo si va cayendo (velY > 0)
    if (_velY > 0) {
      for (final p in _platforms) {
        final inX = petX + _petSize / 2 > p.position.dx &&
            petX - _petSize / 2 < p.position.dx + p.width;
        final crossing = petY + _petSize / 2 >= p.position.dy &&
            petY + _petSize / 2 <= p.position.dy + _platformHeight + 6;
        if (inX && crossing) {
          _velY = _jumpVelocity;
          break;
        }
      }
    }

    // Mover cámara hacia arriba si la mascota sube por encima de 40% de pantalla
    final screenY = petY - _cameraOffset;
    final cameraThreshold = size.y * 0.4;
    if (screenY < cameraThreshold) {
      final delta = cameraThreshold - screenY;
      _cameraOffset -= delta;
      score = max(score, (-_cameraOffset / 10).floor());
      _scoreText.text = 'Score: $score';
    }

    // Reciclar plataformas que quedan por debajo del viewport y generar
    // nuevas arriba para mantener densidad
    _platforms.removeWhere((p) {
      final screenPosY = p.position.dy - _cameraOffset;
      return screenPosY > size.y + 40;
    });
    final highest =
        _platforms.fold<double>(0, (acc, p) => min(acc, p.position.dy));
    while (highest - _cameraOffset > -200) {
      // genera plataformas hasta llenar arriba
      final newY = (_platforms.isEmpty ? petY : highest) -
          (70 + _rng.nextDouble() * 60);
      _platforms.add(_Platform(
        Offset(_rng.nextDouble() * (size.x - _platformWidth), newY),
        _platformWidth,
      ));
      if (newY < highest) break; // safety
    }

    // Game over si la mascota cae por debajo del viewport
    if (petY - _cameraOffset > size.y + 60) _gameOver();
  }

  void _gameOver() {
    if (gameState == SkyJumpState.gameOver) return;
    gameState = SkyJumpState.gameOver;
    onGameOver(score);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    _drawPlatforms(canvas);
    _drawPet(canvas);
  }

  void _drawPlatforms(Canvas canvas) {
    final paint = Paint()..color = const Color(0xFF4D96FF);
    for (final p in _platforms) {
      final rect = Rect.fromLTWH(
        p.position.dx,
        p.position.dy - _cameraOffset,
        p.width,
        _platformHeight,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(4)),
        paint,
      );
    }
  }

  void _drawPet(Canvas canvas) {
    final screenY = petY - _cameraOffset;
    final center = Offset(petX, screenY);

    final body = Paint()..color = const Color(0xFF6BCB77);
    canvas.drawCircle(center, _petSize / 2, body);

    // Ojos
    final eye = Paint()..color = Colors.white;
    canvas.drawCircle(center.translate(-6, -4), 4, eye);
    canvas.drawCircle(center.translate(6, -4), 4, eye);
    final pupil = Paint()..color = Colors.black;
    canvas.drawCircle(center.translate(-6, -3), 2, pupil);
    canvas.drawCircle(center.translate(6, -3), 2, pupil);

    // Boca según dirección de movimiento vertical
    final mouth = Paint()
      ..color = Colors.black
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    if (_velY < 0) {
      // subiendo: cara emocionada (O)
      canvas.drawCircle(center.translate(0, 6), 3, mouth);
    } else {
      // cayendo: sonrisa
      final path = Path()
        ..moveTo(center.dx - 5, center.dy + 5)
        ..quadraticBezierTo(
          center.dx,
          center.dy + 10,
          center.dx + 5,
          center.dy + 5,
        );
      canvas.drawPath(path, mouth);
    }
  }
}
