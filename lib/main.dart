import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/di/injection.dart';
import 'core/theme/app_theme.dart';
import 'features/pet/presentation/providers/pet_provider.dart';
import 'features/pet/presentation/screens/create_pet_screen.dart';
import 'features/pet/presentation/screens/game_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupDependencies();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final petAsync = ref.watch(petActionsProvider);

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
        data: (pet) =>
            pet == null ? const CreatePetScreen() : const GameScreen(),
      ),
    );
  }
}
