import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../services/ai_recommendation_services.dart';
import '../utils/global_state.dart';

class RestaurantDetailSheet extends StatefulWidget {
  final Map<String, dynamic> restaurant;
  final double distance;

  const RestaurantDetailSheet({
    super.key,
    required this.restaurant,
    required this.distance,
  });

  @override
  State<RestaurantDetailSheet> createState() => _RestaurantDetailSheetState();
}

class _RestaurantDetailSheetState extends State<RestaurantDetailSheet> {
  final AIRecommendationService _aiService = AIRecommendationService();
  Future<Map<String, dynamic>>? _aiRecommendationFuture;

  @override
  void initState() {
    super.initState();
    _aiRecommendationFuture = _aiService.getAIRecommendation(
      restaurantName: widget.restaurant['name'] ?? 'Restoran',
      cuisineType: widget.restaurant['type'] ?? 'Tempat Makan',
      userTargetCalorie: 2500,
      isBulking: false,
      isEnglish: isEnglishNotifier.value,
    );
  }

  Future<void> _launchMaps() async {
    final double lat = widget.restaurant['lat'] ?? 0.0;
    final double lng = widget.restaurant['lng'] ?? 0.0;
    final String name = widget.restaurant['name'] ?? 'Restaurant';
    String encodedName = Uri.encodeComponent(name);
    String androidIntentUrl = "geo:0,0?q=$lat,$lng($encodedName)";

    try {
      await launchUrl(
        Uri.parse(androidIntentUrl),
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      debugPrint("Error Launching Maps: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final String googleApiKey = (dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '')
        .trim();
    final double resLat = widget.restaurant['lat'] ?? 0.0;
    final double resLng = widget.restaurant['lng'] ?? 0.0;
    final String staticMapUrl =
        "https://maps.googleapis.com/maps/api/staticmap?center=$resLat,$resLng&zoom=16&size=450x180&markers=color:red%7C$resLat,$resLng&key=$googleApiKey";

    return ValueListenableBuilder<bool>(
      valueListenable: isEnglishNotifier,
      builder: (context, englishActive, child) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colorScheme.onSurfaceVariant.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.restaurant['name'] ?? 'Restaurant',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          Row(
                            children: [
                              const Icon(
                                Icons.star,
                                color: Colors.orange,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                (widget.restaurant['rating'] ?? 4.0)
                                    .toStringAsFixed(1),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                Text(
                  englishActive ? "Location Preview" : "Estimasi Lokasi Tujuan",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    staticMapUrl,
                    height: 140,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),

                const SizedBox(height: 15),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.location_on, color: colorScheme.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          englishActive
                              ? "Distance: ${widget.distance.toStringAsFixed(2)} km"
                              : "Jarak: ${widget.distance.toStringAsFixed(2)} km",
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                FutureBuilder<Map<String, dynamic>>(
                  future: _aiRecommendationFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 20.0),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }
                    if (!snapshot.hasData) return const SizedBox.shrink();

                    final ai = snapshot.data!;
                    final List<dynamic> aiMenus = ai['recommended_menus'] ?? [];

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer.withOpacity(
                              0.25,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            "💡 ${englishActive ? 'AI Nutrition Analysis:' : 'Analisis Nutrisi AI:'}\n${ai['ai_reason'] ?? ''}",
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.primary,
                              height: 1.4,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          englishActive
                              ? "Recommended Menu:"
                              : "Rekomendasi Menu:",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        ...aiMenus.map(
                          (menu) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.auto_awesome,
                                  color: Colors.amber,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    menu.toString(),
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 25),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _launchMaps,
                    icon: const Icon(Icons.navigation_rounded),
                    label: Text(
                      englishActive
                          ? "Start Navigation"
                          : "Mulai Rute Perjalanan",
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
