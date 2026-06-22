//class untuk menampung data user yang diambil dari API
class UserModel {
  final String uid;
  final String firstName;
  final String lastName;
  final String email;
  final String? username;

  int dailyCalorieTarget;
  double? weight;
  double? height;
  int? age;
  String? gender;
  String? activityLevel;
  String? bodyGoal;

  UserModel({
    required this.uid,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.username,
    this.dailyCalorieTarget = 0,
    this.weight,
    this.height,
    this.age,
    this.gender,
    this.activityLevel,
    this.bodyGoal,
  });

  // Helper untuk mendapatkan display name yang rapi
  String get displayName => username != null && username!.isNotEmpty
      ? '@${username!.toLowerCase()}'
      : '@${firstName.toLowerCase()}${lastName.toLowerCase()}';

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'username': username,
      'daily_calorie_target': dailyCalorieTarget,
      'weight': weight,
      'height': height,
      'age': age,
      'gender': gender,
      'activity_level': activityLevel,
      'body_goal': bodyGoal,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      firstName: map['first_name'] ?? '',
      lastName: map['last_name'] ?? '',
      email: map['email'] ?? '',
      username: map['username'],
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
