import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String?> userRegistration({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String usernameHandle,
  }) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = result.user;
      if (user != null) {
        // 🟢 FIX: Pastikan model UserModel Anda di sini tidak menimpa handle secara salah
        UserModel newUser = UserModel(
          uid: user.uid,
          firstName: firstName,
          lastName: lastName,
          email: email,
        );

        Map<String, dynamic> userDataMap = newUser.toMap();

        // Menyimpan handle yang unik (tanpa spasi, lowercase)
        userDataMap['username_handle'] = usernameHandle;

        // Menyimpan Nama Lengkap (DisplayName)
        // Jika Anda ingin mengubah ini, cukup ganti bagian ini
        userDataMap['username'] = "$firstName $lastName".trim();

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
    return "Terjadi kesalahan";
  }

  // 🟢 PERBAIKAN: Update juga fungsi updateUsernameHandle agar
  // sinkron dengan display name jika diperlukan
  Future<String> updateUsernameHandle({
    required String currentUid,
    required String newUsername,
  }) async {
    final String cleanUsername = newUsername.trim().toLowerCase().replaceAll(
      ' ',
      '',
    );

    if (cleanUsername.isEmpty) return "Username tidak boleh kosong.";

    try {
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(currentUid)
          .get();
      if (!userDoc.exists) return "Pengguna tidak ditemukan.";

      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

      if (userData['username_handle'] == cleanUsername) return "success";

      // Cek limit 14 hari
      Timestamp? lastUpdate = userData['last_username_update'] as Timestamp?;
      if (lastUpdate != null) {
        int differenceInDays = DateTime.now()
            .difference(lastUpdate.toDate())
            .inDays;
        if (differenceInDays < 14) {
          return "⏳ Anda baru saja mengubah username. Tunggu ${14 - differenceInDays} hari lagi.";
        }
      }

      // Cek keunikan
      final usernameQuery = await _firestore
          .collection('users')
          .where('username_handle', isEqualTo: cleanUsername)
          .get();

      if (usernameQuery.docs.isNotEmpty) {
        return "⚠️ Username @$cleanUsername sudah digunakan.";
      }

      await _firestore.collection('users').doc(currentUid).update({
        'username_handle': cleanUsername,
        'last_username_update': FieldValue.serverTimestamp(),
      });

      return "success";
    } catch (e) {
      return "Terjadi kesalahan sistem: ${e.toString()}";
    }
  }

  Future<String?> userLogin({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return "success";
    } on FirebaseAuthException catch (e) {
      // 🟢 Pesan error yang digeneralisasi untuk keamanan
      if (e.code == 'user-not-found' ||
          e.code == 'wrong-password' ||
          e.code == 'invalid-credential') {
        return "Email atau password yang Anda masukkan salah.";
      } else if (e.code == 'invalid-email') {
        return "Format email tidak valid.";
      } else if (e.code == 'user-disabled') {
        return "Akun ini telah dinonaktifkan.";
      } else {
        return "Terjadi kesalahan saat login. Silakan coba lagi.";
      }
    } catch (e) {
      return "Terjadi kesalahan sistem: ${e.toString()}";
    }
  }

  Future<void> userLogout() async {
    await _auth.signOut();
  }
}
