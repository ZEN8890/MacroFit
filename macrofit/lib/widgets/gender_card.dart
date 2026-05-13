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

    return Expanded(
      child: GestureDetector(
        onTap: onTap_gender,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            // Warna background adaptif
            color: isSelected
                ? colorScheme.primary.withOpacity(0.1)
                : colorScheme.surface,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              // Outline adaptif (akan gelap di dark mode)
              color: isSelected ? colorScheme.primary : colorScheme.outline,
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
                    ? colorScheme.primary
                    : colorScheme.onSurface.withOpacity(0.4),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  // Warna teks adaptif
                  color: isSelected
                      ? colorScheme.primary
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
