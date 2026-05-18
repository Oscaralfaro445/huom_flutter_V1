import 'package:flutter_test/flutter_test.dart';
import 'package:huom/features/pet/domain/entities/pet.dart';
import 'package:huom/game/minigames/memory_game.dart';

void main() {
  group('MemoryGame.setup', () {
    test('por defecto crea 6 pares (12 cartas) — máximo sin repetir', () {
      // Arrange / Act
      final game = MemoryGame(onGameOver: (_) {}, seed: 1);

      // Assert
      expect(game.cards.length, 12);
      expect(game.pairCount, 6);
    });

    test('cada mutación aparece EXACTAMENTE 2 veces, nunca más', () {
      // Regresión del bug donde una mutación aparecía 4 veces porque
      // _setupBoard duplicaba una mutation al azar antes de generar pares.
      for (var seed = 0; seed < 20; seed++) {
        // Arrange / Act
        final game = MemoryGame(onGameOver: (_) {}, seed: seed);

        // Assert
        final counts = <PetMutation, int>{};
        for (final c in game.cards) {
          counts[c.mutation] = (counts[c.mutation] ?? 0) + 1;
        }
        for (final entry in counts.entries) {
          expect(
            entry.value,
            2,
            reason:
                'seed=$seed: ${entry.key} aparece ${entry.value} veces, debería ser exactamente 2',
          );
        }
      }
    });

    test('todas las cartas inician boca abajo y sin matchear', () {
      // Arrange / Act
      final game = MemoryGame(onGameOver: (_) {}, seed: 1);

      // Assert
      expect(game.cards.every((c) => !c.revealed), isTrue);
      expect(game.cards.every((c) => !c.matched), isTrue);
    });

    test('pairCount custom genera el doble de cartas', () {
      // Arrange / Act
      final game = MemoryGame(onGameOver: (_) {}, seed: 1, pairCount: 4);

      // Assert
      expect(game.cards.length, 8);
    });

    test('pairCount > mutaciones disponibles dispara assertion', () {
      // Assert
      expect(
        () => MemoryGame(
          onGameOver: (_) {},
          seed: 1,
          pairCount: PetMutation.values.length + 1,
        ),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('MemoryGame.flip', () {
    test('voltear 2 cartas iguales las deja matched', () {
      // Arrange
      final game = MemoryGame(onGameOver: (_) {}, seed: 1);
      // Encontrar dos índices con la misma mutación
      const firstIdx = 0;
      final firstMut = game.cards[firstIdx].mutation;
      final secondIdx =
          game.cards.indexWhere((c) => c.mutation == firstMut, firstIdx + 1);

      // Act
      game.flip(firstIdx);
      game.flip(secondIdx);

      // Assert
      expect(game.cards[firstIdx].matched, isTrue);
      expect(game.cards[secondIdx].matched, isTrue);
      expect(game.moves, 1);
    });

    test('voltear 2 cartas diferentes incrementa moves y bloquea input',
        () async {
      // Arrange
      final game = MemoryGame(
        onGameOver: (_) {},
        seed: 1,
        flipBackDelay: const Duration(milliseconds: 10),
      );
      // Buscar dos índices con mutaciones DIFERENTES
      const firstIdx = 0;
      final firstMut = game.cards[firstIdx].mutation;
      final diffIdx =
          game.cards.indexWhere((c) => c.mutation != firstMut, firstIdx + 1);

      // Act
      game.flip(firstIdx);
      game.flip(diffIdx);

      // Assert (inmediatamente tras el segundo flip)
      expect(game.moves, 1);
      expect(game.inputLocked, isTrue);
      expect(game.cards[firstIdx].matched, isFalse);
      expect(game.cards[diffIdx].matched, isFalse);

      // Esperar al flipBack
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(game.cards[firstIdx].revealed, isFalse);
      expect(game.cards[diffIdx].revealed, isFalse);
      expect(game.inputLocked, isFalse);
    });

    test('flip ignora cartas ya matcheadas', () {
      // Arrange
      final game = MemoryGame(onGameOver: (_) {}, seed: 1);
      const firstIdx = 0;
      final firstMut = game.cards[firstIdx].mutation;
      final secondIdx =
          game.cards.indexWhere((c) => c.mutation == firstMut, firstIdx + 1);
      game.flip(firstIdx);
      game.flip(secondIdx);
      // Ambas matcheadas

      // Act: intentar voltearlas de nuevo
      final movesBefore = game.moves;
      game.flip(firstIdx);

      // Assert
      expect(game.moves, movesBefore);
      expect(game.cards[firstIdx].matched, isTrue);
    });

    test('encontrar todos los pares dispara onGameOver con score positivo',
        () async {
      // Arrange
      int? finalScore;
      final game = MemoryGame(
        onGameOver: (s) => finalScore = s,
        seed: 1,
        pairCount: 2, // partida cortita para test
      );

      // Act: emparejar los 2 pares en orden óptimo
      final pairs = <List<int>>[];
      final used = <int>{};
      for (var i = 0; i < game.cards.length; i++) {
        if (used.contains(i)) continue;
        final partner = game.cards.indexWhere(
          (c) => c.mutation == game.cards[i].mutation,
          i + 1,
        );
        pairs.add([i, partner]);
        used.add(i);
        used.add(partner);
      }
      for (final pair in pairs) {
        game.flip(pair[0]);
        game.flip(pair[1]);
      }

      // Assert
      expect(finalScore, isNotNull);
      expect(finalScore! > 0, isTrue);
      expect(game.state, MemoryGameState.gameOver);
    });
  });
}
