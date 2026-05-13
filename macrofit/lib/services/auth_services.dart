import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  // Masukkan instance ke dalam class agar lebih terisolasi (Encapsulation)
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // LOGIKA REGISTRASI
  Future<String?> userRegistration({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
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

        await _firestore
            .collection("users")
            .doc(user.uid)
            .set(newUser.toMap(), SetOptions(merge: true));
        return "success";
      }
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
    return "Terjadi kesalahan";
  }

  // LOGIKA LOGIN
  Future<String?> userLogin({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        return "success";
      }
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return "Terjadi kesalahan sistem: ${e.toString()}";
    }
    return "Gagal melakukan login";
  }

  // LOGIKA LOGOUT
  Future<void> userLogout() async {
    await _auth.signOut();
  }
}
