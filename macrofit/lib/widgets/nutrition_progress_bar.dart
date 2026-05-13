import 'package:flutter/material.dart';

class NutritionProgressBar extends StatelessWidget {
  final String label;
  final double current;
  final double target;
  final Color color;

  const NutritionProgressBar({
    super.key,
    required this.label,
    required this.current,
    required this.target,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Ambil context warna dari tema
    final colorScheme = Theme.of(context).colorScheme;
    double progress = target > 0 ? (current / target) : 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  // 2. Hapus 'const' agar bisa pakai variabel
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  // 3. Gunakan onSurface agar teks otomatis Putih di Dark Mode
                  color: colorScheme.onSurface,
                ),
              ),
              Text(
                "${current.round()} / ${target.round()}g",
                style: TextStyle(
                  fontSize: 12,
                  // 4. Gunakan onSurface dengan opacity agar tetap terlihat tapi halus
                  color: colorScheme.onSurface.withOpacity(0.6),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 10,
              // 5. Menggunakan outline dari tema untuk background progress bar
              backgroundColor: colorScheme.outline,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
