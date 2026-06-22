import 'package:geolocator/geolocator.dart';
import '../utils/global_state.dart';

class LocationService {
  Future<Position> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;
    final bool isEnglish = isEnglishNotifier.value;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error(
        isEnglish
            ? 'Location services (GPS) are disabled on your device.'
            : 'Layanan lokasi (GPS) di handphone Anda mati.',
      );
    }

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

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }
}
