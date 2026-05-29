import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import '../services/location_services.dart';
import '../services/restaurant_services.dart';
import '../widgets/restaurant_card.dart';
import '../services/ai_recommendation_services.dart';
import '../utils/global_state.dart'; // Mengikat notifier global state

class RestaurantPage extends StatefulWidget {
  const RestaurantPage({super.key});

  @override
  State<RestaurantPage> createState() => _RestaurantPageState();
}

class _RestaurantPageState extends State<RestaurantPage> {
  final LocationService _locationService = LocationService();
  final RestaurantServices _restaurantServices = RestaurantServices();
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
      final user = FirebaseAuth.instance.currentUser;
      double userTargetCalorie = 2000;

      if (user != null) {
        var userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (userDoc.exists && userDoc.data() != null) {
          userTargetCalorie = (userDoc.data()!['target_calories'] ?? 2000)
              .toDouble();
        }
      }

      bool isBulking = userTargetCalorie > 2800;

      Position position = await _locationService.getCurrentLocation();
      double lat = position.latitude;
      double lng = position.longitude;

      final List<Map<String, dynamic>> googleRawResults =
          await _restaurantServices.fetchRestaurantsFromGoogle(lat, lng);

      final List<dynamic> aiAnalysisList = await _aiService
          .filterRestaurantListAI(
            rawGoogleRestaurants: googleRawResults,
            userTargetCalorie: userTargetCalorie,
            isBulking: isBulking,
            isEnglish: isEnglishNotifier.value,
          );

      List<Map<String, dynamic>> tempRestaurants = [];

      for (var element in googleRawResults) {
        double resRating = element['rating'] ?? 0.0;
        int totalReviews = element['user_ratings_total'] ?? 0;

        if (resRating >= 4.0 && totalReviews > 10) {
          final aiMatch = aiAnalysisList.firstWhere(
            (aiRes) => aiRes['place_id'] == element['place_id'],
            orElse: () => null,
          );

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
            'diet_type': dietTag,
            'distance': distanceInMeters / 1000,
            'rating': resRating,
            'lat': resLat,
            'lng': resLng,
            'recommended': isHighlyRecommended,
            'place_id': element['place_id'],
            // 🟢 TRANSLASI ALAMAT FALLBACK KOSONG
            'address':
                element['address'] ??
                (isEnglishNotifier.value
                    ? 'Address not available'
                    : 'Alamat tidak tersedia'),
          });
        }
      }

      tempRestaurants.sort((a, b) {
        if (a['recommended'] == true && b['recommended'] == false) return -1;
        if (a['recommended'] == false && b['recommended'] == true) return 1;
        return (a['distance'] as double).compareTo(b['distance'] as double);
      });

      if (!mounted) return;

      setState(() {
        _dynamicRestaurants = tempRestaurants;
        _isLoading = false;
      });
    } catch (e) {
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
    final theme = Theme.of(context);

    // 🟢 REAKTIF MULTI-BAHASA: Membungkus seluruh halaman Restoran dengan ValueListenableBuilder
    return ValueListenableBuilder<bool>(
      valueListenable: isEnglishNotifier,
      builder: (context, englishActive, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text(
              // 🟢 TITLE APPBAR DWI-BAHASA
              englishActive
                  ? "Nearby Restaurants"
                  : "Restoran Terdekat (Google API)",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          backgroundColor: theme.scaffoldBackgroundColor,
          body: _isLoading
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(
                        // 🟢 INDIKATOR LOADING DWI-BAHASA
                        englishActive
                            ? "Finding official Google restaurants nearby..."
                            : "Mencari restoran resmi Google di sekitarmu...",
                      ),
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
                          label: Text(
                            englishActive ? "Try Again" : "Coba Lagi",
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : _dynamicRestaurants.isEmpty
              ? RefreshIndicator(
                  color: theme.primaryColor,
                  onRefresh: _fetchNearbyRestaurants,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: SizedBox(
                      height: 300,
                      child: Center(
                        child: Text(
                          // 🟢 FALLBACK RADIUS DWI-BAHASA
                          englishActive
                              ? "No restaurants detected within a 3 km radius."
                              : "Tidak ada tempat makan terdeteksi dalam radius 3 km.",
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                )
              : RefreshIndicator(
                  color: theme.primaryColor,
                  onRefresh: _fetchNearbyRestaurants,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: _dynamicRestaurants.length,
                    itemBuilder: (context, index) {
                      final res = _dynamicRestaurants[index];
                      double distance = res['distance'] ?? 0.0;

                      return RestaurantCard(
                        restaurant: res,
                        distance: distance,
                      );
                    },
                  ),
                ),
        );
      },
    );
  }
}
