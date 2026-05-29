import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/di/injection.dart';
import 'core/services/auth_service.dart';
import 'core/services/cloud_save_service.dart';
import 'core/services/coins_service.dart';
import 'core/theme/app_theme.dart';
import 'features/memorial/domain/memorial_repository.dart';
import 'features/pet/domain/repositories/pet_repository.dart';
import 'features/pet/presentation/providers/pet_provider.dart';
import 'features/pet/presentation/screens/create_pet_screen.dart';
import 'features/pet/presentation/screens/death_screen.dart';
import 'features/pet/presentation/screens/game_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
  } catch (_) {
    // Firebase not configured — cloud save disabled
  }

  await setupDependencies();
  await _restoreFromCloud();

  runApp(const ProviderScope(child: MyApp()));
}

Future<void> _restoreFromCloud() async {
  try {
    final authService = sl<AuthService>();
    await authService.signInAnonymously();

    if (!authService.isAuthenticated) return;

    final cloudService = sl<CloudSaveService>();
    final cloudData = await cloudService.loadAll();
    if (cloudData == null) return;

    final petRepo = sl<PetRepository>();
    final localPet = await petRepo.getActivePet();

    // Restore pet if cloud version is newer
    if (cloudData.pet != null) {
      final shouldRestore = localPet == null ||
          cloudData.pet!.lastInteraction.isAfter(localPet.lastInteraction);
      if (shouldRestore) {
        await petRepo.savePet(cloudData.pet!);
      }
    }

    // Restore coins: take the maximum (can't lose earned coins)
    final coinsService = sl<CoinsService>();
    final localCoins = await coinsService.getCoins();
    if (cloudData.coins > localCoins) {
      await coinsService.addCoins(cloudData.coins - localCoins);
    }

    // Restore memorials: merge (union by id)
    final memorialRepo = sl<MemorialRepository>();
    final localMemorials = await memorialRepo.getAllMemorials();
    final localIds = localMemorials.map((m) => m.id).toSet();
    for (final memorial in cloudData.memorials) {
      if (!localIds.contains(memorial.id)) {
        await memorialRepo.saveMemorial(memorial);
      }
    }
  } catch (_) {
    // Cloud restore is optional — never crash the app
  }
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final petAsync = ref.watch(petActionsProvider);
    final deathMemorial = ref.watch(deathMemorialProvider);

    return MaterialApp(
      title: 'HUOM',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: petAsync.when(
        loading: () => const Scaffold(
          backgroundColor: Color(0xFF1A1A2E),
          body: Center(
            child: CircularProgressIndicator(
              color: Color(0xFFE94560),
            ),
          ),
        ),
        error: (e, _) => Scaffold(
          body: Center(child: Text('Error: $e')),
        ),
        data: (pet) {
          // Mostrar pantalla de muerte si hay memorial
          if (deathMemorial != null) {
            return DeathScreen(memorial: deathMemorial);
          }
          return pet == null ? const CreatePetScreen() : const GameScreen();
        },
      ),
    );
  }
}
