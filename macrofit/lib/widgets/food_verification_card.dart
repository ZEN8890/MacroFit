import 'package:flutter/material.dart';
import '../utils/global_state.dart'; // 🟢 IMPORT SAKLAR GLOBAL STATE

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

  Widget _nutrisiMiniText(
    BuildContext context,
    String label,
    String value, {
    required Color badgeColor,
    Color? valueColor,
  }) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: badgeColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: badgeColor,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: valueColor ?? (isDarkMode ? Colors.white : Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // 🟢 REAKTIF MULTI-BAHASA: Membungkus kartu verifikasi dengan ValueListenableBuilder
    return ValueListenableBuilder<bool>(
      valueListenable: isEnglishNotifier,
      builder: (context, englishActive, child) {
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: theme.cardTheme.color,
          elevation: 2,
          shape:
              theme.cardTheme.shape ??
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.analytics_outlined,
                      color: Colors.blue,
                      size: 22,
                    ),
                    Expanded(
                      child: Text(
                        englishActive
                            ? "Verification Result: ${data['food_name']}"
                            : "Verifikasi Hasil: ${data['food_name']}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10.0),
                  child: Divider(thickness: 1, height: 1),
                ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _nutrisiMiniText(
                      context,
                      "PROT",
                      "${data['protein']}g",
                      badgeColor: Colors.redAccent,
                    ),
                    _nutrisiMiniText(
                      context,
                      englishActive ? "CARB" : "KARBO",
                      "${data['carbs']}g",
                      badgeColor: Colors.amber.shade700,
                    ),
                    _nutrisiMiniText(
                      context,
                      englishActive ? "FAT" : "LEMAK",
                      "${data['fats']}g",
                      badgeColor: Colors.blueGrey,
                    ),
                    _nutrisiMiniText(
                      context,
                      englishActive ? "CAL" : "KALORI",
                      "${data['calories']} Kcal",
                      badgeColor: Colors.orange,
                      valueColor: Colors.orange.shade700,
                    ),
                    _nutrisiMiniText(
                      context,
                      englishActive ? "WATER" : "AIR",
                      "${data['water_ml']}ml",
                      badgeColor: Colors.blue,
                      valueColor: Colors.blue,
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child:
                          ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade600,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 46),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ).asButton(
                            onPressed: onCancel,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.close, size: 18),
                                const SizedBox(width: 6),
                                Text(
                                  englishActive ? "Wrong" : "Salah",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child:
                          ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade600,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 46),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ).asButton(
                            onPressed: onConfirm,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.check, size: 18),
                                const SizedBox(width: 6),
                                Text(
                                  englishActive ? "Correct" : "Benar",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

extension ElevatedButtonStyles on ButtonStyle {
  ElevatedButton asButton({
    required VoidCallback? onPressed,
    required Widget child,
  }) {
    return ElevatedButton(style: this, onPressed: onPressed, child: child);
  }
}
