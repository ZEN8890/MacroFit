import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../utils/global_state.dart'; // 🟢 IMPORT SAKLAR GLOBAL STATE

class RestaurantServices {
  // Ambil nilai API Key secara dinamik dari file env
  final String _apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';

  Future<List<Map<String, dynamic>>> fetchRestaurantsFromGoogle(
    double userLat,
    double userLng,
  ) async {
    final bool isEnglish = isEnglishNotifier.value;

    // Jalankan pengecekan validitas key demi keamanan skripsi Anda
    if (_apiKey.isEmpty) {
      print("Warning: GOOGLE_MAPS_API_KEY tidak ditemukan di file .env Anda!");
      return [];
    }

    final String url =
        "https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=$userLat,$userLng&radius=3000&type=restaurant&key=$_apiKey";

    List<Map<String, dynamic>> tempRestaurants = [];

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List results = data['results'] ?? [];

        for (var element in results) {
          if (element['business_status'] == 'OPERATIONAL') {
            double resLat = element['geometry']['location']['lat'];
            double resLng = element['geometry']['location']['lng'];

            String dietTag = 'High Protein';

            tempRestaurants.add({
              'name': element['name'],
              // 🟢 DINAMIS MULTI-BAHASA PADA FALLBACK TIPE RESTORAN KOSONG
              'type':
                  element['types']?[0] ??
                  (isEnglish ? 'Eatery' : 'Tempat Makan'),
              'diet_type': dietTag,
              'lat': resLat,
              'lng': resLng,
              'rating': (element['rating'] ?? 4.0).toDouble(),
              'place_id': element['place_id'],
              'user_ratings_total': element['user_ratings_total'] ?? 0,
              // 🟢 DINAMIS MULTI-BAHASA PADA ALAMAT FALLBACK VICINITY GOOGLE MAPS KOSONG
              'address':
                  element['vicinity'] ??
                  (isEnglish
                      ? 'Address not available'
                      : 'Alamat tidak tersedia'),
            });
          }
        }
      }
    } catch (e) {
      print("Error Fetching Google Places: $e");
    }
    return tempRestaurants;
  }
}
