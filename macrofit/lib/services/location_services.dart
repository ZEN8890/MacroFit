import 'package:geolocator/geolocator.dart';
import '../utils/global_state.dart'; // 🟢 IMPORT SAKLAR GLOBAL STATE

class LocationService {
  /// Fungsi untuk mendapatkan posisi GPS saat ini dengan dukungan dwi-bahasa
  Future<Position> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;
    final bool isEnglish = isEnglishNotifier.value;

    // 1. Cek apakah layanan lokasi di HP aktif
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error(
        isEnglish
            ? 'Location services (GPS) are disabled on your device.'
            : 'Layanan lokasi (GPS) di handphone Anda mati.',
      );
    }

    // 2. Cek status izin akses lokasi aplikasi
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error(
          isEnglish
              ? 'Location permission was denied by the user.'
              : 'Izin lokasi ditolak oleh pengguna.',
        );
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
        isEnglish
            ? 'Location permissions are permanently denied. Please enable them in your device settings.'
            : 'Izin lokasi ditolak permanen. Silakan aktifkan di pengaturan HP.',
      );
    }

    // 3. Jika aman, ambil koordinat posisi sekarang
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }
}
