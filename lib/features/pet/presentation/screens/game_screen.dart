import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../memorial/presentation/screens/memorial_screen.dart';
import '../../../store/presentation/providers/coins_provider.dart';
import '../../domain/entities/pet.dart';
import '../../domain/usecases/feed_pet_usecase.dart';
import '../providers/pet_provider.dart';
import '../widgets/action_buttons_widget.dart';
import '../widgets/stats_bar_widget.dart';
import '../../../../game/pet_flame_game.dart';
import 'jump_rope_screen.dart';
import 'mutation_screen.dart';

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  PetFlameGame? _game;

  // Inicializa el juego Flame la primera vez que tenemos una mascota.
  void _ensureGame(Pet pet) {
    _game ??= PetFlameGame(pet);
  }

  @override
  Widget build(BuildContext context) {
    final petAsync = ref.watch(petActionsProvider);

    // Escucha evoluciones para abrir MutationScreen
    ref.listen(evolutionEventProvider, (_, mutation) {
      if (mutation == null) return;
      // Consumir el evento antes de navegar para evitar duplicados
      ref.read(evolutionEventProvider.notifier).state = null;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => MutationScreen(mutation: mutation),
        ),
      );
    });

    // Sincroniza el juego Flame con el estado de Riverpod
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
                      // Monedas
                      Consumer(
                        builder: (context, ref, _) {
                          final coinsAsync = ref.watch(coinsProvider);
                          return coinsAsync.when(
                            loading: () => const SizedBox.shrink(),
                            error: (_, __) => const SizedBox.shrink(),
                            data: (coins) => Row(
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
                                const SizedBox(width: 8),
                              ],
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
                    ],
                  ),
                ],
              ),
            ),

            // ── Barras de stats ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: StatsBarWidget(
                hunger: pet.stats.hunger,
                mood: pet.stats.mood,
                play: pet.stats.play,
                sleep: pet.stats.sleep,
              ),
            ),

            // ── Banner de advertencia ────────────────────────────────────────
            if (pet.stats.isCritical)
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
                      // Juego Flame (fondo de bioma + mascota animada)
                      if (_game != null)
                        GameWidget(game: _game!)
                      else
                        const Center(
                          child: CircularProgressIndicator(
                              color: AppColors.primary),
                        ),

                      // Texto de mutación y etapa encima del juego
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
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // ── Botón minijuego ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const JumpRopeScreen()),
                    );
                    ref.read(coinsProvider.notifier).refresh();
                  },
                  icon: const Text('🎮', style: TextStyle(fontSize: 16)),
                  label: const Text(
                    'Jump Rope',
                    style: TextStyle(
                      fontFamily: 'PressStart2P',
                      fontSize: 10,
                      color: AppColors.statPlay,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side:
                        const BorderSide(color: AppColors.statPlay, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // ── Botones de acción ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ActionButtonsWidget(
                onFeed: () {
                  _game?.updatePet; // asegura sync visual
                  ref
                      .read(petActionsProvider.notifier)
                      .feedPet(FoodItem.basicFood);
                },
                onPlay: () =>
                    ref.read(petActionsProvider.notifier).playWithPet(),
                onBathe: () =>
                    ref.read(petActionsProvider.notifier).bathePet(),
                onSleep: () =>
                    ref.read(petActionsProvider.notifier).sleepPet(),
              ),
            ),

            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  // ─── Helpers ────────────────────────────────────────────────────────────────

  String _getWarningMessage(Pet pet) {
    if (pet.stats.health < 20) return '⚠ Tu mascota está enferma';
    if (pet.stats.hunger < 25) return '⚠ Tu mascota tiene mucha hambre';
    if (pet.stats.sleep < 15) return '⚠ Tu mascota está agotada';
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
