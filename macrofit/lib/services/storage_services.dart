import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../firebase_options.dart';
import '../utils/global_state.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instanceFor(
    app: Firebase.app(),
    bucket: DefaultFirebaseOptions.currentPlatform.storageBucket,
  );

  Future<String> uploadImage(XFile imageFile, String folderName) async {
    final bool isEnglish = isEnglishNotifier.value;
    try {
      File file = File(imageFile.path);

      if (!await file.exists()) {
        throw Exception(
          isEnglish
              ? 'Local image file not found.'
              : 'File gambar lokal tidak ditemukan.',
        );
      }

      String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';

      Reference ref = _storage.ref().child(folderName).child(fileName);

      UploadTask uploadTask = ref.putFile(
        file,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      TaskSnapshot snapshot = await uploadTask;

      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception(
        isEnglish
            ? 'Failed to upload image to Storage: $e'
            : 'Gagal mengunggah gambar ke Storage: $e',
      );
    }
  }
}
