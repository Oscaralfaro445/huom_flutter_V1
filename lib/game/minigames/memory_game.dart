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
///   - [pairCount] pares (cartas = pairCount * 2). Cada par usa una
///     mutación distinta, sin repetidos. Por defecto 6 pares (12 cartas,
///     grid 4x3), que es el máximo posible sin repeticiones dado que
///     solo hay 7 mutaciones disponibles (deja 1 fuera como variedad
///     entre partidas).
///   - El jugador voltea cartas de a 2. Si coinciden, se quedan reveladas;
///     si no, se ocultan tras [flipBackDelay].
///   - El juego termina cuando todos los pares están encontrados.
///   - Score = max(0, (pairCount*4 - moves) * 5). Premia eficiencia.
class MemoryGame extends ChangeNotifier {
  final void Function(int score) onGameOver;
  final Random _rng;
  final Duration flipBackDelay;
  final int pairCount;

  MemoryGameState state = MemoryGameState.playing;
  int moves = 0;
  int score = 0;
  bool inputLocked = false;

  late List<MemoryCard> cards;
  int? _firstPick;

  MemoryGame({
    required this.onGameOver,
    int? seed,
    this.pairCount = 6,
    this.flipBackDelay = const Duration(milliseconds: 700),
  })  : _rng = Random(seed),
        assert(
          pairCount > 0 && pairCount <= PetMutation.values.length,
          'pairCount debe estar entre 1 y ${PetMutation.values.length} (mutaciones disponibles)',
        ) {
    _setupBoard();
  }

  void _setupBoard() {
    // Elegir pairCount mutaciones DISTINTAS de las disponibles
    final available = <PetMutation>[...PetMutation.values]..shuffle(_rng);
    final selected = available.take(pairCount).toList();

    final pool = <MemoryCard>[];
    var id = 0;
    for (final m in selected) {
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
    // Score = max(0, (perfectMoves*2 - moves) * 5). El score perfecto
    // es 0 moves "extra", lo que da (pairCount*2)*5. pairCount=6 → max 60.
    final perfectBudget = pairCount * 4;
    score = ((perfectBudget - moves) * 5).clamp(0, perfectBudget * 5);
    onGameOver(score);
  }

  @visibleForTesting
  int? get firstPickIndex => _firstPick;
}
