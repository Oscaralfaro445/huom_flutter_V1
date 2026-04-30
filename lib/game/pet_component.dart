import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/sprite.dart';
import '../../features/pet/domain/entities/pet.dart';

/// Renderiza la mascota con animaciones reales cargadas desde el sprite sheet
/// en assets/sprites/. El sheet tiene formato grid 4×4 de 48×48 px por celda:
///   fila 0 → idle  (4 frames)
///   fila 1 → eat   (4 frames)
///   fila 2 → sleep (4 frames)
///   fila 3 → sad   (3 frames)
class PetComponent extends SpriteAnimationComponent
    with HasGameReference<FlameGame> {
  PetState _petState;
  PetStage _stage;
  PetMutation _mutation;

  final Map<String, SpriteAnimation> _animations = {};

  PetComponent({
    required Pet pet,
    required Vector2 displaySize,
  })  : _petState = pet.state,
        _stage = pet.stage,
        _mutation = pet.mutation,
        super(size: displaySize, anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    await _loadAnimations();
    animation = _selectAnimation();
  }

  // ─── Carga ───────────────────────────────────────────────────────────────

  Future<void> _loadAnimations() async {
    _animations.clear();

    if (_stage == PetStage.egg) {
      // egg.png: 96×48px — 2 frames en una sola fila
      final image = await game.images.load('sprites/egg.png');
      final anim = SpriteAnimation.fromFrameData(
        image,
        SpriteAnimationData.sequenced(
          amount: 2,
          stepTime: 0.6,
          textureSize: Vector2(48, 48),
        ),
      );
      _animations['idle'] = anim;
      _animations['eat'] = anim;
      _animations['sleep'] = anim;
      _animations['sad'] = anim;
      return;
    }

    // Mutaciones: sprite sheet 192×192px, grid 4 cols × 4 rows
    final image = await game.images.load(_mutation.spritePath);
    final sheet = SpriteSheet(image: image, srcSize: Vector2.all(48));

    _animations['idle'] = sheet.createAnimation(row: 0, stepTime: 0.20, to: 4);
    _animations['eat'] = sheet.createAnimation(row: 1, stepTime: 0.15, to: 4);
    _animations['sleep'] = sheet.createAnimation(row: 2, stepTime: 0.30, to: 4);
    _animations['sad'] = sheet.createAnimation(row: 3, stepTime: 0.25, to: 3);
  }

  SpriteAnimation _selectAnimation() => switch (_petState) {
        PetState.happy => _animations['idle']!,
        PetState.stressed ||
        PetState.sick ||
        PetState.dead =>
          _animations['sad']!,
      };

  // ─── Actualizaciones desde el exterior ──────────────────────────────────

  /// Llamar cuando el estado de Riverpod cambia (desde PetFlameGame).
  Future<void> updateFromPet(Pet pet) async {
    final needsReload = pet.mutation != _mutation || pet.stage != _stage;
    _petState = pet.state;
    _stage = pet.stage;
    _mutation = pet.mutation;

    if (needsReload) await _loadAnimations();
    if (isMounted) animation = _selectAnimation();
  }

  /// Activa la animación de comer durante [duration] y luego vuelve al estado normal.
  void playEatAnimation({Duration duration = const Duration(milliseconds: 900)}) {
    if (!_animations.containsKey('eat')) return;
    animation = _animations['eat'];
    Future.delayed(duration, () {
      if (isMounted) animation = _selectAnimation();
    });
  }

  /// Activa la animación de dormir (para el botón sleep).
  void playSleepAnimation() {
    if (_animations.containsKey('sleep')) animation = _animations['sleep'];
  }

  /// Vuelve a la animación por defecto según el estado actual.
  void resetToDefault() {
    if (isMounted) animation = _selectAnimation();
  }
}
