import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

enum FoodDropState { waiting, playing, gameOver }

enum _FallingKind { good, bomb }

class _Falling {
  static const double size = 32;

  final _FallingKind kind;
  final String emoji;
  Offset position;
  final double speed;

  _Falling({
    required this.kind,
    required this.emoji,
    required this.position,
    required this.speed,
  });
}

/// Mueves un plato izq/der para atrapar comida que cae. Las bombas
/// terminan el juego. La velocidad aumenta cada 5 puntos.
class FoodDropGame extends FlameGame with PanDetector, TapCallbacks {
  final void Function(int score) onGameOver;

  FoodDropGame({required this.onGameOver});

  FoodDropState gameState = FoodDropState.waiting;
  int score = 0;

  final _rng = Random();
  final _falling = <_Falling>[];

  // Plato
  late double plateX;
  static const _plateWidth = 70.0;
  static const _plateHeight = 14.0;

  // Spawner
  double _spawnTimer = 0;
  double _spawnInterval = 1.1;
  double _fallSpeed = 130;

  late TextComponent _scoreText;
  late TextComponent _instructionText;

  static const _goodFoods = ['🍎', '🍔', '🍕', '🍩', '🍰', '🍓', '🥕', '🍌'];

  @override
  Color backgroundColor() => const Color(0xFF1A1A2E);

  @override
  Future<void> onLoad() async {
    plateX = size.x / 2;

    _scoreText = TextComponent(
      text: 'Score: 0',
      position: Vector2(size.x / 2, 40),
      anchor: Anchor.topCenter,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontFamily: 'PressStart2P',
        ),
      ),
    );
    add(_scoreText);

    _instructionText = TextComponent(
      text: 'ARRASTRA el plato',
      position: Vector2(size.x / 2, size.y * 0.5),
      anchor: Anchor.topCenter,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFF9E9E9E),
          fontSize: 11,
          fontFamily: 'PressStart2P',
        ),
      ),
    );
    add(_instructionText);
  }

  @override
  void onPanUpdate(DragUpdateInfo info) {
    if (gameState == FoodDropState.gameOver) return;
    if (gameState == FoodDropState.waiting) _startPlaying();
    plateX = (plateX + info.delta.global.x)
        .clamp(_plateWidth / 2, size.x - _plateWidth / 2);
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (gameState == FoodDropState.waiting) _startPlaying();
  }

  void _startPlaying() {
    gameState = FoodDropState.playing;
    _instructionText.removeFromParent();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (gameState != FoodDropState.playing) return;

    _spawnTimer += dt;
    if (_spawnTimer >= _spawnInterval) {
      _spawnTimer = 0;
      _spawn();
    }

    // 12% de chance que el item nuevo sea bomba (sube con dificultad)
    for (final f in _falling) {
      f.position = Offset(f.position.dx, f.position.dy + f.speed * dt);
    }

    // Colisiones con el plato
    final plateRect = _plateRect();
    _falling.removeWhere((f) {
      final hit = plateRect.contains(f.position);
      if (hit) {
        if (f.kind == _FallingKind.bomb) {
          _gameOver();
        } else {
          score++;
          _scoreText.text = 'Score: $score';
          _maybeLevelUp();
        }
      }
      return hit;
    });

    // Eliminar los que salieron de pantalla
    _falling.removeWhere((f) => f.position.dy > size.y + 32);
  }

  void _spawn() {
    final isBomb = _rng.nextDouble() < 0.12 + (score * 0.005).clamp(0, 0.18);
    final emoji = isBomb ? '💣' : _goodFoods[_rng.nextInt(_goodFoods.length)];
    final x = 24 + _rng.nextDouble() * (size.x - 48);
    _falling.add(_Falling(
      kind: isBomb ? _FallingKind.bomb : _FallingKind.good,
      emoji: emoji,
      position: Offset(x, -32),
      speed: _fallSpeed + _rng.nextDouble() * 30,
    ));
  }

  void _maybeLevelUp() {
    if (score % 5 == 0) {
      _spawnInterval = (_spawnInterval * 0.92).clamp(0.45, 1.1);
      _fallSpeed = (_fallSpeed + 12).clamp(130, 320);
    }
  }

  void _gameOver() {
    if (gameState == FoodDropState.gameOver) return;
    gameState = FoodDropState.gameOver;
    onGameOver(score);
  }

  Rect _plateRect() {
    return Rect.fromCenter(
      center: Offset(plateX, size.y * 0.82),
      width: _plateWidth,
      height: _plateHeight + 24, // hitbox un poco mayor que el dibujo
    );
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    _drawBackground(canvas);
    _drawFalling(canvas);
    _drawPlate(canvas);
  }

  void _drawBackground(Canvas canvas) {
    // Línea base
    final linePaint = Paint()
      ..color = const Color(0xFF0F3460)
      ..strokeWidth = 2;
    final groundY = size.y * 0.88;
    canvas.drawLine(
      Offset(0, groundY),
      Offset(size.x, groundY),
      linePaint,
    );
  }

  void _drawFalling(Canvas canvas) {
    for (final f in _falling) {
      final tp = TextPainter(
        text: TextSpan(
          text: f.emoji,
          style: const TextStyle(fontSize: _Falling.size),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset(f.position.dx - _Falling.size / 2, f.position.dy),
      );
    }
  }

  void _drawPlate(Canvas canvas) {
    final rect = Rect.fromCenter(
      center: Offset(plateX, size.y * 0.82),
      width: _plateWidth,
      height: _plateHeight,
    );
    final paint = Paint()..color = const Color(0xFFE94560);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(6)),
      paint,
    );
    // Stem central decorativo
    final stem = Rect.fromCenter(
      center: Offset(plateX, size.y * 0.82 + 12),
      width: 6,
      height: 16,
    );
    canvas.drawRect(stem, Paint()..color = const Color(0xFF9E9E9E));
  }
}
