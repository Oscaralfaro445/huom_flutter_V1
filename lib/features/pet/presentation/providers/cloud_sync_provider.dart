import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/services/cloud_save_service.dart';

export '../../../../core/services/cloud_save_service.dart' show CloudSyncStatus;

final cloudSyncProvider = StreamProvider<CloudSyncStatus>((ref) {
  return sl<CloudSaveService>().onSyncStatus;
});
