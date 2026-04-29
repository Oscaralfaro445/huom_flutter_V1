import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/di/injection.dart';
import '../../domain/memorial_repository.dart';
import '../../domain/pet_memorial.dart';

class MemorialScreen extends StatefulWidget {
  const MemorialScreen({super.key});

  @override
  State<MemorialScreen> createState() => _MemorialScreenState();
}

class _MemorialScreenState extends State<MemorialScreen> {
  List<PetMemorial> _memorials = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMemorials();
  }

  Future<void> _loadMemorials() async {
    final memorials = await sl<MemorialRepository>().getAllMemorials();
    setState(() {
      _memorials = memorials;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundSecondary,
        title: const Text(
          'Memorial',
          style: TextStyle(
            fontFamily: 'PressStart2P',
            fontSize: 14,
            color: AppColors.textPrimary,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _memorials.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('🪦', style: TextStyle(fontSize: 60)),
                      SizedBox(height: 16),
                      Text(
                        'Ninguna mascota\nha fallecido aún',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'PressStart2P',
                          fontSize: 10,
                          color: AppColors.textSecondary,
                          height: 1.8,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _memorials.length,
                  itemBuilder: (context, index) {
                    return _MemorialCard(memorial: _memorials[index]);
                  },
                ),
    );
  }
}

class _MemorialCard extends StatelessWidget {
  final PetMemorial memorial;

  const _MemorialCard({required this.memorial});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surface, width: 2),
      ),
      child: Row(
        children: [
          // Ícono
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: Text('🪦', style: TextStyle(fontSize: 28)),
            ),
          ),
          const SizedBox(width: 16),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  memorial.petName,
                  style: const TextStyle(
                    fontFamily: 'PressStart2P',
                    fontSize: 11,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  memorial.mutationName,
                  style: const TextStyle(
                    fontFamily: 'PressStart2P',
                    fontSize: 8,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Causa: ${memorial.causeOfDeath}',
                  style: const TextStyle(
                    fontFamily: 'PressStart2P',
                    fontSize: 7,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${memorial.daysAlive} días · ${_formatDate(memorial.diedAt)}',
                  style: const TextStyle(
                    fontFamily: 'PressStart2P',
                    fontSize: 7,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
