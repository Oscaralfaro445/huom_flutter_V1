import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../features/pet/domain/entities/pet.dart';

enum MemoryGameState { playing, gameOver }

class MemoryCard {
  final int id;
  final PetMutation mutation;
  bool revealed = false;
  bool matched = false;

  MemoryCard({required this.id, required this.mutation});
}

/// Modelo puro de Memory para que la UI lo renderice como un GridView
/// y los tests puedan validar la lógica sin Flame.
///
/// Reglas:
///   - 8 pares (16 cartas) usando sprites de las 7 mutaciones (una repetida).
///   - El jugador voltea cartas de a 2. Si coinciden, se quedan reveladas;
///     si no, se ocultan tras [flipBackDelay].
///   - El juego termina cuando todos los pares están encontrados.
///   - Score = (40 - moves) * 5, mínimo 0. Premia eficiencia.
class MemoryGame extends ChangeNotifier {
  final void Function(int score) onGameOver;
  final Random _rng;
  final Duration flipBackDelay;

  MemoryGameState state = MemoryGameState.playing;
  int moves = 0;
  int score = 0;
  bool inputLocked = false;

  late List<MemoryCard> cards;
  int? _firstPick;

  MemoryGame({
    required this.onGameOver,
    int? seed,
    this.flipBackDelay = const Duration(milliseconds: 700),
  }) : _rng = Random(seed) {
    _setupBoard();
  }

  void _setupBoard() {
    // 8 pares: 7 mutaciones + 1 repetida elegida al azar
    final mutations = <PetMutation>[...PetMutation.values];
    mutations.add(mutations[_rng.nextInt(mutations.length)]);

    final pool = <MemoryCard>[];
    var id = 0;
    for (final m in mutations) {
      pool.add(MemoryCard(id: id++, mutation: m));
      pool.add(MemoryCard(id: id++, mutation: m));
    }
    pool.shuffle(_rng);
    cards = pool;
  }

  /// Voltea la carta en [index]. No hace nada si ya está revelada,
  /// matched, o el input está bloqueado por animación.
  void flip(int index) {
    if (state == MemoryGameState.gameOver) return;
    if (inputLocked) return;
    final card = cards[index];
    if (card.revealed || card.matched) return;

    card.revealed = true;
    notifyListeners();

    if (_firstPick == null) {
      _firstPick = index;
      return;
    }

    moves++;
    final firstIdx = _firstPick!;
    _firstPick = null;

    if (cards[firstIdx].mutation == card.mutation) {
      cards[firstIdx].matched = true;
      card.matched = true;
      notifyListeners();
      _checkWin();
    } else {
      inputLocked = true;
      notifyListeners();
      Timer(flipBackDelay, () {
        cards[firstIdx].revealed = false;
        card.revealed = false;
        inputLocked = false;
        notifyListeners();
      });
    }
  }

  void _checkWin() {
    final allMatched = cards.every((c) => c.matched);
    if (!allMatched) return;
    state = MemoryGameState.gameOver;
    // Score = max(0, (40 - moves) * 5)
    score = ((40 - moves) * 5).clamp(0, 200);
    onGameOver(score);
  }

  @visibleForTesting
  int? get firstPickIndex => _firstPick;
}
