import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

enum ReactionTapState { waiting, playing, gameOver }

/// Aparece un punto en una posición aleatoria. El jugador debe tocarlo
/// antes de que se acabe el tiempo. Cada acierto baja el timeout y
/// aumenta el score. Un fallo (toque fuera del punto o timeout) termina
/// el juego.
class ReactionTapGame extends FlameGame with TapCallbacks {
  final void Function(int score) onGameOver;

  ReactionTapGame({required this.onGameOver});

  ReactionTapState gameState = ReactionTapState.waiting;
  int score = 0;

  final _rng = Random();

  static const _palette = <Color>[
    Color(0xFFE94560),
    Color(0xFF4D96FF),
    Color(0xFF6BCB77),
    Color(0xFFFFD93D),
  ];

  // Target actual
  Offset _targetCenter = Offset.zero;
  double _targetRadius = 38;
  late Color _targetColor;

  // Tiempo
  double _remaining = 0;
  double _roundTimeout = 1.6;

  late TextComponent _scoreText;
  late TextComponent _timerText;
  late TextComponent _instructionText;

  // Área válida para spawnear (deja espacio para los textos superiores)
  static const double _topPadding = 140;
  static const double _bottomPadding = 40;

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

    _timerText = TextComponent(
      text: '',
      position: Vector2(size.x / 2, 70),
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

    _targetColor = _palette[0];
  }

  void _startPlaying() {
    gameState = ReactionTapState.playing;
    _instructionText.removeFromParent();
    _nextRound();
  }

  void _nextRound() {
    final usableHeight = size.y - _topPadding - _bottomPadding;
    final usableWidth = size.x - _targetRadius * 2 - 16;
    final x = _targetRadius + 8 + _rng.nextDouble() * usableWidth;
    final y = _topPadding +
        _targetRadius +
        _rng.nextDouble() * (usableHeight - _targetRadius * 2);
    _targetCenter = Offset(x, y);
    _targetColor = _palette[_rng.nextInt(_palette.length)];
    _remaining = _roundTimeout;
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (gameState == ReactionTapState.waiting) {
      _startPlaying();
      return;
    }
    if (gameState != ReactionTapState.playing) return;

    final p = event.localPosition;
    final dx = p.x - _targetCenter.dx;
    final dy = p.y - _targetCenter.dy;
    final dist = sqrt(dx * dx + dy * dy);

    if (dist <= _targetRadius) {
      score++;
      _scoreText.text = 'Score: $score';
      // Acelerar: bajar timeout 5%, mínimo 0.55s; shrink del radio hasta 22
      _roundTimeout = (_roundTimeout * 0.95).clamp(0.55, 1.6);
      _targetRadius = (_targetRadius - 0.5).clamp(22, 38);
      _nextRound();
    } else {
      _gameOver();
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (gameState != ReactionTapState.playing) return;

    _remaining -= dt;
    _timerText.text =
        _remaining > 0 ? '${_remaining.toStringAsFixed(1)}s' : '';
    if (_remaining <= 0) _gameOver();
  }

  void _gameOver() {
    if (gameState == ReactionTapState.gameOver) return;
    gameState = ReactionTapState.gameOver;
    onGameOver(score);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (gameState != ReactionTapState.playing) return;
    _drawTarget(canvas);
  }

  void _drawTarget(Canvas canvas) {
    // Aro exterior que se encoge con el tiempo
    final progress = (_remaining / _roundTimeout).clamp(0.0, 1.0);
    final outerRadius = _targetRadius + 14 * progress;
    final ring = Paint()
      ..color = _targetColor.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(_targetCenter, outerRadius, ring);

    // Punto principal
    final fill = Paint()..color = _targetColor;
    canvas.drawCircle(_targetCenter, _targetRadius, fill);

    // Brillo interior
    final inner = Paint()..color = Colors.white.withValues(alpha: 0.25);
    canvas.drawCircle(
      _targetCenter.translate(-_targetRadius * 0.3, -_targetRadius * 0.3),
      _targetRadius * 0.35,
      inner,
    );
  }
}
