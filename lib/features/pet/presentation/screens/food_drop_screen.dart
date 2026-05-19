import 'dart:math';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/services/coins_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../game/minigames/food_drop_game.dart';
import '../../domain/entities/pet.dart';
import '../providers/pet_provider.dart';

class FoodDropScreen extends ConsumerStatefulWidget {
  const FoodDropScreen({super.key});

  @override
  ConsumerState<FoodDropScreen> createState() => _FoodDropScreenState();
}

class _FoodDropScreenState extends ConsumerState<FoodDropScreen> {
  late FoodDropGame _game;
  bool _gameOver = false;
  int _finalScore = 0;
  int _coinsEarned = 0;
  bool _injured = false;

  @override
  void initState() {
    super.initState();
    _startGame();
  }

  void _startGame() {
    setState(() {
      _gameOver = false;
      _finalScore = 0;
      _injured = false;
    });
    final pet = ref.read(petActionsProvider).valueOrNull;
    final spritePath = (pet?.mutation ?? PetMutation.slimeBit).spritePath;
    _game = FoodDropGame(
      petSpritePath: spritePath,
      onGameOver: (score) {
        final coins = _calculateCoins(score);
        final injured = _rollInjury(score);
        setState(() {
          _gameOver = true;
          _finalScore = score;
          _coinsEarned = coins;
          _injured = injured;
        });
        _applyRewards(coins, injured);
      },
    );
  }

  int _calculateCoins(int score) {
    if (score >= 20) return 30;
    if (score >= 10) return 20;
    if (score >= 5) return 15;
    return 5;
  }

  /// Colisionar con bomba (score 0) = 20% chance de lesión leve.
  bool _rollInjury(int score) {
    if (score > 0) return false;
    return Random().nextDouble() < 0.20;
  }

  Future<void> _applyRewards(int coins, bool injured) async {
    await sl<CoinsService>().addCoins(coins);
    await ref.read(petActionsProvider.notifier).playWithPet();
    if (injured) {
      await ref
          .read(petActionsProvider.notifier)
          .applyInjury(ConditionType.minorInjury);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          GameWidget(game: _game),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Icon(
                      Icons.close,
                      color: AppColors.textPrimary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Food Drop',
                    style: TextStyle(
                      fontFamily: 'PressStart2P',
                      fontSize: 12,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_gameOver)
            _GameOverOverlay(
              score: _finalScore,
              coins: _coinsEarned,
              injured: _injured,
              onReplay: _startGame,
              onExit: () => Navigator.of(context).pop(),
            ),
        ],
      ),
    );
  }
}

class _GameOverOverlay extends StatelessWidget {
  final int score;
  final int coins;
  final bool injured;
  final VoidCallback onReplay;
  final VoidCallback onExit;

  const _GameOverOverlay({
    required this.score,
    required this.coins,
    required this.injured,
    required this.onReplay,
    required this.onExit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.85),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primary, width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Game Over',
                style: TextStyle(
                  fontFamily: 'PressStart2P',
                  fontSize: 16,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Score: $score',
                style: const TextStyle(
                  fontFamily: 'PressStart2P',
                  fontSize: 13,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('🪙 ', style: TextStyle(fontSize: 20)),
                  Text(
                    '+$coins monedas',
                    style: const TextStyle(
                      fontFamily: 'PressStart2P',
                      fontSize: 11,
                      color: AppColors.statMood,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                '+Juego subió',
                style: TextStyle(
                  fontFamily: 'PressStart2P',
                  fontSize: 9,
                  color: AppColors.statPlay,
                ),
              ),
              if (injured) ...[
                const SizedBox(height: 10),
                const Text(
                  '🩹 ¡La bomba lastimó a tu mascota!',
                  style: TextStyle(
                    fontFamily: 'PressStart2P',
                    fontSize: 8,
                    color: AppColors.statCritical,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onExit,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: AppColors.buttonBorder),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Salir',
                        style: TextStyle(
                          fontFamily: 'PressStart2P',
                          fontSize: 9,
                          color: AppColors.buttonBorder,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onReplay,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Jugar',
                        style: TextStyle(
                          fontFamily: 'PressStart2P',
                          fontSize: 9,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
