import 'dart:math';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../../features/pet/domain/entities/pet.dart';

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
  final Pet pet;

  SkyJumpGame({required this.onGameOver, required this.pet});

  SkyJumpState gameState = SkyJumpState.waiting;
  int score = 0;
  double _cameraOffset = 0; // cuánto ha subido el mundo en total

  // Mascota
  late double petX;
  late double petY; // coordenada en el "mundo" (no en pantalla)
  double _velY = 0;
  static const _gravity = 1200.0;
  static const _jumpVelocity = -620.0;
  static const _petSize = 48.0;
  static const _horizontalSpeed = 220.0;

  // Sprite de la mascota (cargado en onLoad)
  ui.Image? _petImage;
  double _animTime = 0;
  static const _frameSize = 48.0;
  static const _frameStep = 0.20; // segundos por frame (igual que PetComponent)

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
  Color backgroundColor() => const Color(0xFF87CEEB);

  @override
  Future<void> onLoad() async {
    // Carga el sprite sheet de la mascota (etapa egg usa sprite distinto)
    images.prefix = 'assets/';
    final path = pet.stage == PetStage.egg
        ? 'sprites/egg.png'
        : pet.mutation.spritePath;
    _petImage = await images.load(path);

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
    _animTime += dt;
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
    _drawSky(canvas);
    _drawClouds(canvas);
    super.render(canvas);
    _drawPlatforms(canvas);
    _drawPet(canvas);
  }

  // ─── Fondo cielo ──────────────────────────────────────────────────────────

  void _drawSky(Canvas canvas) {
    final rect = Rect.fromLTWH(0, 0, size.x, size.y);
    const gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFF4FA8E0), // azul cielo
        Color(0xFF87CEEB), // celeste
        Color(0xFFD8F0FB), // casi blanco abajo
      ],
      stops: [0.0, 0.55, 1.0],
    );
    canvas.drawRect(rect, Paint()..shader = gradient.createShader(rect));

    // Sol arriba a la derecha
    final sunCenter = Offset(size.x - 50, 60);
    canvas.drawCircle(
      sunCenter,
      40,
      Paint()..color = const Color(0xFFFFE680).withValues(alpha: 0.45),
    );
    canvas.drawCircle(
      sunCenter,
      28,
      Paint()..color = const Color(0xFFFFD93D),
    );
  }

  // Posiciones base de nubes en el mundo (se repiten verticalmente).
  // Cada par es (xRatio, worldY).
  static const _cloudSlots = <(double, double)>[
    (0.10, 40),
    (0.65, 130),
    (0.30, 260),
    (0.85, 360),
    (0.05, 480),
    (0.55, 600),
  ];
  static const _cloudCycle = 720.0;

  void _drawClouds(Canvas canvas) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.85);
    // Parallax: las nubes se mueven al 35% del movimiento de cámara, dando
    // sensación de profundidad respecto a las plataformas.
    final parallax = _cameraOffset * 0.35;
    for (final (xRatio, baseY) in _cloudSlots) {
      final x = xRatio * size.x;
      // Wrap-around vertical: la nube vuelve a aparecer arriba al pasar abajo
      final raw = (baseY - parallax) % _cloudCycle;
      final yInCycle = raw < 0 ? raw + _cloudCycle : raw;
      // Mapea [0, _cloudCycle] sobre [-60, size.y + 60]
      final screenY = -60 + (yInCycle / _cloudCycle) * (size.y + 120);
      _drawCloud(canvas, Offset(x, screenY), paint);
    }
  }

  void _drawCloud(Canvas canvas, Offset c, Paint paint) {
    canvas.drawCircle(c, 22, paint);
    canvas.drawCircle(c.translate(-18, 6), 16, paint);
    canvas.drawCircle(c.translate(18, 6), 16, paint);
    canvas.drawCircle(c.translate(-6, -10), 14, paint);
    canvas.drawOval(
      Rect.fromCenter(center: c.translate(0, 10), width: 70, height: 20),
      paint,
    );
  }

  // ─── Plataformas ──────────────────────────────────────────────────────────

  void _drawPlatforms(Canvas canvas) {
    final body = Paint()..color = const Color(0xFFFFFFFF);
    final shadow = Paint()..color = const Color(0xFFB0D8E8);
    for (final p in _platforms) {
      final rect = Rect.fromLTWH(
        p.position.dx,
        p.position.dy - _cameraOffset,
        p.width,
        _platformHeight,
      );
      // Sombra inferior (efecto nubecita)
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          rect.translate(0, 3),
          const Radius.circular(6),
        ),
        shadow,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(6)),
        body,
      );
    }
  }

  // ─── Mascota ─────────────────────────────────────────────────────────────

  void _drawPet(Canvas canvas) {
    final img = _petImage;
    if (img == null) return;

    final screenY = petY - _cameraOffset;
    final isEgg = pet.stage == PetStage.egg;
    final framesInRow = isEgg ? 2 : 4;
    final frameIdx = ((_animTime / _frameStep).floor()) % framesInRow;

    final src = Rect.fromLTWH(
      frameIdx * _frameSize,
      0,
      _frameSize,
      _frameSize,
    );
    const renderSize = _petSize * 1.4;
    final dst = Rect.fromCenter(
      center: Offset(petX, screenY),
      width: renderSize,
      height: renderSize,
    );
    // Pixel art: sin filtro para mantener crujiente
    final paint = Paint()..filterQuality = FilterQuality.none;
    canvas.drawImageRect(img, src, dst, paint);
  }
}
