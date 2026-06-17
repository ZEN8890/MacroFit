import 'package:flutter/material.dart';

class GenderCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap_gender;

  const GenderCard({
    super.key,
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap_gender,
  });

  @override
  Widget build(BuildContext context) {
    // Mengambil skema warna dari tema aktif
    final colorScheme = Theme.of(context).colorScheme;

    // LOGIKA WARNA PINK KUSTOM
    final Color activeColor = (label == "Female" || label == "Wanita")
        ? Colors.pink
        : colorScheme.primary;

    // 🟢 PERBAIKAN: Langsung kembalikan GestureDetector (Buang pembungkus Expanded di sini)
    return GestureDetector(
      onTap: onTap_gender,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withOpacity(0.1)
              : colorScheme.surface,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isSelected ? activeColor : colorScheme.outline,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 40,
              color: isSelected
                  ? activeColor
                  : colorScheme.onSurface.withOpacity(0.4),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? activeColor : colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
