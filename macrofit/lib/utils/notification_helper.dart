import 'package:flutter/material.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';

class Notify {
  // Notifikasi untuk pesan sukses (Hijau)
  static void success(BuildContext context, String message) {
    showTopSnackBar(
      Overlay.of(context),
      CustomSnackBar.success(
        message: message,
        backgroundColor: Colors.green, // Anda bisa menyesuaikan warna
      ),
    );
  }

  // Notifikasi untuk pesan error (Merah)
  static void error(BuildContext context, String message) {
    showTopSnackBar(
      Overlay.of(context),
      CustomSnackBar.error(message: message),
    );
  }

  // Notifikasi untuk info/warning (Oranye/Kuning)
  static void warning(BuildContext context, String message) {
    showTopSnackBar(
      Overlay.of(context),
      CustomSnackBar.info(
        message: message,
        backgroundColor: Colors.orangeAccent,
      ),
    );
  }
}
