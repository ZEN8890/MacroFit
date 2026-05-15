import 'package:flutter/material.dart';

class FoodVerificationCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const FoodVerificationCard({
    super.key,
    required this.data,
    required this.onConfirm,
    required this.onCancel,
  });

  // Tambahkan BuildContext agar bisa membaca tema (Dark/Light Mode)
  Widget _nutrisiMiniText(
    BuildContext context,
    String label,
    String value, {
    Color? valueColor,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            // onSurface otomatis Putih di Dark Mode, Hitam di Light Mode
            color: valueColor ?? colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 20),
      // Background kartu ikut tema surface agar sinkron
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: colorScheme.primary.withOpacity(0.5), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "🔍 Verifikasi: ${data['food_name']}",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: colorScheme.onSurface, // Judul adaptif
              ),
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _nutrisiMiniText(context, "P", "${data['protein']}g"),
                _nutrisiMiniText(context, "K", "${data['carbs']}g"),
                _nutrisiMiniText(context, "L", "${data['fats']}g"),
                _nutrisiMiniText(context, "Kal", "${data['calories']} kcal"),
                _nutrisiMiniText(
                  context,
                  "Air",
                  "${data['water_ml']}ml",
                  valueColor: Colors.blue,
                ),
              ],
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onCancel,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                    child: const Text("Salah"),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text("Benar"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
