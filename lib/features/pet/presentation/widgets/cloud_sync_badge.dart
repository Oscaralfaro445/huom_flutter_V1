import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/cloud_sync_provider.dart';

class CloudSyncBadge extends ConsumerStatefulWidget {
  const CloudSyncBadge({super.key});

  @override
  ConsumerState<CloudSyncBadge> createState() => _CloudSyncBadgeState();
}

class _CloudSyncBadgeState extends ConsumerState<CloudSyncBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final syncAsync = ref.watch(cloudSyncProvider);

    final status = syncAsync.valueOrNull ?? CloudSyncStatus.idle;

    if (status == CloudSyncStatus.syncing) {
      _rotationController.repeat();
    } else {
      _rotationController.stop();
      _rotationController.reset();
    }

    return GestureDetector(
      onTap: () => _showStatus(context, status),
      child: SizedBox(
        width: 20,
        height: 20,
        child: _buildIcon(status),
      ),
    );
  }

  Widget _buildIcon(CloudSyncStatus status) {
    return switch (status) {
      CloudSyncStatus.syncing => RotationTransition(
          turns: _rotationController,
          child: const Icon(Icons.sync, color: Colors.white54, size: 16),
        ),
      CloudSyncStatus.synced => const Icon(
          Icons.cloud_done_outlined,
          color: Color(0xFF4CAF50),
          size: 16,
        ),
      CloudSyncStatus.error => const Icon(
          Icons.cloud_off_outlined,
          color: Color(0xFFE94560),
          size: 16,
        ),
      CloudSyncStatus.idle => const Icon(
          Icons.cloud_outlined,
          color: Colors.white24,
          size: 16,
        ),
    };
  }

  void _showStatus(BuildContext context, CloudSyncStatus status) {
    final message = switch (status) {
      CloudSyncStatus.syncing => 'Guardando en la nube...',
      CloudSyncStatus.synced => 'Progreso guardado en la nube',
      CloudSyncStatus.error => 'Sin conexión — guardado local',
      CloudSyncStatus.idle => 'Guardado en la nube',
    };

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontFamily: 'PressStart2P', fontSize: 8),
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: const Color(0xFF1A1A2E),
      ),
    );
  }
}
