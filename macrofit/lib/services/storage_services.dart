import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
// 🔥 IMPORT FILE OPTIONS AGAR BUCKET MEMBACA OTOMATIS DARI CONFIGURE CLI
import '../firebase_options.dart';

class StorageService {
  // 🔥 SOLUSI ANTI-GAGAL: Mengambil string storageBucket langsung dari file konfigurasi resmi
  // Ini menghindari typo/salah format domain antara .appspot.com atau .firebasestorage.app
  final FirebaseStorage _storage = FirebaseStorage.instanceFor(
    app: Firebase.app(),
    bucket: DefaultFirebaseOptions.currentPlatform.storageBucket,
  );

  /// Fungsi untuk mengunggah gambar ke Firebase Storage dan mengembalikan Download URL berupa String
  Future<String> uploadImage(XFile imageFile, String folderName) async {
    try {
      File file = File(imageFile.path);

      if (!await file.exists()) {
        throw Exception('File gambar lokal tidak ditemukan.');
      }

      // Membuat nama file unik berbasis milidetik agar aman dari duplikasi
      String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';

      // Membuat referensi root path penampung media secara eksplisit
      Reference ref = _storage.ref().child(folderName).child(fileName);

      // Mulai proses upload dengan menyisipkan tipe konten metadata agar lolos filter server
      UploadTask uploadTask = ref.putFile(
        file,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      TaskSnapshot snapshot = await uploadTask;

      // Mengambil tautan URL download publik setelah sukses terunggah
      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('Gagal mengunggah gambar ke Storage: $e');
    }
  }
}
