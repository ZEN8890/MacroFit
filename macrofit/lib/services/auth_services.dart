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
    required String usernameHandle,
    required DateTime
    dateOfBirth, // 🟢 PARAMETER BARU: Menerima input tanggal lahir dari RegisterPage
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

        Map<String, dynamic> userDataMap = newUser.toMap();

        // Menyimpan handle yang unik (tanpa spasi, lowercase)
        userDataMap['username_handle'] = usernameHandle;

        // Menyimpan Nama Lengkap (DisplayName) secara rapi
        userDataMap['username'] = "$firstName $lastName".trim();

        // 🟢 SINKRONISASI DATABASE: Menyimpan data Date of Birth ke dokumen Firestore
        userDataMap['date_of_birth'] = dateOfBirth;

        // 🟢 SAKELAR STATUS BARU (FIX ONBOARDING MELOMPAT):
        // Menandai secara default bahwa akun baru ini BELUM menyelesaikan tahap onboarding.
        // Data ini dibaca oleh router utama untuk membelokkan user baru ke Onboarding Page.
        userDataMap['has_completed_onboarding'] = false;

        // 🟢 PRESET DEFAULT METRIK KLINIS: Mengunci struktur agar saat awal akun dibuat tidak kosong (null)
        userDataMap['weight'] = 65.0; // Default awal 65kg
        userDataMap['height'] = 170.0; // Default awal 170cm
        userDataMap['gender'] = 'Laki-laki'; // Default gender awal
        userDataMap['diet_code'] = 'healthy_lifestyle'; // Default program awal
        userDataMap['activity_multiplier'] =
            1.2; // Default tingkat aktivitas santai
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

  Future<String> updateUsernameHandle({
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

      if (userData['username_handle'] == cleanUsername) return "success";

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
          .where('username_handle', isEqualTo: cleanUsername)
          .get();

      if (usernameQuery.docs.isNotEmpty) {
        return isEnglish
            ? "⚠️ Username @$cleanUsername is already taken."
            : "⚠️ Username @$cleanUsername sudah digunakan.";
      }

      await _firestore.collection('users').doc(currentUid).update({
        'username_handle': cleanUsername,
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
