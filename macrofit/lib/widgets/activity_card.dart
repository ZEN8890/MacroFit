import 'package:flutter/material.dart';

class ActivityCard extends StatelessWidget {
  final String title;
  final String description;
  final bool isSelected;
  final VoidCallback onSelected;

  const ActivityCard({
    super.key,
    required this.title,
    required this.description,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    // Mengambil skema warna dari tema aktif
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onSelected,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          // Jika terpilih: biru transparan, jika tidak: pakai warna permukaan tema (Gelap di Dark Mode)
          color: isSelected
              ? colorScheme.primary.withOpacity(0.1)
              : colorScheme.surface,
          border: Border.all(
            // outline adalah warna unselectedDark/Light yang kita set di tema
            color: isSelected ? colorScheme.primary : colorScheme.outline,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      // Otomatis putih di dark mode, hitam di light mode
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      // Menggunakan onSurface dengan opasitas agar teks deskripsi lebih halus
                      color: colorScheme.onSurface.withOpacity(0.6),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: colorScheme.primary),
          ],
        ),
      ),
    );
  }
}
