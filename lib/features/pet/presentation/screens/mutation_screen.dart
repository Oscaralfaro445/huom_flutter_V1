import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/particles.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/pet.dart';

// ─── Flame game interno ──────────────────────────────────────────────────────

class _MutationFlameGame extends FlameGame {
  final PetMutation mutation;

  static const _kRevealOverlay = 'reveal';

  _MutationFlameGame(this.mutation);

  double _elapsed = 0;
  _FlashOverlay? _flash;
  SpriteAnimationComponent? _pet;
  bool _petVisible = false;
  bool _revealTriggered = false;

  @override
  Color backgroundColor() => const Color(0xFF0A0A1A);

  @override
  Future<void> onLoad() async {
    // Flash blanco: cubre toda la pantalla y desvanece en ~0.8 s
    _flash = _FlashOverlay(gameSize: size);
    add(_flash!);

    // Mascota: cargamos mientras el flash desvanece
    Future.delayed(const Duration(milliseconds: 700), _showPet);
  }

  Future<void> _showPet() async {
    final image = await images.load(mutation.spritePath);
    final sheet = SpriteSheet(image: image, srcSize: Vector2.all(48));
    final anim = sheet.createAnimation(row: 0, stepTime: 0.2, to: 4);

    _pet = SpriteAnimationComponent(
      animation: anim,
      size: Vector2.all(96),
      position: size / 2,
      anchor: Anchor.center,
      scale: Vector2.zero(), // escala desde 0
      priority: 10,
    );
    add(_pet!);
    _petVisible = true;

    await _spawnParticles();
  }

  Future<void> _spawnParticles() async {
    final pImage = await images.load('sprites/particle.png');
    final pSprite = Sprite(pImage);
    final rng = Random();

    add(ParticleSystemComponent(
      position: size / 2,
      priority: 20,
      particle: Particle.generate(
        count: 40,
        lifespan: 1.8,
        generator: (i) {
          final angle = rng.nextDouble() * 2 * pi;
          final speed = 70 + rng.nextDouble() * 140;
          return AcceleratedParticle(
            acceleration: Vector2(0, 70),
            speed: Vector2(cos(angle) * speed, sin(angle) * speed - 50),
            child: SpriteParticle(
              sprite: pSprite,
              size: Vector2.all(8),
            ),
          );
        },
      ),
    ));
  }

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;

    // Scale-up de la mascota entre t=0.7 y t=1.4 s
    if (_petVisible && _pet != null) {
      final t = ((_elapsed - 0.7) / 0.7).clamp(0.0, 1.0);
      _pet!.scale = Vector2.all(t);
    }

    // Mostrar overlay Flutter con nombre + botón a partir de t=2.5 s
    if (_elapsed >= 2.5 && !_revealTriggered) {
      _revealTriggered = true;
      overlays.add(_kRevealOverlay);
    }
  }
}

// ─── Componente de flash ─────────────────────────────────────────────────────

class _FlashOverlay extends PositionComponent {
  double _opacity = 1.0;

  _FlashOverlay({required Vector2 gameSize})
      : super(size: gameSize, priority: 100);

  @override
  void update(double dt) {
    super.update(dt);
    _opacity = (_opacity - dt * 1.4).clamp(0.0, 1.0);
  }

  @override
  void render(Canvas canvas) {
    if (_opacity <= 0) return;
    canvas.drawRect(
      size.toRect(),
      Paint()..color = Color.fromRGBO(255, 255, 255, _opacity),
    );
  }
}

// ─── Pantalla Flutter ────────────────────────────────────────────────────────

class MutationScreen extends StatefulWidget {
  final PetMutation mutation;

  const MutationScreen({super.key, required this.mutation});

  @override
  State<MutationScreen> createState() => _MutationScreenState();
}

class _MutationScreenState extends State<MutationScreen> {
  late final _MutationFlameGame _game;

  @override
  void initState() {
    super.initState();
    _game = _MutationFlameGame(widget.mutation);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      body: GameWidget(
        game: _game,
        overlayBuilderMap: {
          _MutationFlameGame._kRevealOverlay: (_, __) => _buildReveal(),
        },
      ),
    );
  }

  Widget _buildReveal() {
    return SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 60),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '¡NUEVA FORMA!',
                style: TextStyle(
                  fontFamily: 'PressStart2P',
                  fontSize: 10,
                  color: AppColors.textSecondary,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                widget.mutation.displayName.toUpperCase(),
                style: const TextStyle(
                  fontFamily: 'PressStart2P',
                  fontSize: 18,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 32),
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.primary, width: 2),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 32, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'CONTINUAR',
                  style: TextStyle(
                    fontFamily: 'PressStart2P',
                    fontSize: 10,
                    color: AppColors.primary,
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
