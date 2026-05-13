import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/nutrition_model.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- LOGIKA UPDATE PROFIL ---
  Future<void> updateOnboardingData({
    required String uid,
    required int age,
    required double weight,
    required double height,
    required String gender,
    required NutritionModel nutrition,
  }) async {
    try {
      await _firestore.collection("users").doc(uid).update({
        'age': age,
        'weight': weight,
        'height': height,
        'gender': gender,
        'diet_code': nutrition.dietCode,
        'target_protein': nutrition.proteinGram,
        'target_carbs': nutrition.carbsGram,
        'target_fats': nutrition.fatsGram,
        'target_sugar': nutrition.sugarGram, // TAMBAHKAN INI
        'target_water': nutrition.waterMl, // TAMBAHKAN INI
        'target_cal_min': nutrition.targetCalMin,
        'daily_calorie_target': nutrition.targetCalMax,
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("Error Update Profil: $e");
      rethrow;
    }
  }

  // --- LOGIKA WATER TRACKER ---
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
        'consumed_protein': FieldValue.increment(0),
        'consumed_carbs': FieldValue.increment(0),
        'consumed_fats': FieldValue.increment(0),
        'consumed_calories': FieldValue.increment(0),
        'consumed_sugar': FieldValue.increment(0), // TAMBAHKAN INI
      }, SetOptions(merge: true));
    } catch (e) {
      print("Error Water Intake: $e");
    }
  }

  //remove water intake
  Future<void> removeWaterIntake(String uid, int amount) async {
    String today = DateTime.now().toString().split(' ')[0];
    DocumentReference dailyRef = _firestore
        .collection("users")
        .doc(uid)
        .collection("daily_logs")
        .doc(today);

    try {
      // Kita gunakan Transaction agar lebih aman saat pengambilan data current
      await _firestore.runTransaction((transaction) async {
        DocumentSnapshot snap = await transaction.get(dailyRef);

        if (snap.exists) {
          Map<String, dynamic> data = snap.data() as Map<String, dynamic>;
          double current = (data['water_ml'] ?? 0).toDouble();

          // Logika: Jangan biarkan air jadi negatif di bawah 0
          double newValue = (current - amount) < 0 ? 0 : (current - amount);

          transaction.update(dailyRef, {'water_ml': newValue});
        }
      });
    } catch (e) {
      print("Error Remove Water: $e");
    }
  }

  // --- FUNGSI SAVE FOOD LOG ---
  Future<void> saveFoodLog(String uid, Map<String, dynamic> foodData) async {
    num safeNum(dynamic value) {
      if (value == null) return 0;
      if (value is num) return value;
      return num.tryParse(value.toString()) ?? 0;
    }

    try {
      String today = DateTime.now().toString().split(' ')[0];
      DocumentReference logRef = _firestore
          .collection('users')
          .doc(uid)
          .collection('daily_logs')
          .doc(today);

      await _firestore.runTransaction((transaction) async {
        DocumentSnapshot snapshot = await transaction.get(logRef);

        num protein = safeNum(foodData['protein']);
        num carbs = safeNum(foodData['carbs']);
        num fats = safeNum(foodData['fats']);
        num calories = safeNum(foodData['calories']);
        num sugar = safeNum(foodData['sugar']);
        num water = safeNum(foodData['water_ml']);

        Map<String, dynamic> historyItem = {
          'food_name': foodData['food_name'],
          'calories': calories,
          'sugar': sugar,
          'water_ml': water, // Tambahkan detail air di history
          'time': Timestamp.now(),
        };

        if (!snapshot.exists) {
          transaction.set(logRef, {
            'consumed_protein': protein,
            'consumed_carbs': carbs,
            'consumed_fats': fats,
            'consumed_calories': calories,
            'consumed_sugar': sugar,
            'water_ml': water,
            'date': today,
            'food_history': [historyItem],
          });
        } else {
          transaction.update(logRef, {
            'consumed_protein': FieldValue.increment(protein),
            'consumed_carbs': FieldValue.increment(carbs),
            'consumed_fats': FieldValue.increment(fats),
            'consumed_calories': FieldValue.increment(calories),
            'consumed_sugar': FieldValue.increment(sugar),
            'water_ml': FieldValue.increment(water),
            'food_history': FieldValue.arrayUnion([historyItem]),
          });
        }
      });
    } catch (e) {
      print("CRITICAL DATABASE ERROR: $e");
      rethrow;
    }
  }
}
