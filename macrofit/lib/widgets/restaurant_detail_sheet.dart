import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Wajib di-import untuk membaca KEY peta Google
import '../services/ai_recommendation_services.dart';

class RestaurantDetailSheet extends StatelessWidget {
  final Map<String, dynamic> restaurant;
  final double distance;

  final AIRecommendationService _aiService = AIRecommendationService();

  RestaurantDetailSheet({
    super.key,
    required this.restaurant,
    required this.distance,
  });

  // 1. NAVIGASI PREMIUM FIXED: Mengunci navigasi mutlak pada ID Pin Resmi Google Maps
  Future<void> _launchMaps() async {
    final double lat = restaurant['lat'] ?? 0.0;
    final double lng = restaurant['lng'] ?? 0.0;
    final String? placeId = restaurant['place_id'];
    final String name = restaurant['name'] ?? 'Restoran';

    String encodedName = Uri.encodeComponent(name);
    String googleMapsUrl;

    if (placeId != null && placeId.isNotEmpty) {
      googleMapsUrl =
          "https://www.google.com/maps/dir/?api=1&destination=$encodedName&destination_place_id=$placeId";
    } else {
      googleMapsUrl =
          "https://www.google.com/maps/dir/?api=1&destination=$lat,$lng";
    }

    final String androidIntentUrl = placeId != null && placeId.isNotEmpty
        ? "geo:0,0?q=place_id:$placeId($encodedName)"
        : "geo:0,0?q=$lat,$lng($encodedName)";

    try {
      final Uri uri = Uri.parse(googleMapsUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        final Uri fallbackUri = Uri.parse(androidIntentUrl);
        if (await canLaunchUrl(fallbackUri)) {
          await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
        } else {
          throw 'Tidak dapat membuka Google Maps.';
        }
      }
    } catch (e) {
      debugPrint("Error Launching Maps: $e");
      await launchUrl(
        Uri.parse(
          "https://www.google.com/maps/search/?api=1&query=$encodedName",
        ),
        mode: LaunchMode.externalApplication,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // 1. Ambil koordinat dan bersihkan dari spasi gaib
    final double resLat = restaurant['lat'] ?? 0.0;
    final double resLng = restaurant['lng'] ?? 0.0;
    final String latString = resLat.toString().trim();
    final String lngString = resLng.toString().trim();

    final String currentDietType = restaurant['diet_type'] ?? 'Clean Balanced';
    final bool recommendedStatus = restaurant['recommended'] ?? false;

    // 2. PERBAIKAN UTAMA: Paksa String API Key dibersihkan menggunakan .trim()
    // Ini menjamin tidak ada spasi atau karakter '\n' yang merusak keabsahan Key di URL
    final String googleApiKey = (dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '')
        .trim();

    // 3. URL Peta Baru yang sudah steril dari karakter liar
    final String staticMapUrl =
        "https://maps.googleapis.com/maps/api/staticmap?center=$latString,$lngString&zoom=16&size=450x180&markers=color:red%7C$latString,$lngString&key=$googleApiKey";

    // Cetak ulang untuk memastikan kebersihan URL di terminal
    debugPrint("=== TESTING URL GOOGLE MAPS STATIC (CLEANED) ===");
    debugPrint(staticMapUrl);
    // Tambahkan ini sementara untuk melihat kebenaran key Anda di terminal VS Code/Android Studio
    debugPrint("=== TESTING URL GOOGLE MAPS STATIC ===");
    debugPrint(staticMapUrl);

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
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // --- BARIS NAMA RESTORAN, RATING, & TOMBOL CLOSE "X" ---
            Row(
              crossAxisAlignment: CrossAxisAlignment
                  .start, // Sejajar rata atas dengan nama restoran
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        restaurant['name'] ?? 'Nama Restoran',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Rating diletakkan di bawah nama agar ruang pojok kanan murni milik tombol X
                      Row(
                        children: [
                          const Icon(
                            Icons.star,
                            color: Colors.orange,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "${(restaurant['rating'] ?? 4.0).toStringAsFixed(1)}",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                // 🔥 TOMBOL "X" UNTUK MENUTUP SHEET SECARA INSTAN
                IconButton(
                  icon: Icon(
                    Icons.close_rounded,
                    color: colorScheme.onSurfaceVariant,
                    size: 24,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.5),
                    padding: const EdgeInsets.all(8),
                  ),
                  onPressed: () {
                    Navigator.pop(
                      context,
                    ); // Eksekusi tutup bottom sheet balik ke list utama
                  },
                ),
              ],
            ),

            Row(
              children: [
                Text(
                  "Kategori: ${restaurant['type'] ?? 'Tempat Makan'}",
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 10),
                if (recommendedStatus)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      "Sesuai Target Diet",
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 15),

            // --- VISUALISASI PETA AKTIF (GOOGLE MAPS RESMI) ---
            const Text(
              "Estimasi Lokasi Tujuan",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Container(
              height: 140,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colorScheme.outlineVariant),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.network(
                  staticMapUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(
                      child: Text(
                        "Memuat peta Google Maps...",
                        style: TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: colorScheme.primaryContainer.withValues(
                        alpha: 0.2,
                      ),
                      child: Center(
                        child: Icon(
                          Icons.map_outlined,
                          color: colorScheme.primary,
                          size: 36,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // 🔥 TAMBAHKAN BLOK KODE INI TEPAT DI BAWAH CONTAINER PETA:
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.pin_drop_rounded,
                    size: 16,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      restaurant['address'] ?? 'Alamat lengkap tidak tersedia.',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // --------------------------------------------------------
            const SizedBox(height: 15),

            // --- KARTU INFORMASI JARAK ---
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.5,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colorScheme.outlineVariant),
              ),
              child: Row(
                children: [
                  Icon(Icons.location_on, color: colorScheme.primary, size: 26),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Informasi Jarak",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "Restoran ini berjarak sekitar ${distance.toStringAsFixed(2)} km dari posisi GPS Anda saat ini.",
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // --- INTEGRASI CORE AI: REKOMENDASI MENU ADAPTIF GEMINI ---
            FutureBuilder<Map<String, dynamic>>(
              future: _aiService.getAIRecommendation(
                restaurantName: restaurant['name'] ?? 'Restoran',
                cuisineType: restaurant['type'] ?? 'Tempat Makan',
                userTargetCalorie: 2500,
                // Cek apakah string diet mengandung kata kunci Protein tinggi untuk status Bulking
                isBulking:
                    currentDietType.toLowerCase().contains('protein') ||
                    currentDietType.toLowerCase().contains('high'),
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Column(
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 12),
                          Text(
                            "Ahli Gizi AI MacroFit sedang menganalisis menu...",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // Jika terjadi error koneksi atau data null, tampilkan pesan gagal yang aman
                if (snapshot.hasError ||
                    snapshot.data == null ||
                    snapshot.data!['error'] != null) {
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      "⚠️ Gagal memuat rekomendasi menu pintar AI. Pastikan kuota internet aktif dan API Key Gemini di file .env sudah benar.",
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  );
                }

                final aiResponse = snapshot.data!;
                final String aiReason =
                    aiResponse['ai_reason'] ??
                    'Cocok untuk variasi menu diet harian.';
                final List<dynamic> aiMenus =
                    aiResponse['recommended_menus'] ?? [];

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer.withValues(
                          alpha: 0.25,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: colorScheme.primary.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Text(
                        "💡 Analisis Nutrisi AI:\n$aiReason",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: colorScheme.primary,
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    const Text(
                      "Rekomendasi Menu (Hasil Analisis AI Gemini)",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (aiMenus.isEmpty)
                      const Text(
                        "Tidak ada rekomendasi menu khusus dari AI.",
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      )
                    else
                      ...aiMenus.map(
                        (menu) => Padding(
                          padding: const EdgeInsets.only(bottom: 10.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 2.0),
                                child: Icon(
                                  Icons.auto_awesome,
                                  color: Colors.amber,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  menu.toString(),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    height: 1.3,
                                  ),
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

            // --- TOMBOL DIRECTION NAVIGASI ---
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _launchMaps,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.navigation_rounded),
                label: const Text(
                  "Mulai Rute Perjalanan (Directions)",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
