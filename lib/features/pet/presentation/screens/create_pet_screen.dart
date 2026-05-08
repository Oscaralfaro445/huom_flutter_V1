import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/pet.dart';
import '../providers/pet_provider.dart';
import '../widgets/pet_picker_widget.dart';

class CreatePetScreen extends ConsumerStatefulWidget {
  const CreatePetScreen({super.key});

  @override
  ConsumerState<CreatePetScreen> createState() => _CreatePetScreenState();
}

class _CreatePetScreenState extends ConsumerState<CreatePetScreen> {
  final TextEditingController _nameController = TextEditingController();
  PetMutation? _selectedMutation;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _nameController.text.trim().isNotEmpty && _selectedMutation != null;

  Future<void> _createPet() async {
    if (!_canSubmit) return;
    setState(() => _isLoading = true);
    await ref.read(petActionsProvider.notifier).createPet(
          _nameController.text.trim(),
          mutation: _selectedMutation,
        );
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Encabezado ─────────────────────────────────────────────
              const Center(
                child: Text(
                  'HUOM',
                  style: TextStyle(
                    fontSize: 30,
                    color: AppColors.primary,
                    fontFamily: 'PressStart2P',
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Center(
                child: Text(
                  'Tu mascota virtual',
                  style: TextStyle(
                    fontSize: 9,
                    color: AppColors.textSecondary,
                    fontFamily: 'PressStart2P',
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // ── Selector de mascota ───────────────────────────────────
              const Text(
                'ELIGE TU MASCOTA',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textPrimary,
                  fontFamily: 'PressStart2P',
                ),
              ),
              const SizedBox(height: 14),
              PetPickerWidget(
                selected: _selectedMutation,
                onSelect: (m) => setState(() => _selectedMutation = m),
              ),
              const SizedBox(height: 24),

              // ── Nombre ─────────────────────────────────────────────────
              const Text(
                'NOMBRE',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.textPrimary,
                  fontFamily: 'PressStart2P',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _nameController,
                maxLength: 12,
                textAlign: TextAlign.center,
                onChanged: (_) => setState(() {}),
                style: const TextStyle(
                  fontFamily: 'PressStart2P',
                  fontSize: 13,
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: 'Tu mascota...',
                  hintStyle: const TextStyle(
                    color: AppColors.textSecondary,
                    fontFamily: 'PressStart2P',
                    fontSize: 12,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: AppColors.buttonBorder,
                      width: 2,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: AppColors.surface,
                ),
              ),
              const SizedBox(height: 20),

              // ── Botón Comenzar ────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed:
                      (_isLoading || !_canSubmit) ? null : _createPet,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor:
                        AppColors.primary.withValues(alpha: 0.35),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          '¡COMENZAR!',
                          style: TextStyle(
                            fontFamily: 'PressStart2P',
                            fontSize: 12,
                            color: Colors.white,
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
}
