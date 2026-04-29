import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/pet.dart';
import '../../domain/usecases/feed_pet_usecase.dart';
import '../providers/pet_provider.dart';
import '../widgets/stats_bar_widget.dart';
import '../widgets/action_buttons_widget.dart';

class GameScreen extends ConsumerWidget {
  const GameScreen({super.key});

  String _getTimeOfDayBackground() {
    final hour = DateTime.now().hour;
    if (hour >= 6 && hour < 12) return '🌅';
    if (hour >= 12 && hour < 19) return '☀️';
    return '🌙';
  }

  String _getPetEmoji(Pet pet) {
    if (pet.state == PetState.dead) return '💀';
    if (pet.state == PetState.sick) return '🤒';
    if (pet.state == PetState.stressed) return '😰';
    if (pet.stats.hunger > 80 && pet.stats.mood > 80) return '🤩';
    return '😊';
  }

  Color _getBackgroundColor() {
    final hour = DateTime.now().hour;
    if (hour >= 6 && hour < 12) {
      return const Color(0xFF1A2A4A);
    }
    if (hour >= 12 && hour < 19) {
      return const Color(0xFF1A1A2E);
    }
    return const Color(0xFF0A0A1A);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final petAsync = ref.watch(petActionsProvider);

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
        return _buildGameScreen(context, ref, pet);
      },
    );
  }

  Widget _buildGameScreen(BuildContext context, WidgetRef ref, Pet pet) {
    return Scaffold(
      backgroundColor: _getBackgroundColor(),
      body: SafeArea(
        child: Column(
          children: [
            // Header con nombre y momento del día
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
                        _getTimeOfDayBackground(),
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
                    ],
                  ),
                ],
              ),
            ),

            // Barras de stats
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: StatsBarWidget(
                hunger: pet.stats.hunger,
                mood: pet.stats.mood,
                play: pet.stats.play,
                sleep: pet.stats.sleep,
              ),
            ),

            const SizedBox(height: 16),

            // Área principal de la mascota
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.surface,
                    width: 2,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Sprite placeholder de la mascota
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Text(
                        _getPetEmoji(pet),
                        key: ValueKey(pet.state),
                        style: const TextStyle(fontSize: 100),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Nombre de mutación
                    Text(
                      _getMutationName(pet.mutation),
                      style: const TextStyle(
                        fontSize: 9,
                        color: AppColors.primary,
                        fontFamily: 'PressStart2P',
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Etapa
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
            ),

            const SizedBox(height: 16),

            // Botones de acción
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ActionButtonsWidget(
                onFeed: () => ref
                    .read(petActionsProvider.notifier)
                    .feedPet(FoodItem.basicFood),
                onPlay: () =>
                    ref.read(petActionsProvider.notifier).playWithPet(),
                onBathe: () => ref.read(petActionsProvider.notifier).bathePet(),
                onSleep: () => ref.read(petActionsProvider.notifier).sleepPet(),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  String _getMutationName(PetMutation mutation) {
    return switch (mutation) {
      PetMutation.slimeBit => 'Slime Bit',
      PetMutation.cactusRex => 'Cactus Rex',
      PetMutation.aquaSlime => 'Aqua Slime',
      PetMutation.thunderLeaf => 'Thunder Leaf',
      PetMutation.blossom => 'Blossom',
      PetMutation.shadowBone => 'Shadow Bone',
      PetMutation.glitchPet => 'Glitch Pet',
    };
  }

  String _getStageName(PetStage stage) {
    return switch (stage) {
      PetStage.egg => '[ Huevo ]',
      PetStage.baby => '[ Cría ]',
      PetStage.adult => '[ Adulto ]',
      PetStage.elder => '[ Anciano ]',
    };
  }
}
