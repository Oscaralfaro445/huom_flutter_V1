import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../features/pet/data/models/pet_model.dart';
import '../../features/pet/data/repositories/pet_repository_impl.dart';
import '../../features/pet/domain/repositories/pet_repository.dart';
import '../../features/pet/domain/usecases/feed_pet_usecase.dart';
import '../../features/pet/domain/usecases/sleep_usecase.dart';
import '../../features/pet/domain/usecases/play_usecase.dart';
import '../../features/pet/domain/usecases/bathe_usecase.dart';
import '../../features/pet/domain/usecases/create_pet_usecase.dart';
import '../services/stat_decay_service.dart';

final GetIt sl = GetIt.instance;

Future<void> setupDependencies() async {
  // Inicializar Hive
  await Hive.initFlutter();

  // Registrar adaptadores
  Hive.registerAdapter(PetModelAdapter());

  // Services
  sl.registerSingleton<StatDecayService>(StatDecayService());

  // Repositories
  sl.registerSingleton<PetRepository>(PetRepositoryImpl());

  // Use Cases
  sl.registerFactory(() => CreatePetUseCase(sl<PetRepository>()));
  sl.registerFactory(() => FeedPetUseCase(
        sl<PetRepository>(),
        sl<StatDecayService>(),
      ));
  sl.registerFactory(() => SleepUseCase(
        sl<PetRepository>(),
        sl<StatDecayService>(),
      ));
  sl.registerFactory(() => PlayUseCase(
        sl<PetRepository>(),
        sl<StatDecayService>(),
      ));
  sl.registerFactory(() => BatheUseCase(
        sl<PetRepository>(),
        sl<StatDecayService>(),
      ));
}
