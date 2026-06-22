import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/nutrition_model.dart';
import 'package:flutter/foundation.dart';
import '../utils/global_state.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> updateOnboardingData({
    required String uid,
    required int age,
    required double weight,
    required double height,
    required String gender,
    required NutritionModel nutrition,
  }) async {
    try {
      await _firestore.collection("users").doc(uid).set({
        'age': age,
        'weight': weight,
        'height': height,
        'gender': gender,
        'diet_code': nutrition.dietCode,
        'target_protein': nutrition.proteinGram,
        'target_carbs': nutrition.carbsGram,
        'target_fats': nutrition.fatsGram,
        'target_sugar': nutrition.sugarGram,
        'target_water': nutrition.waterMl,
        'target_cal_min': nutrition.targetCalMin,
        'daily_calorie_target': nutrition.targetCalMax,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint("Error Update Profil: $e");
      rethrow;
    }
  }

  Future<void> updateWaterIntake(String uid, int addMl) async {
    String today = DateTime.now().toString().split(' ')[0];
    DocumentReference dailyRef = _firestore
        .collection("users")
        .doc(uid)
        .collection("daily_logs")
        .doc(today);

    try {
      await dailyRef.set({
        'water_ml': FieldValue.increment(addMl),
        'date': today,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint("Error Water Intake: $e");
    }
  }

  Future<void> removeWaterIntake(String uid, int amount) async {
    String today = DateTime.now().toString().split(' ')[0];
    DocumentReference dailyRef = _firestore
        .collection("users")
        .doc(uid)
        .collection("daily_logs")
        .doc(today);

    try {
      await _firestore
          .runTransaction((transaction) async {
            DocumentSnapshot snap = await transaction.get(dailyRef);
            if (snap.exists) {
              Map<String, dynamic> data = snap.data() as Map<String, dynamic>;
              double current = (data['water_ml'] ?? 0).toDouble();
              double newValue = (current - amount).clamp(0.0, double.infinity);
              transaction.update(dailyRef, {'water_ml': newValue});
            }
          })
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      debugPrint("MacroFit Error - Remove Water: $e");
      throw Exception(
        isEnglishNotifier.value
            ? "Failed to reduce water log data: $e"
            : "Gagal mengurangi data air: $e",
      );
    }
  }

  Future<void> saveFoodLog(String uid, Map<String, dynamic> foodData) async {
    num safeNum(dynamic value) {
      if (value == null) return 0;
      if (value is num) return value;
      return num.tryParse(value.toString()) ?? 0;
    }

    try {
      String today = DateTime.now().toString().split(' ')[0];
      DocumentReference dailyRef = _firestore
          .collection('users')
          .doc(uid)
          .collection('daily_logs')
          .doc(today);
      CollectionReference historyRef = _firestore
          .collection('users')
          .doc(uid)
          .collection('food_logs');

      await _firestore.runTransaction((transaction) async {
        num protein = safeNum(foodData['protein']);
        num carbs = safeNum(foodData['carbs']);
        num fats = safeNum(foodData['fats']);
        num calories = safeNum(foodData['calories']);
        num sugar = safeNum(foodData['sugar']);
        num water = safeNum(foodData['water_ml']);

        transaction.set(historyRef.doc(), {
          'food_name': foodData['food_name'],
          'protein': protein,
          'carbs': carbs,
          'fats': fats,
          'calories': calories,
          'sugar': sugar,
          'water_ml': water,
          'timestamp': FieldValue.serverTimestamp(),
        });

        transaction.set(dailyRef, {
          'consumed_protein': FieldValue.increment(protein),
          'consumed_carbs': FieldValue.increment(carbs),
          'consumed_fats': FieldValue.increment(fats),
          'consumed_calories': FieldValue.increment(calories),
          'consumed_sugar': FieldValue.increment(sugar),
          'water_ml': FieldValue.increment(water),
          'date': today,
        }, SetOptions(merge: true));
      });
    } catch (e) {
      debugPrint("CRITICAL DATABASE ERROR: $e");
      rethrow;
    }
  }

  Stream<QuerySnapshot> getTodayFoodLogs(String uid) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    return _firestore
        .collection('users')
        .doc(uid)
        .collection('food_logs')
        .where('timestamp', isGreaterThanOrEqualTo: startOfDay)
        .where('timestamp', isLessThanOrEqualTo: endOfDay)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot> getFilteredFoodLogs(
    String uid,
    String filterType,
    DateTime? customDate,
  ) {
    final now = DateTime.now();
    DateTime startDate;
    if (filterType == 'Harian' || filterType == 'Daily') {
      startDate = DateTime(now.year, now.month, now.day);
    } else if (filterType == 'Mingguan' || filterType == 'Weekly') {
      startDate = now.subtract(const Duration(days: 7));
    } else if (filterType == 'Tahunan' || filterType == 'Yearly') {
      startDate = DateTime(now.year, 1, 1);
    } else if (filterType == 'Custom' && customDate != null) {
      startDate = DateTime(customDate.year, customDate.month, customDate.day);
      DateTime endDate = DateTime(
        customDate.year,
        customDate.month,
        customDate.day,
        23,
        59,
        59,
      );

      return _firestore
          .collection('users')
          .doc(uid)
          .collection('food_logs')
          .where('timestamp', isGreaterThanOrEqualTo: startDate)
          .where('timestamp', isLessThanOrEqualTo: endDate)
          .orderBy('timestamp', descending: true)
          .snapshots();
    } else {
      startDate = DateTime(now.year, now.month, now.day);
    }

    return _firestore
        .collection('users')
        .doc(uid)
        .collection('food_logs')
        .where('timestamp', isGreaterThanOrEqualTo: startDate)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }
}
