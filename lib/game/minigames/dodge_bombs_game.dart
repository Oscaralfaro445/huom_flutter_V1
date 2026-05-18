import 'dart:math';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum DodgeBombsState { waiting, playing, gameOver }

class _Bomb {
  static const double size = 28;
  Offset position;
  final double speed;
  _Bomb({required this.position, required this.speed});
}

/// La mascota está en la parte baja de la pantalla y se mueve izq/der
/// arrastrando. Caen bombas del cielo a velocidad creciente. Cada
/// bomba esquivada (que sale por debajo) suma 1 punto. Si una bomba
/// toca a la mascota, game over.
class DodgeBombsGame extends FlameGame with PanDetector, TapCallbacks {
  final void Function(int score) onGameOver;
  final String petSpritePath;

  DodgeBombsGame({
    required this.onGameOver,
    required this.petSpritePath,
  });

  DodgeBombsState gameState = DodgeBombsState.waiting;
  int score = 0;

  final _rng = Random();
  final _bombs = <_Bomb>[];

  // Mascota
  late double petCenterX;
  static const _petSize = 64.0;
  static const _petHitRadius = 26.0;

  ui.Image? _petImage;
  static const _frameSize = 48.0;

  // Spawner
  double _spawnTimer = 0;
  double _spawnInterval = 0.95;
  double _fallSpeed = 160;

  late TextComponent _scoreText;
  late TextComponent _instructionText;

  @override
  Color backgroundColor() => const Color(0xFF1A1A2E);

  @override
  Future<void> onLoad() async {
    petCenterX = size.x / 2;

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
      text: 'ARRASTRA para esquivar',
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

    await _loadPetImage();
  }

  Future<void> _loadPetImage() async {
    try {
      final data = await rootBundle.load('assets/$petSpritePath');
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      _petImage = frame.image;
    } catch (_) {
      _petImage = null;
    }
  }

  @override
  void onPanUpdate(DragUpdateInfo info) {
    if (gameState == DodgeBombsState.gameOver) return;
    if (gameState == DodgeBombsState.waiting) _startPlaying();
    petCenterX = (petCenterX + info.delta.global.x)
        .clamp(_petSize / 2, size.x - _petSize / 2);
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (gameState == DodgeBombsState.waiting) _startPlaying();
  }

  void _startPlaying() {
    gameState = DodgeBombsState.playing;
    _instructionText.removeFromParent();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (gameState != DodgeBombsState.playing) return;

    _spawnTimer += dt;
    if (_spawnTimer >= _spawnInterval) {
      _spawnTimer = 0;
      _spawn();
    }

    final petCenter = Offset(petCenterX, size.y * 0.84);

    for (final b in _bombs) {
      b.position = Offset(b.position.dx, b.position.dy + b.speed * dt);
    }

    // Detectar colisión con la mascota
    for (final b in _bombs) {
      final dx = b.position.dx - petCenter.dx;
      final dy = b.position.dy - petCenter.dy;
      final dist = sqrt(dx * dx + dy * dy);
      if (dist < _petHitRadius + _Bomb.size * 0.45) {
        _gameOver();
        return;
      }
    }

    // Bombas que salen por debajo: punto y eliminación
    _bombs.removeWhere((b) {
      if (b.position.dy > size.y + 32) {
        score++;
        _scoreText.text = 'Score: $score';
        _maybeLevelUp();
        return true;
      }
      return false;
    });
  }

  void _spawn() {
    final x = 24 + _rng.nextDouble() * (size.x - 48);
    _bombs.add(_Bomb(
      position: Offset(x, -32),
      speed: _fallSpeed + _rng.nextDouble() * 40,
    ));
  }

  void _maybeLevelUp() {
    if (score % 5 == 0) {
      _spawnInterval = (_spawnInterval * 0.92).clamp(0.4, 0.95);
      _fallSpeed = (_fallSpeed + 14).clamp(160, 360);
    }
  }

  void _gameOver() {
    if (gameState == DodgeBombsState.gameOver) return;
    gameState = DodgeBombsState.gameOver;
    onGameOver(score);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    _drawBackground(canvas);
    _drawBombs(canvas);
    _drawPet(canvas);
  }

  void _drawBackground(Canvas canvas) {
    final linePaint = Paint()
      ..color = const Color(0xFF0F3460)
      ..strokeWidth = 2;
    final groundY = size.y * 0.92;
    canvas.drawLine(
      Offset(0, groundY),
      Offset(size.x, groundY),
      linePaint,
    );
  }

  void _drawBombs(Canvas canvas) {
    for (final b in _bombs) {
      final tp = TextPainter(
        text: const TextSpan(
          text: '💣',
          style: TextStyle(fontSize: _Bomb.size),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset(b.position.dx - _Bomb.size / 2, b.position.dy - _Bomb.size / 2),
      );
    }
  }

  void _drawPet(Canvas canvas) {
    final center = Offset(petCenterX, size.y * 0.84);
    final image = _petImage;
    if (image != null) {
      final dst = Rect.fromCenter(
        center: center,
        width: _petSize,
        height: _petSize,
      );
      canvas.drawImageRect(
        image,
        const Rect.fromLTWH(0, 0, _frameSize, _frameSize),
        dst,
        Paint()..filterQuality = FilterQuality.none,
      );
    } else {
      canvas.drawCircle(
        center,
        _petSize / 2,
        Paint()..color = const Color(0xFFE94560),
      );
    }
  }
}
