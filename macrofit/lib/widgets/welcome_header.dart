import 'package:flutter/material.dart';

class WelcomeHeader extends StatelessWidget {
  final String name;

  const WelcomeHeader({super.key, required this.name});

  @override
  Widget build(BuildContext context) {
    // Mengambil colorScheme dari context agar tetap sinkron dengan tema aplikasi
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Statistik Hari Ini,",
          style: TextStyle(
            color: colorScheme.onSurface.withOpacity(0.6),
            fontSize: 14,
          ),
        ),
        Text(
          name,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
