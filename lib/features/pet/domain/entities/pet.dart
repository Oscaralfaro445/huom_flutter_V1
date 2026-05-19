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

enum ConditionType {
  cold,          // Resfriado
  flu,           // Gripe
  fever,         // Fiebre
  minorInjury,   // Lesión leve
  seriousInjury, // Lesión grave
  exhaustion,    // Agotamiento
}

class PetCondition {
  final ConditionType type;
  final DateTime contractedAt;

  const PetCondition({required this.type, required this.contractedAt});

  String get displayName => switch (type) {
        ConditionType.cold => 'Resfriado',
        ConditionType.flu => 'Gripe',
        ConditionType.fever => 'Fiebre',
        ConditionType.minorInjury => 'Lesión leve',
        ConditionType.seriousInjury => 'Lesión grave',
        ConditionType.exhaustion => 'Agotamiento',
      };

  String get icon => switch (type) {
        ConditionType.cold => '🤧',
        ConditionType.flu => '🤒',
        ConditionType.fever => '🥵',
        ConditionType.minorInjury => '🩹',
        ConditionType.seriousInjury => '🤕',
        ConditionType.exhaustion => '😵',
      };
}

class PetStats {
  final double hunger;
  final double mood;
  final double play;
  final double sleep;
  final double health;
  final double cleanliness;

  const PetStats({
    this.hunger = 70,
    this.mood = 70,
    this.play = 70,
    this.sleep = 70,
    this.health = 100,
    this.cleanliness = 100,
  });

  PetStats copyWith({
    double? hunger,
    double? mood,
    double? play,
    double? sleep,
    double? health,
    double? cleanliness,
  }) {
    return PetStats(
      hunger: (hunger ?? this.hunger).clamp(0, 100),
      mood: (mood ?? this.mood).clamp(0, 100),
      play: (play ?? this.play).clamp(0, 100),
      sleep: (sleep ?? this.sleep).clamp(0, 100),
      health: (health ?? this.health).clamp(0, 100),
      cleanliness: (cleanliness ?? this.cleanliness).clamp(0, 100),
    );
  }

  bool get isCritical =>
      hunger < 25 || sleep < 15 || health < 20 || cleanliness < 20;

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
  final List<PetCondition> conditions;

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
    this.conditions = const [],
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
    List<PetCondition>? conditions,
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
      conditions: conditions ?? this.conditions,
    );
  }

  bool get hasCondition => conditions.isNotEmpty;

  bool get isInjured => conditions.any(
        (c) =>
            c.type == ConditionType.minorInjury ||
            c.type == ConditionType.seriousInjury,
      );

  bool get isIll => conditions.any(
        (c) =>
            c.type == ConditionType.cold ||
            c.type == ConditionType.flu ||
            c.type == ConditionType.fever,
      );

  bool get isExhausted =>
      conditions.any((c) => c.type == ConditionType.exhaustion);
}

extension PetMutationAssets on PetMutation {
  String get spritePath => switch (this) {
        PetMutation.slimeBit => 'sprites/slimebit.png',
        PetMutation.cactusRex => 'sprites/cactusrex.png',
        PetMutation.aquaSlime => 'sprites/aquaslime.png',
        PetMutation.thunderLeaf => 'sprites/thunderleaf.png',
        PetMutation.blossom => 'sprites/blossom.png',
        PetMutation.shadowBone => 'sprites/shadowbone.png',
        PetMutation.glitchPet => 'sprites/glitchpet.png',
      };

  String get displayName => switch (this) {
        PetMutation.slimeBit => 'Slime Bit',
        PetMutation.cactusRex => 'Cactus Rex',
        PetMutation.aquaSlime => 'Aqua Slime',
        PetMutation.thunderLeaf => 'Thunder Leaf',
        PetMutation.blossom => 'Blossom',
        PetMutation.shadowBone => 'Shadow Bone',
        PetMutation.glitchPet => 'Glitch Pet',
      };
}
