import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../utils/global_state.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String?> userRegistration({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String username,
    required DateTime dateOfBirth,
  }) async {
    final bool isEnglish = isEnglishNotifier.value;
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = result.user;
      if (user != null) {
        UserModel newUser = UserModel(
          uid: user.uid,
          firstName: firstName,
          lastName: lastName,
          email: email,
        );

        //proses perubahan data user model ke dalam bentuk map untuk disimpan ke firestore
        Map<String, dynamic> userDataMap = newUser.toMap();

        userDataMap['username'] = username;
        userDataMap['full_name'] = "$firstName $lastName".trim();
        userDataMap['date_of_birth'] = dateOfBirth;
        userDataMap['has_completed_onboarding'] = false;
        //Default data user, supaya tidak null
        userDataMap['weight'] = 65.0;
        userDataMap['height'] = 170.0;
        userDataMap['gender'] = 'Laki-laki';
        userDataMap['diet_code'] = 'healthy_lifestyle';
        userDataMap['activity_multiplier'] = 1.2;
        userDataMap['target_calories'] = 2000;
        userDataMap['target_carbs'] = 275;
        userDataMap['target_proteins'] = 100;
        userDataMap['target_fats'] = 55;
        userDataMap['timestamp'] = FieldValue.serverTimestamp();

        await _firestore
            .collection("users")
            .doc(user.uid)
            .set(userDataMap, SetOptions(merge: true));

        return "success";
      }
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
    return isEnglish ? "An error occurred" : "Terjadi kesalahan";
  }

  Future<String> updateusername({
    required String currentUid,
    required String newUsername,
  }) async {
    final bool isEnglish = isEnglishNotifier.value;
    final String cleanUsername = newUsername.trim().toLowerCase().replaceAll(
      ' ',
      '',
    );

    if (cleanUsername.isEmpty) {
      return isEnglish
          ? "Username cannot be empty."
          : "Username tidak boleh kosong.";
    }

    try {
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(currentUid)
          .get();

      if (!userDoc.exists) {
        return isEnglish ? "User not found." : "Pengguna tidak ditemukan.";
      }

      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

      if (userData['username'] == cleanUsername) return "success";

      // Cek limit 14 hari
      Timestamp? lastUpdate = userData['last_username_update'] as Timestamp?;
      if (lastUpdate != null) {
        int differenceInDays = DateTime.now()
            .difference(lastUpdate.toDate())
            .inDays;
        if (differenceInDays < 14) {
          return isEnglish
              ? "⏳ You recently changed your username. Wait ${14 - differenceInDays} more days."
              : "⏳ Anda baru saja mengubah username. Tunggu ${14 - differenceInDays} hari lagi.";
        }
      }

      // Cek keunikan
      final usernameQuery = await _firestore
          .collection('users')
          .where('username', isEqualTo: cleanUsername)
          .get();

      if (usernameQuery.docs.isNotEmpty) {
        return isEnglish
            ? "⚠️ Username @$cleanUsername is already taken."
            : "⚠️ Username @$cleanUsername sudah digunakan.";
      }

      await _firestore.collection('users').doc(currentUid).update({
        'username': cleanUsername,
        'last_username_update': FieldValue.serverTimestamp(),
      });

      return "success";
    } catch (e) {
      return isEnglish
          ? "System error: ${e.toString()}"
          : "Terjadi kesalahan sistem: ${e.toString()}";
    }
  }

  Future<String?> userLogin({
    required String email,
    required String password,
  }) async {
    final bool isEnglish = isEnglishNotifier.value;
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      return "success";
    } on FirebaseAuthException catch (e) {
      debugPrint("Auth Error Code: ${e.code}");

      switch (e.code) {
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          return isEnglish
              ? "The email or password you entered is incorrect."
              : "Email atau password yang Anda masukkan salah.";
        case 'invalid-email':
          return isEnglish
              ? "Invalid email format."
              : "Format email tidak valid.";
        case 'user-disabled':
          return isEnglish
              ? "This account has been disabled."
              : "Akun ini telah dinonaktifkan.";
        case 'too-many-requests':
          return isEnglish
              ? "Too many login attempts. Please try again later."
              : "Terlalu banyak percobaan login. Silakan coba lagi nanti.";
        default:
          return isEnglish
              ? "Error during login: ${e.message}"
              : "Terjadi kesalahan saat login: ${e.message}";
      }
    } catch (e) {
      return isEnglish
          ? "System error: ${e.toString()}"
          : "Terjadi kesalahan sistem: ${e.toString()}";
    }
  }

  Future<void> userLogout() async {
    try {
      await _auth.signOut();
      debugPrint("User berhasil logout.");
    } catch (e) {
      debugPrint("Error saat logout: $e");
    }
  }
}
