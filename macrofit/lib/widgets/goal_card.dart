import 'package:flutter/material.dart';

class GoalCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap_goal;

  const GoalCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap_goal,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    // Kita gunakan warna hijau sukses khusus untuk goal
    const successColor = Colors.green;

    return GestureDetector(
      onTap: onTap_goal,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? successColor.withOpacity(0.1)
              : colorScheme.surface,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isSelected ? successColor : colorScheme.outline,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? successColor
                  : colorScheme.onSurface.withOpacity(0.4),
              size: 30,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      // Jika terpilih kita beri warna hijau agar kontras, jika tidak ikut tema
                      color: isSelected ? successColor : colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: colorScheme.onSurface.withOpacity(0.5),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected) const Icon(Icons.check_circle, color: successColor),
          ],
        ),
      ),
    );
  }
}
