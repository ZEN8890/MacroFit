import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/database_services.dart';
import '../utils/global_state.dart';

class WaterTrackerCard extends StatelessWidget {
  final String uid;
  final Map<String, dynamic> userData;

  const WaterTrackerCard({
    super.key,
    required this.uid,
    required this.userData,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    String today = DateTime.now().toString().split(' ')[0];
    double targetWater = (userData['target_water'] ?? 2000).toDouble();

    return ValueListenableBuilder<bool>(
      valueListenable: isEnglishNotifier,
      builder: (context, englishActive, child) {
        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('daily_logs')
              .doc(today)
              .snapshots(),
          builder: (context, snapshot) {
            double currentWater = 0;
            if (snapshot.hasData && snapshot.data!.exists) {
              currentWater =
                  (snapshot.data!.data() as Map<String, dynamic>)['water_ml']
                      ?.toDouble() ??
                  0.0;
            }

            double progress = (currentWater / targetWater).clamp(0.0, 1.0);

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
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.local_drink,
                        color: Colors.blue,
                        size: 30,
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              englishActive
                                  ? "Daily Hydration"
                                  : "Hidrasi Hari Ini",
                              style: TextStyle(
                                color: colorScheme.onSurface.withOpacity(0.6),
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              "${currentWater.toInt()} / ${targetWater.toInt()} ml",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            onPressed: () async {
                              try {
                                await DatabaseService().removeWaterIntake(
                                  uid,
                                  250,
                                );
                              } catch (e) {
                                debugPrint("Gagal update air: $e");
                              }
                            },
                            icon: Icon(
                              Icons.remove_circle_outline,
                              color: Colors.redAccent.withOpacity(0.7),
                              size: 28,
                            ),
                          ),
                          IconButton(
                            onPressed: () =>
                                DatabaseService().updateWaterIntake(uid, 250),
                            icon: const Icon(
                              Icons.add_circle,
                              color: Colors.blue,
                              size: 32,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 10,
                      backgroundColor: Colors.blue.withOpacity(0.1),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.blue,
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      "${(progress * 100).toInt()}%",
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
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
