import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 🟢 LOGIKA REGISTRASI TER-UPDATE DENGAN USERNAME HANDLE
  Future<String?> userRegistration({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String usernameHandle, // 🟢 SUNTIKKAN VARIABEL BARU DI SINI
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

        // 🟢 VALIDASI AMAN SKRIPSI: Ekstrak data model ke Map bawaan kamu
        Map<String, dynamic> userDataMap = newUser.toMap();

        // Suntikkan field username secara dinamis langsung ke dalam map sebelum dilempar ke database server
        userDataMap['username_handle'] = usernameHandle;

        // Buat gabungan nama lengkap otomatis untuk kebutuhan pilar visual komunitas
        userDataMap['username'] = "$firstName $lastName".trim();

        // 🟢 Simpan data profil lengkap terpadu ke Cloud Firestore
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

  // 🟢 FUNGSI BARU: UPDATE USERNAME DENGAN BATASAN 14 HARI & CEK KEUNIKAN
  Future<String> updateUsernameHandle({
    required String currentUid,
    required String newUsername,
  }) async {
    // Bersihkan format input username baru
    final String cleanUsername = newUsername.trim().toLowerCase().replaceAll(
      ' ',
      '',
    );

    if (cleanUsername.isEmpty) {
      return "Username tidak boleh kosong.";
    }

    try {
      // 1. AMBIL DATA USER SAAT INI UNTUK CEK TIMESTAMPS
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(currentUid)
          .get();
      if (!userDoc.exists) return "Pengguna tidak ditemukan.";

      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

      // Jika username yang dimasukkan ternyata sama dengan yang sekarang, tidak usah diproses
      if (userData['username_handle'] == cleanUsername) {
        return "success"; // Anggap sukses karena tidak ada perubahan
      }

      Timestamp? lastUpdate = userData['last_username_update'] as Timestamp?;

      if (lastUpdate != null) {
        DateTime lastUpdateDateTime = lastUpdate.toDate();
        DateTime now = DateTime.now();

        // Hitung selisih hari
        int differenceInDays = now.difference(lastUpdateDateTime).inDays;

        if (differenceInDays < 14) {
          int daysLeft = 14 - differenceInDays;
          return "⏳ Anda baru saja mengubah username. Silakan tunggu $daysLeft hari lagi untuk mengubahnya kembali.";
        }
      }

      // 2. CEK APAKAH USERNAME BARU SUDAH DIAMBIL ORANG LAIN
      final usernameQuery = await _firestore
          .collection('users')
          .where('username_handle', isEqualTo: cleanUsername)
          .get();

      if (usernameQuery.docs.isNotEmpty) {
        return "⚠️ Username @$cleanUsername sudah digunakan oleh orang lain. Pilih yang lain!";
      }

      // 3. JIKA LOLOS KEDUA VALIDASI, UPDATE KE FIRESTORE
      await _firestore.collection('users').doc(currentUid).update({
        'username_handle': cleanUsername,
        'last_username_update':
            FieldValue.serverTimestamp(), // Set waktu update menjadi sekarang
      });

      return "success";
    } catch (e) {
      return "Terjadi kesalahan sistem: ${e.toString()}";
    }
  }

  // LOGIKA LOGOUT
  Future<void> userLogout() async {
    await _auth.signOut();
  }
}
