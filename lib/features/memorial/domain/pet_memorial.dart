class PetMemorial {
  final String id;
  final String petName;
  final String mutationName;
  final String causeOfDeath;
  final int daysAlive;
  final DateTime diedAt;

  const PetMemorial({
    required this.id,
    required this.petName,
    required this.mutationName,
    required this.causeOfDeath,
    required this.daysAlive,
    required this.diedAt,
  });
}
