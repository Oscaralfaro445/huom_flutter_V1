enum PetStage { egg, baby, adult, elder }

enum PetState { happy, stressed, sick, dead }

enum PetMutation {
  slimeBit,
  cactusRex,
  aquaSlime,
  thunderLeaf,
  blossom,
  shadowBone,
  glitchPet,
}

class PetStats {
  final double hunger;
  final double mood;
  final double play;
  final double sleep;
  final double health;

  const PetStats({
    this.hunger = 70,
    this.mood = 70,
    this.play = 70,
    this.sleep = 70,
    this.health = 100,
  });

  PetStats copyWith({
    double? hunger,
    double? mood,
    double? play,
    double? sleep,
    double? health,
  }) {
    return PetStats(
      hunger: (hunger ?? this.hunger).clamp(0, 100),
      mood: (mood ?? this.mood).clamp(0, 100),
      play: (play ?? this.play).clamp(0, 100),
      sleep: (sleep ?? this.sleep).clamp(0, 100),
      health: (health ?? this.health).clamp(0, 100),
    );
  }

  // Devuelve true si algún stat está en nivel crítico
  bool get isCritical => hunger < 25 || sleep < 15 || health < 20;

  // Promedio de todos los stats (útil para evaluar mutaciones)
  double get average => (hunger + mood + play + sleep + health) / 5;
}

class Pet {
  final String id;
  final String name;
  final PetStage stage;
  final PetState state;
  final PetStats stats;
  final PetMutation mutation;
  final DateTime lastInteraction;
  final DateTime createdAt;
  final int daysAlive;
  final String biomeId;

  const Pet({
    required this.id,
    required this.name,
    this.stage = PetStage.egg,
    this.state = PetState.happy,
    required this.stats,
    this.mutation = PetMutation.slimeBit,
    required this.lastInteraction,
    required this.createdAt,
    this.daysAlive = 0,
    this.biomeId = 'home',
  });

  Pet copyWith({
    String? name,
    PetStage? stage,
    PetState? state,
    PetStats? stats,
    PetMutation? mutation,
    DateTime? lastInteraction,
    int? daysAlive,
    String? biomeId,
  }) {
    return Pet(
      id: id,
      createdAt: createdAt,
      name: name ?? this.name,
      stage: stage ?? this.stage,
      state: state ?? this.state,
      stats: stats ?? this.stats,
      mutation: mutation ?? this.mutation,
      lastInteraction: lastInteraction ?? this.lastInteraction,
      daysAlive: daysAlive ?? this.daysAlive,
      biomeId: biomeId ?? this.biomeId,
    );
  }
}
