import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/pet.dart';
import 'sprite_frame_preview.dart';

/// Grid 2×4 con las 7 mutaciones disponibles. Llama [onSelect] cuando el
/// usuario toca una. La que se renderiza con borde primario es [selected].
class PetPickerWidget extends StatelessWidget {
  final PetMutation? selected;
  final ValueChanged<PetMutation> onSelect;

  const PetPickerWidget({
    super.key,
    required this.selected,
    required this.onSelect,
  });

  static const _options = PetMutation.values;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _options.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.85,
      ),
      itemBuilder: (context, i) {
        final mutation = _options[i];
        final isSelected = mutation == selected;
        return _PetCard(
          mutation: mutation,
          selected: isSelected,
          onTap: () => onSelect(mutation),
        );
      },
    );
  }
}

class _PetCard extends StatelessWidget {
  final PetMutation mutation;
  final bool selected;
  final VoidCallback onTap;

  const _PetCard({
    required this.mutation,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.15)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.buttonBorder,
            width: selected ? 2.5 : 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SpriteFramePreview(
              assetPath: 'assets/${mutation.spritePath}',
              frameSize: 48,
              displaySize: 56,
            ),
            const SizedBox(height: 6),
            Text(
              mutation.displayName.toUpperCase(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'PressStart2P',
                fontSize: 6.5,
                color: selected
                    ? AppColors.primary
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
