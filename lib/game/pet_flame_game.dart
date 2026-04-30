import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import '../features/pet/domain/entities/pet.dart';
import 'pet_component.dart';

/// Juego Flame embebido en la card central de GameScreen.
/// Renderiza el fondo de bioma y la mascota animada.
class PetFlameGame extends FlameGame {
  Pet _pet;

  PetComponent? _petComponent;
  SpriteComponent? _background;

  // Actualización pendiente si llega antes de que onLoad termine
  Pet? _pendingUpdate;

  PetFlameGame(this._pet);

  @override
  Color backgroundColor() => const Color(0xFF1A1A2E);

  @override
  Future<void> onLoad() async {
    await _loadBackground(_pet.biomeId);

    _petComponent = PetComponent(pet: _pet, displaySize: Vector2.all(96));
    _petComponent!.position = size / 2;
    _petComponent!.priority = 10;
    add(_petComponent!);

    // Aplicar actualización que llegó mientras cargábamos
    if (_pendingUpdate != null) {
      _applyUpdate(_pendingUpdate!);
      _pendingUpdate = null;
    }
  }

  // ─── API pública ─────────────────────────────────────────────────────────

  /// Llamar desde GameScreen (vía ref.listen) cuando el estado de la mascota cambia.
  void updatePet(Pet pet) {
    if (_petComponent == null) {
      _pendingUpdate = pet;
      return;
    }
    _applyUpdate(pet);
  }

  // ─── Privado ─────────────────────────────────────────────────────────────

  void _applyUpdate(Pet pet) {
    final biomeChanged = pet.biomeId != _pet.biomeId;
    _pet = pet;

    if (biomeChanged) _loadBackground(pet.biomeId);
    _petComponent?.updateFromPet(pet);
  }

  Future<void> _loadBackground(String biomeId) async {
    if (_background != null && _background!.isMounted) {
      remove(_background!);
    }

    final path = biomeId == 'desert'
        ? 'images/biome_desert.png'
        : 'images/biome_home.png';

    final bgImage = await images.load(path);
    _background = SpriteComponent(
      sprite: Sprite(bgImage),
      size: size,
      position: Vector2.zero(),
      priority: 0,
    );
    add(_background!);
  }
}
