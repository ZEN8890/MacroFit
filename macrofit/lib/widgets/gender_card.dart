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

    // 🟢 LOGIKA WARNA PINKKUSTOM: Jika kartu ini adalah kartu Female, gunakan warna pink.
    // Jika bukan (misal Male), tetap gunakan warna tema utama aplikasi (colorScheme.primary).
    final Color activeColor = (label == "Female")
        ? Colors.pink
        : colorScheme.primary;

    return Expanded(
      child: GestureDetector(
        onTap: onTap_gender,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            // Warna background adaptif
            color: isSelected
                ? activeColor.withOpacity(0.1) // 🟢 Menggunakan activeColor
                : colorScheme.surface,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              // Outline adaptif
              color: isSelected
                  ? activeColor
                  : colorScheme.outline, // 🟢 Menggunakan activeColor
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 40,
                // Warna ikon adaptif
                color: isSelected
                    ? activeColor // 🟢 Menggunakan activeColor
                    : colorScheme.onSurface.withOpacity(0.4),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  // Warna teks adaptif
                  color: isSelected
                      ? activeColor // 🟢 Menggunakan activeColor
                      : colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
