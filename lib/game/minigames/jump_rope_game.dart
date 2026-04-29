import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

enum JumpRopeState { waiting, playing, gameOver }

class JumpRopeGame extends FlameGame with TapCallbacks {
  // Callback cuando termina el juego
  final void Function(int score) onGameOver;

  JumpRopeGame({required this.onGameOver});

  // Estado
  JumpRopeState gameState = JumpRopeState.waiting;
  int score = 0;
  double ropeSpeed = 200;
  double ropeAngle = 0;
  bool isJumping = false;
  double jumpHeight = 0;
  double jumpVelocity = 0;
  double timeSinceLastJump = 0;

  // Posiciones base
  late double groundY;
  late double petX;
  late double petY;

  // Componentes de texto
  late TextComponent scoreText;
  late TextComponent instructionText;

  @override
  Color backgroundColor() => const Color(0xFF1A1A2E);

  @override
  Future<void> onLoad() async {
    groundY = size.y * 0.65;
    petX = size.x / 2;
    petY = groundY;

    // Texto de score
    scoreText = TextComponent(
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
    add(scoreText);

    // Instrucción inicial
    instructionText = TextComponent(
      text: 'TAP para saltar',
      position: Vector2(size.x / 2, size.y * 0.82),
      anchor: Anchor.topCenter,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFF9E9E9E),
          fontSize: 12,
          fontFamily: 'PressStart2P',
        ),
      ),
    );
    add(instructionText);
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (gameState == JumpRopeState.waiting) {
      gameState = JumpRopeState.playing;
      instructionText.text = '';
    }

    if (gameState == JumpRopeState.playing && !isJumping) {
      isJumping = true;
      jumpVelocity = -420;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (gameState != JumpRopeState.playing) return;

    // Actualizar velocidad de cuerda progresivamente
    ropeSpeed += dt * 8;

    // Actualizar ángulo de la cuerda
    ropeAngle += ropeSpeed * dt * 0.05;
    if (ropeAngle > 2 * 3.14159) ropeAngle -= 2 * 3.14159;

    // Física del salto
    if (isJumping) {
      jumpVelocity += 900 * dt;
      jumpHeight += jumpVelocity * dt;

      if (jumpHeight >= 0) {
        jumpHeight = 0;
        jumpVelocity = 0;
        isJumping = false;
      }
    }

    // Posición actual de la mascota
    petY = groundY + jumpHeight;

    // Detectar colisión con la cuerda
    final petOnGround = jumpHeight >= -20;

    if (petOnGround && _isRopeAtGround()) {
      timeSinceLastJump += dt;
      if (timeSinceLastJump > 0.1) {
        _gameOver();
        return;
      }
    } else {
      timeSinceLastJump = 0;
    }

    // Sumar punto por cada vuelta completa
    final prevAngle = ropeAngle - ropeSpeed * dt * 0.05;
    if (prevAngle < 3.14159 && ropeAngle >= 3.14159) {
      score++;
      scoreText.text = 'Score: $score';
    }
  }

  bool _isRopeAtGround() {
    final normalized = ropeAngle % (2 * 3.14159);
    return normalized > 2.8 || normalized < 0.3;
  }

  void _gameOver() {
    if (gameState == JumpRopeState.gameOver) return;
    gameState = JumpRopeState.gameOver;
    onGameOver(score);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    _drawBackground(canvas);
    _drawRope(canvas);
    _drawPet(canvas);
  }

  void _drawBackground(Canvas canvas) {
    // Suelo
    final groundPaint = Paint()
      ..color = const Color(0xFF0F3460)
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(0, groundY + 10, size.x, size.y - groundY),
      groundPaint,
    );

    // Línea del suelo
    final linePaint = Paint()
      ..color = const Color(0xFF4D96FF)
      ..strokeWidth = 2;
    canvas.drawLine(
      Offset(0, groundY + 10),
      Offset(size.x, groundY + 10),
      linePaint,
    );
  }

  void _drawRope(Canvas canvas) {
    if (gameState == JumpRopeState.waiting) return;

    final ropePaint = Paint()
      ..color = const Color(0xFFFFD93D)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final centerX = petX;
    final centerY = groundY + 10;
    const ropeLength = 80.0;

    final endX = centerX + ropeLength * _getCos();
    final endY = centerY + ropeLength * _getSin();
    final startX = centerX - ropeLength * _getCos();
    final startY = centerY - ropeLength * _getSin();

    final path = Path();
    path.moveTo(startX, startY);
    path.quadraticBezierTo(centerX, endY - 20, endX, startY);
    canvas.drawPath(path, ropePaint);
  }

  double _getCos() => _cos(ropeAngle);
  double _getSin() => _sin(ropeAngle) * 0.4;

  double _cos(double angle) {
    // Aproximación simple
    return (angle % (2 * 3.14159) < 3.14159) ? 1.0 : -1.0;
  }

  double _sin(double angle) {
    final normalized = angle % (2 * 3.14159);
    if (normalized < 3.14159) {
      return normalized / 3.14159;
    }
    return 1.0 - (normalized - 3.14159) / 3.14159;
  }

  void _drawPet(Canvas canvas) {
    final petPaint = Paint()
      ..color = const Color(0xFF4CAF50)
      ..style = PaintingStyle.fill;

    // Cuerpo del slime
    canvas.drawCircle(
      Offset(petX, petY),
      28,
      petPaint,
    );

    // Sombra cuando está en el suelo
    if (!isJumping) {
      final shadowPaint = Paint()..color = Colors.black.withValues(alpha: 0.3);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(petX, groundY + 14),
          width: 50,
          height: 10,
        ),
        shadowPaint,
      );
    }

    // Ojos
    final eyePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(petX - 9, petY - 6), 6, eyePaint);
    canvas.drawCircle(Offset(petX + 9, petY - 6), 6, eyePaint);

    // Pupilas
    final pupilPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(petX - 9, petY - 5), 3, pupilPaint);
    canvas.drawCircle(Offset(petX + 9, petY - 5), 3, pupilPaint);

    // Sonrisa (cuando salta se pone cara de susto)
    final mouthPaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    if (isJumping) {
      canvas.drawCircle(Offset(petX, petY + 8), 5, mouthPaint);
    } else {
      final mouthPath = Path();
      mouthPath.moveTo(petX - 8, petY + 6);
      mouthPath.quadraticBezierTo(petX, petY + 14, petX + 8, petY + 6);
      canvas.drawPath(mouthPath, mouthPaint);
    }
  }
}
