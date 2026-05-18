import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart'; // 1. Pastikan package dotenv di-import

class RestaurantServices {
  // 2. Ambil nilai API Key secara dinamis dari file env Anda
  // Jika nama filenya 'key.env', pastikan di main.dart Anda sudah memanggil dotenv.load(fileName: "key.env")
  final String _apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';

  Future<List<Map<String, dynamic>>> fetchRestaurantsFromGoogle(
    double userLat,
    double userLng,
  ) async {
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
          // Di dalam file restaurant_services.dart, pada loop 'for (var element in results)'
          if (element['business_status'] == 'OPERATIONAL') {
            double resLat = element['geometry']['location']['lat'];
            double resLng = element['geometry']['location']['lng'];

            String dietTag = 'High Protein';

            tempRestaurants.add({
              'name': element['name'],
              'type': element['types']?[0] ?? 'Tempat Makan',
              'diet_type': dietTag,
              'lat': resLat,
              'lng': resLng,
              'rating': (element['rating'] ?? 4.0).toDouble(),
              'place_id': element['place_id'],
              'user_ratings_total': element['user_ratings_total'] ?? 0,
              'address': element['vicinity'] ?? 'Alamat tidak tersedia',
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
