import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/services/coins_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../game/minigames/memory_game.dart';
import '../../domain/entities/pet.dart';
import '../providers/pet_provider.dart';
import '../widgets/sprite_frame_preview.dart';

class MemoryScreen extends ConsumerStatefulWidget {
  const MemoryScreen({super.key});

  @override
  ConsumerState<MemoryScreen> createState() => _MemoryScreenState();
}

class _MemoryScreenState extends ConsumerState<MemoryScreen> {
  late MemoryGame _game;
  bool _gameOver = false;
  int _finalScore = 0;
  int _coinsEarned = 0;

  @override
  void initState() {
    super.initState();
    _startGame();
  }

  void _startGame() {
    setState(() {
      _gameOver = false;
      _finalScore = 0;
    });
    _game = MemoryGame(
      onGameOver: (score) {
        final coins = _calculateCoinsMemory(score);
        setState(() {
          _gameOver = true;
          _finalScore = score;
          _coinsEarned = coins;
        });
        _applyRewards(coins);
      },
    );
    _game.addListener(_onGameChanged);
  }

  void _onGameChanged() {
    if (mounted) setState(() {});
  }

  // Curva específica para Memory: el score llega a 200 (40 - moves) * 5.
  // Mapeamos a la misma escala de monedas que los otros juegos.
  int _calculateCoinsMemory(int score) {
    if (score >= 150) return 30;
    if (score >= 100) return 20;
    if (score >= 50) return 15;
    return 5;
  }

  Future<void> _applyRewards(int coins) async {
    await sl<CoinsService>().addCoins(coins);
    await ref.read(petActionsProvider.notifier).playWithPet();
  }

  @override
  void dispose() {
    _game.removeListener(_onGameChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                        'Memory',
                        style: TextStyle(
                          fontFamily: 'PressStart2P',
                          fontSize: 12,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Movimientos: ${_game.moves}',
                        style: const TextStyle(
                          fontFamily: 'PressStart2P',
                          fontSize: 9,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: _game.cards.length,
                      itemBuilder: (context, i) {
                        final card = _game.cards[i];
                        return GestureDetector(
                          onTap: () => _game.flip(i),
                          child: _MemoryCardTile(card: card),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
            if (_gameOver)
              _MemoryGameOver(
                score: _finalScore,
                moves: _game.moves,
                coins: _coinsEarned,
                onReplay: _startGame,
                onExit: () => Navigator.of(context).pop(),
              ),
          ],
        ),
      ),
    );
  }
}

class _MemoryCardTile extends StatelessWidget {
  final MemoryCard card;

  const _MemoryCardTile({required this.card});

  @override
  Widget build(BuildContext context) {
    final isFaceUp = card.revealed || card.matched;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        color: card.matched
            ? AppColors.statPlay.withValues(alpha: 0.15)
            : (isFaceUp ? AppColors.surface : AppColors.buttonBackground),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: card.matched
              ? AppColors.statPlay
              : (isFaceUp ? AppColors.primary : AppColors.buttonBorder),
          width: card.matched ? 2 : 1.5,
        ),
      ),
      child: Center(
        child: isFaceUp
            ? SpriteFramePreview(
                assetPath: 'assets/${card.mutation.spritePath}',
                frameSize: 48,
                displaySize: 48,
              )
            : const Text(
                '?',
                style: TextStyle(
                  fontFamily: 'PressStart2P',
                  fontSize: 18,
                  color: AppColors.textSecondary,
                ),
              ),
      ),
    );
  }
}

class _MemoryGameOver extends StatelessWidget {
  final int score;
  final int moves;
  final int coins;
  final VoidCallback onReplay;
  final VoidCallback onExit;

  const _MemoryGameOver({
    required this.score,
    required this.moves,
    required this.coins,
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
                '¡Ganaste!',
                style: TextStyle(
                  fontFamily: 'PressStart2P',
                  fontSize: 16,
                  color: AppColors.statPlay,
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
              const SizedBox(height: 8),
              Text(
                'Movimientos: $moves',
                style: const TextStyle(
                  fontFamily: 'PressStart2P',
                  fontSize: 9,
                  color: AppColors.textSecondary,
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
                        'Jugar de nuevo',
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
