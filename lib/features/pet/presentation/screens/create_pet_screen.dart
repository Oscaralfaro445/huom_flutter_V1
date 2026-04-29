import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/pet_provider.dart';

class CreatePetScreen extends ConsumerStatefulWidget {
  const CreatePetScreen({super.key});

  @override
  ConsumerState<CreatePetScreen> createState() => _CreatePetScreenState();
}

class _CreatePetScreenState extends ConsumerState<CreatePetScreen> {
  final TextEditingController _nameController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _createPet() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _isLoading = true);
    await ref.read(petActionsProvider.notifier).createPet(name);
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'HUOM',
                style: TextStyle(
                  fontSize: 36,
                  color: AppColors.primary,
                  fontFamily: 'PressStart2P',
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Tu mascota virtual',
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                  fontFamily: 'PressStart2P',
                ),
              ),
              const SizedBox(height: 60),
              // Huevo placeholder
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(60),
                  border: Border.all(
                    color: AppColors.primary,
                    width: 3,
                  ),
                ),
                child: const Center(
                  child: Text('🥚', style: TextStyle(fontSize: 60)),
                ),
              ),
              const SizedBox(height: 60),
              const Text(
                'Dale un nombre\na tu mascota',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textPrimary,
                  fontFamily: 'PressStart2P',
                  height: 1.8,
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _nameController,
                maxLength: 12,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'PressStart2P',
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: 'Nombre...',
                  hintStyle: const TextStyle(
                    color: AppColors.textSecondary,
                    fontFamily: 'PressStart2P',
                    fontSize: 14,
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
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createPet,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
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
                          '¡Comenzar!',
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
