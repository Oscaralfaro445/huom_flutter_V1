import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../features/memorial/domain/pet_memorial.dart';
import '../../features/pet/domain/entities/pet.dart';
import 'auth_service.dart';

enum CloudSyncStatus { idle, syncing, synced, error }

class CloudSaveData {
  final Pet? pet;
  final int coins;
  final List<PetMemorial> memorials;

  const CloudSaveData({
    required this.pet,
    required this.coins,
    required this.memorials,
  });
}

class CloudSaveService {
  final AuthService _authService;
  final _firestore = FirebaseFirestore.instance;

  final _statusController = StreamController<CloudSyncStatus>.broadcast();
  Stream<CloudSyncStatus> get onSyncStatus => _statusController.stream;

  CloudSaveService(this._authService);

  DocumentReference<Map<String, dynamic>>? get _userDoc {
    final uid = _authService.userId;
    if (uid == null) return null;
    return _firestore.collection('users').doc(uid);
  }

  void _emit(CloudSyncStatus status) {
    if (!_statusController.isClosed) _statusController.add(status);
  }

  // ─── Public fire-and-forget methods (called from repositories) ─────────────

  void savePet(Pet? pet) {
    final doc = _userDoc;
    if (doc == null) return;
    unawaited(_syncPet(doc, pet));
  }

  void saveCoins(int coins) {
    final doc = _userDoc;
    if (doc == null) return;
    unawaited(_syncCoins(doc, coins));
  }

  void saveMemorial(PetMemorial memorial) {
    final doc = _userDoc;
    if (doc == null) return;
    unawaited(_syncMemorial(doc, memorial));
  }

  // ─── Internal async sync methods ───────────────────────────────────────────

  Future<void> _syncPet(
    DocumentReference<Map<String, dynamic>> doc,
    Pet? pet,
  ) async {
    _emit(CloudSyncStatus.syncing);
    try {
      final petData = pet == null
          ? null
          : {
              'id': pet.id,
              'name': pet.name,
              'stageIndex': pet.stage.index,
              'stateIndex': pet.state.index,
              'mutationIndex': pet.mutation.index,
              'biomeId': pet.biomeId,
              'hunger': pet.stats.hunger,
              'mood': pet.stats.mood,
              'play': pet.stats.play,
              'sleep': pet.stats.sleep,
              'health': pet.stats.health,
              'cleanliness': pet.stats.cleanliness,
              'lastInteraction': Timestamp.fromDate(pet.lastInteraction),
              'createdAt': Timestamp.fromDate(pet.createdAt),
              'daysAlive': pet.daysAlive,
              'conditionTypeIndexes':
                  pet.conditions.map((c) => c.type.index).toList(),
              'conditionTimestamps': pet.conditions
                  .map((c) => c.contractedAt.millisecondsSinceEpoch)
                  .toList(),
            };

      await doc.set(
        {'pet': petData, 'lastSync': FieldValue.serverTimestamp()},
        SetOptions(merge: true),
      );
      _emit(CloudSyncStatus.synced);
    } catch (_) {
      _emit(CloudSyncStatus.error);
    }
  }

  Future<void> _syncCoins(
    DocumentReference<Map<String, dynamic>> doc,
    int coins,
  ) async {
    _emit(CloudSyncStatus.syncing);
    try {
      await doc.set(
        {'coins': coins, 'lastSync': FieldValue.serverTimestamp()},
        SetOptions(merge: true),
      );
      _emit(CloudSyncStatus.synced);
    } catch (_) {
      _emit(CloudSyncStatus.error);
    }
  }

  Future<void> _syncMemorial(
    DocumentReference<Map<String, dynamic>> doc,
    PetMemorial memorial,
  ) async {
    _emit(CloudSyncStatus.syncing);
    try {
      await doc.collection('memorials').doc(memorial.id).set({
        'id': memorial.id,
        'petName': memorial.petName,
        'mutationName': memorial.mutationName,
        'causeOfDeath': memorial.causeOfDeath,
        'daysAlive': memorial.daysAlive,
        'diedAt': Timestamp.fromDate(memorial.diedAt),
      });
      _emit(CloudSyncStatus.synced);
    } catch (_) {
      _emit(CloudSyncStatus.error);
    }
  }

  // ─── Load all cloud data (used on startup) ─────────────────────────────────

  Future<CloudSaveData?> loadAll() async {
    final doc = _userDoc;
    if (doc == null) return null;
    try {
      final snapshot = await doc.get();
      if (!snapshot.exists) return null;

      final data = snapshot.data();
      if (data == null) return null;

      final pet = _parsePet(data['pet'] as Map<String, dynamic>?);
      final coins = data['coins'] as int? ?? 0;

      final memorialsSnap = await doc.collection('memorials').get();
      final memorials = memorialsSnap.docs
          .map((d) => _parseMemorial(d.data()))
          .whereType<PetMemorial>()
          .toList();

      return CloudSaveData(pet: pet, coins: coins, memorials: memorials);
    } catch (_) {
      return null;
    }
  }

  // ─── Parsers ───────────────────────────────────────────────────────────────

  Pet? _parsePet(Map<String, dynamic>? data) {
    if (data == null) return null;
    try {
      final conditionIndexes =
          List<int>.from(data['conditionTypeIndexes'] as List? ?? []);
      final conditionTimestamps =
          List<int>.from(data['conditionTimestamps'] as List? ?? []);

      final conditions = <PetCondition>[];
      for (int i = 0; i < conditionIndexes.length; i++) {
        final idx = conditionIndexes[i];
        if (idx < 0 || idx >= ConditionType.values.length) continue;
        final ts = i < conditionTimestamps.length
            ? conditionTimestamps[i]
            : DateTime.now().millisecondsSinceEpoch;
        conditions.add(PetCondition(
          type: ConditionType.values[idx],
          contractedAt: DateTime.fromMillisecondsSinceEpoch(ts),
        ));
      }

      final stageIdx = (data['stageIndex'] as int? ?? 0)
          .clamp(0, PetStage.values.length - 1);
      final stateIdx = (data['stateIndex'] as int? ?? 0)
          .clamp(0, PetState.values.length - 1);
      final mutationIdx = (data['mutationIndex'] as int? ?? 0)
          .clamp(0, PetMutation.values.length - 1);

      return Pet(
        id: data['id'] as String,
        name: data['name'] as String,
        stage: PetStage.values[stageIdx],
        state: PetState.values[stateIdx],
        mutation: PetMutation.values[mutationIdx],
        biomeId: data['biomeId'] as String? ?? 'home',
        stats: PetStats(
          hunger: (data['hunger'] as num?)?.toDouble() ?? 70,
          mood: (data['mood'] as num?)?.toDouble() ?? 70,
          play: (data['play'] as num?)?.toDouble() ?? 70,
          sleep: (data['sleep'] as num?)?.toDouble() ?? 70,
          health: (data['health'] as num?)?.toDouble() ?? 100,
          cleanliness: (data['cleanliness'] as num?)?.toDouble() ?? 100,
        ),
        lastInteraction:
            (data['lastInteraction'] as Timestamp?)?.toDate() ?? DateTime.now(),
        createdAt:
            (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        daysAlive: data['daysAlive'] as int? ?? 0,
        conditions: conditions,
      );
    } catch (_) {
      return null;
    }
  }

  PetMemorial? _parseMemorial(Map<String, dynamic> data) {
    try {
      return PetMemorial(
        id: data['id'] as String,
        petName: data['petName'] as String,
        mutationName: data['mutationName'] as String,
        causeOfDeath: data['causeOfDeath'] as String,
        daysAlive: data['daysAlive'] as int,
        diedAt: (data['diedAt'] as Timestamp).toDate(),
      );
    } catch (_) {
      return null;
    }
  }
}
