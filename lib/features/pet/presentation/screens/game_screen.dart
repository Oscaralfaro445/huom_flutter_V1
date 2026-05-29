import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../memorial/presentation/screens/memorial_screen.dart';
import '../../../store/presentation/providers/coins_provider.dart';
import '../../../store/presentation/screens/store_screen.dart';
import '../../domain/entities/pet.dart';
import '../../domain/usecases/feed_pet_usecase.dart';
import '../providers/pet_provider.dart';
import '../widgets/action_buttons_widget.dart';
import '../widgets/action_feedback_overlay.dart';
import '../widgets/cloud_sync_badge.dart';
import '../widgets/food_menu_sheet.dart';
import '../widgets/games_menu_sheet.dart';
import '../widgets/stats_bar_widget.dart';
import '../../../../game/pet_flame_game.dart';
import 'color_tap_screen.dart';
import 'dodge_bombs_screen.dart';
import 'food_drop_screen.dart';
import 'memory_screen.dart';
import 'mutation_screen.dart';
import 'reaction_tap_screen.dart';
import 'sky_jump_screen.dart';
import 'whack_a_pet_screen.dart';

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  PetFlameGame? _game;

  Widget? _feedbackOverlay;
  int _feedbackKey = 0;

  void _ensureGame(Pet pet) {
    _game ??= PetFlameGame(pet);
  }

  void _showFeedback({
    required String emoji,
    required String label,
    required Color color,
  }) {
    final key = ++_feedbackKey;
    setState(() {
      _feedbackOverlay = ActionFeedbackOverlay(
        key: ValueKey(key),
        emoji: emoji,
        label: label,
        labelColor: color,
        onCompleted: () {
          if (!mounted) return;
          if (_feedbackKey == key) {
            setState(() => _feedbackOverlay = null);
          }
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final petAsync = ref.watch(petActionsProvider);

    ref.listen(evolutionEventProvider, (_, mutation) {
      if (mutation == null) return;
      ref.read(evolutionEventProvider.notifier).state = null;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => MutationScreen(mutation: mutation),
        ),
      );
    });

    ref.listen(petActionsProvider, (_, next) {
      final pet = next.valueOrNull;
      if (pet != null && _game != null) {
        _game!.updatePet(pet);
      }
    });

    return petAsync.when(
      loading: () => const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: Text('Error: $e')),
      ),
      data: (pet) {
        if (pet == null) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }
        _ensureGame(pet);
        return _buildGameScreen(context, pet);
      },
    );
  }

  Widget _buildGameScreen(BuildContext context, Pet pet) {
    return Scaffold(
      backgroundColor: _getBackgroundColor(),
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    pet.name,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textPrimary,
                      fontFamily: 'PressStart2P',
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        _getTimeOfDayIcon(),
                        style: const TextStyle(fontSize: 18),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Día ${pet.daysAlive}',
                        style: const TextStyle(
                          fontSize: 9,
                          color: AppColors.textSecondary,
                          fontFamily: 'PressStart2P',
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Monedas + botón tienda
                      Consumer(
                        builder: (context, ref, _) {
                          final coinsAsync = ref.watch(coinsProvider);
                          return coinsAsync.when(
                            loading: () => const SizedBox.shrink(),
                            error: (_, __) => const SizedBox.shrink(),
                            data: (coins) => GestureDetector(
                              onTap: _openStore,
                              child: Row(
                                children: [
                                  const Text('🪙',
                                      style: TextStyle(fontSize: 14)),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$coins',
                                    style: const TextStyle(
                                      fontSize: 9,
                                      color: AppColors.statMood,
                                      fontFamily: 'PressStart2P',
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.storefront_rounded,
                                    color: AppColors.statMood,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      GestureDetector(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const MemorialScreen()),
                        ),
                        child: const Text('🪦',
                            style: TextStyle(fontSize: 20)),
                      ),
                      const SizedBox(width: 8),
                      const CloudSyncBadge(),
                    ],
                  ),
                ],
              ),
            ),

            // ── Barras de stats (incluye salud y condiciones) ────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: StatsBarWidget(
                hunger: pet.stats.hunger,
                mood: pet.stats.mood,
                play: pet.stats.play,
                sleep: pet.stats.sleep,
                cleanliness: pet.stats.cleanliness,
                health: pet.stats.health,
                conditions: pet.conditions,
              ),
            ),

            // ── Banner de advertencia ────────────────────────────────────────
            if (pet.stats.isCritical || pet.hasCondition)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.statCritical.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border:
                        Border.all(color: AppColors.statCritical, width: 1),
                  ),
                  child: Text(
                    _getWarningMessage(pet),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'PressStart2P',
                      fontSize: 7,
                      color: AppColors.statCritical,
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 8),

            // ── Área principal: Flame game ───────────────────────────────────
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.surface, width: 2),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Stack(
                    children: [
                      if (_game != null)
                        GameWidget(game: _game!)
                      else
                        const Center(
                          child: CircularProgressIndicator(
                              color: AppColors.primary),
                        ),
                      Positioned(
                        bottom: 12,
                        left: 0,
                        right: 0,
                        child: Column(
                          children: [
                            Text(
                              pet.mutation.displayName,
                              style: const TextStyle(
                                fontSize: 9,
                                color: AppColors.primary,
                                fontFamily: 'PressStart2P',
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _getStageName(pet.stage),
                              style: const TextStyle(
                                fontSize: 8,
                                color: AppColors.textSecondary,
                                fontFamily: 'PressStart2P',
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_feedbackOverlay != null)
                        Positioned.fill(child: _feedbackOverlay!),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // ── Botones de acción ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ActionButtonsWidget(
                onFeed: _openFoodMenu,
                onPlay: _openGamesMenu,
                onBathe: _bathePet,
                onSleep: () =>
                    ref.read(petActionsProvider.notifier).sleepPet(),
                onStore: _openStore,
              ),
            ),

            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  // ─── Acciones ──────────────────────────────────────────────────────────────

  Future<void> _openFoodMenu() async {
    final food = await showFoodMenu(context);
    if (food == null) return;
    _game?.triggerEatAnimation();
    _showFeedback(
      emoji: _foodEmoji(food),
      label: '¡ÑAM ÑAM!',
      color: AppColors.statHunger,
    );
    await ref.read(petActionsProvider.notifier).feedPet(food);
  }

  Future<void> _bathePet() async {
    _game?.triggerBatheAnimation();
    _showFeedback(
      emoji: '🫧',
      label: '¡A BAÑARSE!',
      color: AppColors.statCleanliness,
    );
    await ref.read(petActionsProvider.notifier).bathePet();
  }

  Future<void> _openStore() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const StoreScreen()),
    );
    ref.read(coinsProvider.notifier).refresh();
  }

  String _foodEmoji(FoodItem food) => switch (food) {
        FoodItem.snack => '🍪',
        FoodItem.basicFood => '🍗',
        FoodItem.premiumFood => '🥩',
        FoodItem.specialFood => '🍰',
      };

  Future<void> _openGamesMenu() async {
    final game = await showGamesMenu(context);
    if (game == null) return;
    if (!mounted) return;
    switch (game) {
      case GameId.foodDrop:
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const FoodDropScreen()),
        );
        break;
      case GameId.colorTap:
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ColorTapScreen()),
        );
        break;
      case GameId.memory:
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const MemoryScreen()),
        );
        break;
      case GameId.skyJump:
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const SkyJumpScreen()),
        );
        break;
      case GameId.reactionTap:
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ReactionTapScreen()),
        );
        break;
      case GameId.whackAPet:
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const WhackAPetScreen()),
        );
        break;
      case GameId.dodgeBombs:
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const DodgeBombsScreen()),
        );
        break;
    }
    if (!mounted) return;
    ref.read(coinsProvider.notifier).refresh();
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  String _getWarningMessage(Pet pet) {
    if (pet.conditions.isNotEmpty) {
      final c = pet.conditions.first;
      return '${c.icon} Tu mascota tiene ${c.displayName} — visita la tienda';
    }
    if (pet.stats.health < 20) return '⚠ Tu mascota está enferma';
    if (pet.stats.hunger < 25) return '⚠ Tu mascota tiene mucha hambre';
    if (pet.stats.sleep < 15) return '⚠ Tu mascota está agotada';
    if (pet.stats.cleanliness < 20) return '⚠ Tu mascota necesita un baño';
    return '';
  }

  String _getTimeOfDayIcon() {
    final hour = DateTime.now().hour;
    if (hour >= 6 && hour < 12) return '🌅';
    if (hour >= 12 && hour < 19) return '☀️';
    return '🌙';
  }

  Color _getBackgroundColor() {
    final hour = DateTime.now().hour;
    if (hour >= 6 && hour < 12) return const Color(0xFF1A2A4A);
    if (hour >= 12 && hour < 19) return const Color(0xFF1A1A2E);
    return const Color(0xFF0A0A1A);
  }

  String _getStageName(PetStage stage) => switch (stage) {
        PetStage.egg => '[ Huevo ]',
        PetStage.baby => '[ Cría ]',
        PetStage.adult => '[ Adulto ]',
        PetStage.elder => '[ Anciano ]',
      };
}
