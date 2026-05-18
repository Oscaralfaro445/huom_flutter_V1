import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

enum ColorTapState { waiting, playing, gameOver }

enum _Slot { topLeft, topRight, bottomLeft, bottomRight }

class _ColorOption {
  final String name;
  final Color color;
  const _ColorOption(this.name, this.color);
}

/// Aparece un color objetivo y el jugador debe tocar el cuadrante
/// con ese color antes de que se acabe el tiempo. Cada acierto
/// reduce el timeout y el primer error termina el juego.
class ColorTapGame extends FlameGame with TapCallbacks {
  final void Function(int score) onGameOver;

  ColorTapGame({required this.onGameOver});

  ColorTapState gameState = ColorTapState.waiting;
  int score = 0;

  final _rng = Random();

  static const _palette = <_ColorOption>[
    _ColorOption('ROJO', Color(0xFFE94560)),
    _ColorOption('AZUL', Color(0xFF4D96FF)),
    _ColorOption('VERDE', Color(0xFF6BCB77)),
    _ColorOption('AMARILLO', Color(0xFFFFD93D)),
  ];

  late Map<_Slot, _ColorOption> _slotColors;
  late _ColorOption _target;
  double _remaining = 0;
  double _roundTimeout = 2.0;

  late TextComponent _scoreText;
  late TextComponent _targetText;
  late TextComponent _timerText;
  late TextComponent _instructionText;

  @override
  Color backgroundColor() => const Color(0xFF1A1A2E);

  @override
  Future<void> onLoad() async {
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

    _targetText = TextComponent(
      text: '',
      position: Vector2(size.x / 2, 72),
      anchor: Anchor.topCenter,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontFamily: 'PressStart2P',
        ),
      ),
    );
    add(_targetText);

    _timerText = TextComponent(
      text: '',
      position: Vector2(size.x / 2, 110),
      anchor: Anchor.topCenter,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFF9E9E9E),
          fontSize: 10,
          fontFamily: 'PressStart2P',
        ),
      ),
    );
    add(_timerText);

    _instructionText = TextComponent(
      text: 'TAP para empezar',
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

  void _startPlaying() {
    gameState = ColorTapState.playing;
    _instructionText.removeFromParent();
    _nextRound();
  }

  void _nextRound() {
    // Shuffle palette en los 4 slots (sin repetir colores entre slots)
    final shuffled = [..._palette]..shuffle(_rng);
    _slotColors = {
      _Slot.topLeft: shuffled[0],
      _Slot.topRight: shuffled[1],
      _Slot.bottomLeft: shuffled[2],
      _Slot.bottomRight: shuffled[3],
    };
    _target = shuffled[_rng.nextInt(4)];
    _remaining = _roundTimeout;
    _targetText.text = _target.name;
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (gameState == ColorTapState.waiting) {
      _startPlaying();
      return;
    }
    if (gameState != ColorTapState.playing) return;

    final p = event.localPosition;
    final slot = _slotAt(p.x, p.y);
    if (slot == null) return;

    if (_slotColors[slot] == _target) {
      score++;
      _scoreText.text = 'Score: $score';
      // Acelerar: bajar timeout 5%, mínimo 0.6s
      _roundTimeout = (_roundTimeout * 0.95).clamp(0.6, 2.0);
      _nextRound();
    } else {
      _gameOver();
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (gameState != ColorTapState.playing) return;

    _remaining -= dt;
    _timerText.text = _remaining > 0
        ? '${_remaining.toStringAsFixed(1)}s'
        : '';
    if (_remaining <= 0) _gameOver();
  }

  _Slot? _slotAt(double x, double y) {
    if (y < size.y * 0.3) return null; // header
    final isTop = y < size.y * 0.65;
    final isLeft = x < size.x / 2;
    if (isTop && isLeft) return _Slot.topLeft;
    if (isTop && !isLeft) return _Slot.topRight;
    if (!isTop && isLeft) return _Slot.bottomLeft;
    return _Slot.bottomRight;
  }

  void _gameOver() {
    if (gameState == ColorTapState.gameOver) return;
    gameState = ColorTapState.gameOver;
    onGameOver(score);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (gameState == ColorTapState.waiting) return;
    _drawSlots(canvas);
  }

  void _drawSlots(Canvas canvas) {
    final top = size.y * 0.3;
    final mid = size.y * 0.65;
    final bot = size.y;
    final centerX = size.x / 2;

    _drawSlot(canvas, _Slot.topLeft, Rect.fromLTRB(0, top, centerX, mid));
    _drawSlot(canvas, _Slot.topRight, Rect.fromLTRB(centerX, top, size.x, mid));
    _drawSlot(canvas, _Slot.bottomLeft, Rect.fromLTRB(0, mid, centerX, bot));
    _drawSlot(canvas, _Slot.bottomRight, Rect.fromLTRB(centerX, mid, size.x, bot));
  }

  void _drawSlot(Canvas canvas, _Slot slot, Rect rect) {
    final color = _slotColors[slot]!.color;
    final paint = Paint()..color = color;
    canvas.drawRect(rect.deflate(6), paint);
  }
}
