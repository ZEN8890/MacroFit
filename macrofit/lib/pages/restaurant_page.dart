import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import '../services/location_services.dart';
import '../services/restaurant_services.dart';
import '../widgets/restaurant_card.dart';
import '../services/ai_recommendation_services.dart';

class RestaurantPage extends StatefulWidget {
  const RestaurantPage({super.key});

  @override
  State<RestaurantPage> createState() => _RestaurantPageState();
}

class _RestaurantPageState extends State<RestaurantPage> {
  final LocationService _locationService = LocationService();
  final RestaurantServices _restaurantServices = RestaurantServices();

  // 🔥 SOLUSI ERROR UNDEFINED: Daftarkan instance AI Service di sini
  final AIRecommendationService _aiService = AIRecommendationService();

  List<Map<String, dynamic>> _dynamicRestaurants = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchNearbyRestaurants();
  }

  Future<void> _fetchNearbyRestaurants() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // A. Ambil Target Kalori User dari Firestore secara real-time
      final user = FirebaseAuth.instance.currentUser;
      double userTargetCalorie = 2000; // Default jika data tidak ditemukan

      if (user != null) {
        var userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (userDoc.exists && userDoc.data() != null) {
          userTargetCalorie = (userDoc.data()!['daily_calorie_target'] ?? 2000)
              .toDouble();
        }
      }

      // Tentukan status tipe diet berdasarkan target kalori (Konsep Rekomendasi Pintar Skripsi)
      bool isBulking = userTargetCalorie > 2800;

      // 1. Ambil koordinat GPS HP asli via LocationService Anda
      Position position = await _locationService.getCurrentLocation();
      double lat = position.latitude;
      double lng = position.longitude;

      // 2. Panggil Google Places API melalui file service baru Anda
      final List<Map<String, dynamic>> googleRawResults =
          await _restaurantServices.fetchRestaurantsFromGoogle(lat, lng);

      // 3. TEMBAK AI SECARA MASSAL UNTUK MENANDAI RESTORAN YANG COCOK
      final List<dynamic>
      aiAnalysisList = await _aiService.filterRestaurantListAI(
        rawGoogleRestaurants: googleRawResults,
        // PERBAIKAN: Nilai di bawah ini sekarang dinamis mengikuti data Firestore user, bukan hardcoded 2500 lagi
        userTargetCalorie: userTargetCalorie,
        isBulking: isBulking,
      );

      List<Map<String, dynamic>> tempRestaurants = [];

      // 4. Masukkan data ke UI List dengan tanda dari AI Gemini
      for (var element in googleRawResults) {
        double resRating = element['rating'] ?? 0.0;
        int totalReviews = element['user_ratings_total'] ?? 0;

        // Filter dasar keaslian rating (tetap dipertahankan agar terbebas dari tempat abal-abal)
        if (resRating >= 4.0 && totalReviews > 10) {
          // MENCARI HASIL ANALISIS AI UNTUK RESTORAN INI
          final aiMatch = aiAnalysisList.firstWhere(
            (aiRes) => aiRes['place_id'] == element['place_id'],
            orElse: () => null,
          );

          // Ambil keputusan dari otak AI Gemini 3.1 Flash Lite
          bool isHighlyRecommended = aiMatch != null
              ? (aiMatch['is_suitable'] ?? false)
              : false;
          String dietTag = aiMatch != null
              ? (aiMatch['ai_diet_tag'] ?? 'Clean Eating')
              : 'Clean Eating';

          double resLat = element['lat'];
          double resLng = element['lng'];
          double distanceInMeters = Geolocator.distanceBetween(
            lat,
            lng,
            resLat,
            resLng,
          );

          tempRestaurants.add({
            'name': element['name'],
            'type': element['type'],
            'diet_type': dietTag, // Menggunakan tag cerdas buatan AI Gemini
            'distance': distanceInMeters / 1000,
            'rating': resRating,
            'lat': resLat,
            'lng': resLng,
            'recommended':
                isHighlyRecommended, // Menandai restoran yang lolos sensor diet AI
            'place_id': element['place_id'],
            'address': element['address'] ?? 'Alamat tidak tersedia',
          });
        }
      }

      // 5. PERBAIKAN SORTING: Prioritaskan yang direkomendasikan AI (true didepan), lalu urutkan jarak terdekat
      tempRestaurants.sort((a, b) {
        if (a['recommended'] == true && b['recommended'] == false) return -1;
        if (a['recommended'] == false && b['recommended'] == true) return 1;
        // Jika status rekomendasinya sama, urutkan berdasarkan yang jaraknya paling dekat
        return (a['distance'] as double).compareTo(b['distance'] as double);
      });

      // 🔥 PERBAIKAN: Cek apakah widget masih aktif di layar sebelum memanggil setState
      if (!mounted) return;

      setState(() {
        _dynamicRestaurants = tempRestaurants;
        _isLoading = false;
      });
    } catch (e) {
      // 🔥 PERBAIKAN: Lakukan proteksi yang sama pada catch error block
      if (!mounted) return;

      setState(() {
        _errorMessage = e.toString().replaceAll("Exception:", "");
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Restoran Terdekat (Google API)",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchNearbyRestaurants,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text("Mencari restoran resmi Google di sekitarmu..."),
                ],
              ),
            )
          : _errorMessage != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                key: const Key('error_state'),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.gpp_bad_outlined,
                      size: 64,
                      color: colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: colorScheme.error),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _fetchNearbyRestaurants,
                      icon: const Icon(Icons.refresh),
                      label: const Text("Coba Lagi"),
                    ),
                  ],
                ),
              ),
            )
          : _dynamicRestaurants.isEmpty
          ? const Center(
              child: Text(
                "Tidak ada tempat makan terdeteksi dalam radius 3 km.",
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _dynamicRestaurants.length,
              itemBuilder: (context, index) {
                final res = _dynamicRestaurants[index];
                double distance = res['distance'] ?? 0.0;

                return RestaurantCard(restaurant: res, distance: distance);
              },
            ),
    );
  }
}
