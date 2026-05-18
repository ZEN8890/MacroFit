import 'package:flutter/material.dart';

class CalorieTargetCard extends StatelessWidget {
  final int targetCal;
  final int consumedCal; // Tambahkan parameter kalori yang dikonsumsi

  const CalorieTargetCard({
    super.key,
    required this.targetCal,
    required this.consumedCal, // Wajib diisi saat memanggil card ini
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Hitung persentase untuk progress bar (maksimal 1.0 agar tidak crash jika surplus)
    double progress = targetCal > 0 ? (consumedCal / targetCal) : 0.0;
    double clampedProgress = progress.clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outlineVariant,
        ), // Gunakan outlineVariant agar lebih smooth
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Pencapaian Kalori Harian",
                    style: TextStyle(
                      color: colorScheme.onSurface.withOpacity(0.5),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      // Kalori yang sudah dimakan
                      Text(
                        "$consumedCal",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 28,
                          color: consumedCal > targetCal
                              ? Colors.red
                              : colorScheme.primary,
                        ),
                      ),
                      // Pembagi target maksimal
                      Text(
                        " / $targetCal kkal",
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                          color: colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              // Ikon Petir Petunjuk
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.bolt_rounded,
                  color: Colors.orange,
                  size: 30,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          // --- VISUAL PROGRESS BAR ---
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: clampedProgress,
              minHeight: 10,
              backgroundColor: colorScheme.surfaceVariant,
              // Jika melebihi target, warna bar berubah jadi merah (Peringatan Surplus)
              valueColor: AlwaysStoppedAnimation<Color>(
                consumedCal > targetCal ? Colors.red : Colors.green,
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Keterangan Sisa Kalori
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "${(progress * 100).toInt()}% Terpenuhi",
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
              if (targetCal - consumedCal >= 0)
                Text(
                  "Sisa: ${targetCal - consumedCal} kkal lagi",
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                )
              else
                Text(
                  "Surplus: ${(targetCal - consumedCal).abs()} kkal!",
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
