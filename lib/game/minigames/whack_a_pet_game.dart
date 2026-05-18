import 'dart:math';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum WhackAPetState { waiting, playing, gameOver }

class _Hole {
  bool active = false;
  double remaining = 0;
}

/// Grid 3x3 de huecos. La mascota aparece en un hueco aleatorio y
/// debe ser tocada antes de que se esconda. Cada acierto suma 1 punto
/// y acelera el ritmo. Cada miss (toque vacío o hueco que se esconde
/// sin tocar) suma una falla; 3 fallas terminan el juego.
class WhackAPetGame extends FlameGame with TapCallbacks {
  final void Function(int score) onGameOver;
  final String petSpritePath;

  WhackAPetGame({
    required this.onGameOver,
    required this.petSpritePath,
  });

  WhackAPetState gameState = WhackAPetState.waiting;
  int score = 0;
  int misses = 0;
  static const int _maxMisses = 3;

  final _rng = Random();
  late List<_Hole> _holes;

  ui.Image? _petImage;
  static const _frameSize = 48.0;

  double _spawnTimer = 0;
  double _spawnInterval = 1.1;
  double _showTime = 1.0;

  late TextComponent _scoreText;
  late TextComponent _missesText;
  late TextComponent _instructionText;

  // Layout del grid
  static const _cols = 3;
  static const _rows = 3;
  static const _topPadding = 130.0;
  static const _bottomPadding = 40.0;
  static const _hPadding = 20.0;

  @override
  Color backgroundColor() => const Color(0xFF1A1A2E);

  @override
  Future<void> onLoad() async {
    _holes = List.generate(_cols * _rows, (_) => _Hole());

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

    _missesText = TextComponent(
      text: 'Fallas: 0/$_maxMisses',
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
    add(_missesText);

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

  void _startPlaying() {
    gameState = WhackAPetState.playing;
    _instructionText.removeFromParent();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (gameState != WhackAPetState.playing) return;

    // Actualizar mascotas activas
    for (final h in _holes) {
      if (!h.active) continue;
      h.remaining -= dt;
      if (h.remaining <= 0) {
        h.active = false;
        _registerMiss();
      }
    }

    // Spawner
    _spawnTimer += dt;
    if (_spawnTimer >= _spawnInterval) {
      _spawnTimer = 0;
      _spawnPet();
    }
  }

  void _spawnPet() {
    // Buscar huecos vacíos
    final empty = <int>[];
    for (var i = 0; i < _holes.length; i++) {
      if (!_holes[i].active) empty.add(i);
    }
    if (empty.isEmpty) return;
    final idx = empty[_rng.nextInt(empty.length)];
    _holes[idx].active = true;
    _holes[idx].remaining = _showTime;
  }

  void _registerMiss() {
    if (gameState != WhackAPetState.playing) return;
    misses++;
    _missesText.text = 'Fallas: $misses/$_maxMisses';
    if (misses >= _maxMisses) _gameOver();
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (gameState == WhackAPetState.waiting) {
      _startPlaying();
      return;
    }
    if (gameState != WhackAPetState.playing) return;

    final p = event.localPosition;
    final hitIdx = _holeAt(p.x, p.y);
    if (hitIdx == null) return;

    final hole = _holes[hitIdx];
    if (hole.active) {
      hole.active = false;
      score++;
      _scoreText.text = 'Score: $score';
      _ramp();
    } else {
      _registerMiss();
    }
  }

  int? _holeAt(double x, double y) {
    final gridRect = _gridRect();
    if (!gridRect.contains(Offset(x, y))) return null;
    final cellW = gridRect.width / _cols;
    final cellH = gridRect.height / _rows;
    final col = ((x - gridRect.left) / cellW).floor().clamp(0, _cols - 1);
    final row = ((y - gridRect.top) / cellH).floor().clamp(0, _rows - 1);
    return row * _cols + col;
  }

  void _ramp() {
    // Cada acierto acelera
    _spawnInterval = (_spawnInterval * 0.95).clamp(0.55, 1.1);
    _showTime = (_showTime * 0.97).clamp(0.55, 1.0);
  }

  void _gameOver() {
    if (gameState == WhackAPetState.gameOver) return;
    gameState = WhackAPetState.gameOver;
    onGameOver(score);
  }

  Rect _gridRect() {
    const left = _hPadding;
    final right = size.x - _hPadding;
    const top = _topPadding;
    final bottom = size.y - _bottomPadding;
    return Rect.fromLTRB(left, top, right, bottom);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (gameState == WhackAPetState.waiting) return;
    _drawGrid(canvas);
  }

  void _drawGrid(Canvas canvas) {
    final grid = _gridRect();
    final cellW = grid.width / _cols;
    final cellH = grid.height / _rows;
    const padding = 8.0;
    final holePaint = Paint()..color = const Color(0xFF0F3460);
    final border = Paint()
      ..color = const Color(0xFF4D96FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (var r = 0; r < _rows; r++) {
      for (var c = 0; c < _cols; c++) {
        final idx = r * _cols + c;
        final rect = Rect.fromLTWH(
          grid.left + c * cellW + padding,
          grid.top + r * cellH + padding,
          cellW - padding * 2,
          cellH - padding * 2,
        );

        // Fondo del hueco
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(10)),
          holePaint,
        );

        // Borde
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(10)),
          border,
        );

        // Pet si está activo
        if (_holes[idx].active) {
          _drawPetIn(canvas, rect);
        }
      }
    }
  }

  void _drawPetIn(Canvas canvas, Rect rect) {
    final image = _petImage;
    final dim = min(rect.width, rect.height) * 0.85;
    final dst = Rect.fromCenter(
      center: rect.center,
      width: dim,
      height: dim,
    );
    if (image != null) {
      canvas.drawImageRect(
        image,
        const Rect.fromLTWH(0, 0, _frameSize, _frameSize),
        dst,
        Paint()..filterQuality = FilterQuality.none,
      );
    } else {
      canvas.drawCircle(
        rect.center,
        dim / 2,
        Paint()..color = const Color(0xFFE94560),
      );
    }
  }
}
