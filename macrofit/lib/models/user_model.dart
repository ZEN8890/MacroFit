// user_model.dart

//data model user
class UserModel {
  final String uid;
  final String firstName;
  final String lastName;
  final String email;

  int dailyCalorieTarget;
  double? weight; // dalam kg
  double? height; // dalam cm
  int? age;
  String? gender; // 'pria' atau 'wanita'
  String? activityLevel; // sedentary, light, moderate, active
  String? bodyGoal; // lose, maintain, gain

  UserModel({
    required this.uid,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.dailyCalorieTarget = 0,
    this.weight,
    this.height,
    this.age,
    this.gender,
    this.activityLevel,
    this.bodyGoal,
  });

  // Mengubah data ke Map untuk dikirim ke Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'daily_calorie_target': dailyCalorieTarget,
      'weight': weight,
      'height': height,
      'age': age,
      'gender': gender,
      'activity_level': activityLevel,
      'body_goal': bodyGoal,
    };
  }

  // Factory untuk mengambil data dari Firestore (Map to Object)
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      firstName: map['first_name'] ?? '',
      lastName: map['last_name'] ?? '',
      email: map['email'] ?? '',
      dailyCalorieTarget: map['daily_calorie_target'] ?? 0,
      weight: (map['weight'] as num?)?.toDouble(),
      height: (map['height'] as num?)?.toDouble(),
      age: map['age'] as int?,
      gender: map['gender'] as String?,
      activityLevel: map['activity_level'] as String?,
      bodyGoal: map['body_goal'] as String?,
    );
  }
}
