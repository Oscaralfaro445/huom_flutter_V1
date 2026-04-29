import '../entities/pet.dart';

abstract class PetRepository {
  /// Obtiene la mascota activa. Retorna null si no existe ninguna.
  Future<Pet?> getActivePet();

  /// Guarda o actualiza la mascota.
  Future<void> savePet(Pet pet);

  /// Elimina la mascota activa (al morir y elegir nueva).
  Future<void> deleteActivePet();

  /// Escucha cambios en la mascota en tiempo real.
  Stream<Pet?> watchActivePet();
}
