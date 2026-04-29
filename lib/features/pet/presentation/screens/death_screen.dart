import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../memorial/domain/pet_memorial.dart';
import '../providers/pet_provider.dart';
import '../../../memorial/presentation/screens/memorial_screen.dart';

class DeathScreen extends ConsumerWidget {
  final PetMemorial memorial;

  const DeathScreen({super.key, required this.memorial});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icono de muerte
              const Text('💀', style: TextStyle(fontSize: 80)),
              const SizedBox(height: 24),

              const Text(
                'Ha fallecido...',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  fontFamily: 'PressStart2P',
                ),
              ),
              const SizedBox(height: 16),

              // Nombre de la mascota
              Text(
                memorial.petName,
                style: const TextStyle(
                  fontSize: 22,
                  color: AppColors.primary,
                  fontFamily: 'PressStart2P',
                ),
              ),
              const SizedBox(height: 8),

              Text(
                memorial.mutationName,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                  fontFamily: 'PressStart2P',
                ),
              ),
              const SizedBox(height: 32),

              // Tarjeta de info
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.surface,
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    _InfoRow(
                      label: 'Causa',
                      value: memorial.causeOfDeath,
                    ),
                    const SizedBox(height: 12),
                    _InfoRow(
                      label: 'Días vividos',
                      value: '${memorial.daysAlive} días',
                    ),
                    const SizedBox(height: 12),
                    _InfoRow(
                      label: 'Descanse en paz',
                      value: _formatDate(memorial.diedAt),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // Botón nueva mascota
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    await ref
                        .read(petActionsProvider.notifier)
                        .resetForNewPet();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Nueva mascota',
                    style: TextStyle(
                      fontFamily: 'PressStart2P',
                      fontSize: 11,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Botón ver memorial
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const MemorialScreen(),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(
                      color: AppColors.buttonBorder,
                      width: 2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Ver memorial',
                    style: TextStyle(
                      fontFamily: 'PressStart2P',
                      fontSize: 11,
                      color: AppColors.buttonBorder,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 8,
            color: AppColors.textSecondary,
            fontFamily: 'PressStart2P',
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 8,
            color: AppColors.textPrimary,
            fontFamily: 'PressStart2P',
          ),
        ),
      ],
    );
  }
}
