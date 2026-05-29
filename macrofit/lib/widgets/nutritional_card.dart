import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'nutrition_progress_bar.dart';
import '../utils/global_state.dart'; // 🟢 IMPORT SAKLAR GLOBAL STATE

class NutritionalCard extends StatelessWidget {
  final Map<String, dynamic> userData;
  final String uid;

  const NutritionalCard({super.key, required this.userData, required this.uid});

  Color _getSugarColor(double current, double target) {
    if (current > target) return Colors.red;
    if (current > target * 0.8) return Colors.orange;
    return Colors.purpleAccent;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    String today = DateTime.now().toString().split(' ')[0];

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('daily_logs')
          .doc(today)
          .snapshots(),
      builder: (context, logSnapshot) {
        Map<String, dynamic> logData =
            logSnapshot.hasData && logSnapshot.data!.exists
            ? logSnapshot.data!.data() as Map<String, dynamic>
            : {
                'consumed_protein': 0,
                'consumed_carbs': 0,
                'consumed_fats': 0,
                'consumed_calories': 0,
                'consumed_sugar': 0,
              };

        double currentSugar = (logData['consumed_sugar'] ?? 0).toDouble();
        double targetSugar = (userData['target_sugar'] ?? 50.0).toDouble();

        // 🟢 REAKTIF MULTI-BAHASA
        return ValueListenableBuilder<bool>(
          valueListenable: isEnglishNotifier,
          builder: (context, englishActive, child) {
            return Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: colorScheme.outline),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    englishActive
                        ? "Macronutrients (Grams)"
                        : "Makronutrisi (Gram)",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 20),

                  NutritionProgressBar(
                    label: "Protein",
                    current: (logData['consumed_protein'] ?? 0).toDouble(),
                    target:
                        (userData['target_proteins'] ??
                                userData['target_protein'] ??
                                0)
                            .toDouble(),
                    color: Colors.redAccent,
                  ),

                  NutritionProgressBar(
                    label: englishActive ? "Carbohydrates" : "Karbohidrat",
                    current: (logData['consumed_carbs'] ?? 0).toDouble(),
                    target: (userData['target_carbs'] ?? 0).toDouble(),
                    color: Colors.blueAccent,
                  ),

                  NutritionProgressBar(
                    label: englishActive ? "Fats" : "Lemak",
                    current: (logData['consumed_fats'] ?? 0).toDouble(),
                    target: (userData['target_fats'] ?? 0).toDouble(),
                    color: Colors.orangeAccent,
                  ),

                  NutritionProgressBar(
                    label: englishActive ? "Sugar" : "Gula",
                    current: currentSugar,
                    target: targetSugar,
                    color: _getSugarColor(currentSugar, targetSugar),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
