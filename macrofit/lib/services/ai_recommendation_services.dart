import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AIRecommendationService {
  final String _apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';

  Future<Map<String, dynamic>> getAIRecommendation({
    required String restaurantName,
    required String cuisineType,
    required double userTargetCalorie,
    required bool isBulking,
    required bool isEnglish,
  }) async {
    if (_apiKey.isEmpty) return {'error': 'API Key Gemini tidak ditemukan'};

    final model = GenerativeModel(
      model: 'gemini-3.1-flash-lite',
      apiKey: _apiKey,
      generationConfig: GenerationConfig(responseMimeType: 'application/json'),
    );

    String languageInstruction = isEnglish
        ? "Strictly generate the entire text values response (ai_diet_tag, ai_reason, and recommended_menus names/descriptions) in English language."
        : "Tolong generate seluruh nilai respon teks (ai_diet_tag, ai_reason, dan recommended_menus) dalam Bahasa Indonesia secara konsisten.";

    final prompt =
        '''
    Anda adalah seorang Ahli Gizi Digital profesional untuk aplikasi MacroFit.
    Tugas Anda adalah menganalisis apakah restoran berikut cocok untuk program diet pengguna dan memberikan 3 rekomendasi menu yang paling tepat secara ilmiah.

    $languageInstruction

    Data Pengguna:
    - Target Kalori Harian: $userTargetCalorie kkal
    - Status Program: ${isBulking ? "Bulking (Surplus Kalori & Tinggi Protein)" : "Cutting/Weight Loss (Defisit Kalori & Makanan Bersih)"}

    Data Restoran:
    - Nama Restoran: $restaurantName
    - Kategori Kuliner: $cuisineType

    Berikan output HARUS dalam format JSON dengan struktur seperti ini, jangan berikan teks tambahan di luar JSON:
    {
      "is_suitable": true atau false (apakah restoran ini mendukung program diet pengguna),
      "match_score": angka 1 sampai 5 (skor kecocokan restoran dengan diet pengguna),
      "ai_diet_tag": "${isEnglish ? 'Short diet category name by AI' : 'string pendek kategori diet yang disesuaikan oleh AI'}",
      "ai_reason": "${isEnglish ? 'Short reason why AI recommends or does not recommend this restaurant' : 'alasan singkat mengapa AI merekomendasikan atau tidak merekomendasikan restoran ini bagi pengguna'}",
      "recommended_menus": [
        "${isEnglish ? 'Recommended Menu Name 1 (provide brief macro estimate)' : 'Nama Menu Rekomendasi AI 1 (berikan estimasi makronutrisi singkat)'}",
        "Nama Menu Rekomendasi AI 2",
        "Nama Menu Rekomendasi AI 3"
      ]
    }
    ''';

    try {
      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);

      if (response.text != null) {
        return json.decode(response.text!);
      }
      return {'error': 'Gagal mendapatkan respons dari AI'};
    } catch (e) {
      return {'error': 'Terjadi kesalahan AI: $e'};
    }
  }

  Future<List<dynamic>> filterRestaurantListAI({
    required List<Map<String, dynamic>> rawGoogleRestaurants,
    required double userTargetCalorie,
    required bool isBulking,
    required bool isEnglish,
  }) async {
    if (_apiKey.isEmpty || rawGoogleRestaurants.isEmpty) return [];

    final model = GenerativeModel(
      model: 'gemini-3.1-flash-lite',
      apiKey: _apiKey,
      generationConfig: GenerationConfig(responseMimeType: 'application/json'),
    );

    final List<Map<String, dynamic>> simplifiedList = rawGoogleRestaurants
        .map(
          (res) => {
            'place_id': res['place_id'],
            'name': res['name'],
            'type': res['type'] ?? 'Tempat Makan',
          },
        )
        .toList();

    String bulkLanguageInstruction = isEnglish
        ? "Strictly provide the 'ai_diet_tag' text value description in English language (e.g., 'High Protein', 'Low Calories', 'Clean Eating')."
        : "Tolong berikan deskripsi nilai teks 'ai_diet_tag' dalam Bahasa Indonesia secara konsisten (Contoh: 'Tinggi Protein', 'Rendah Kalori', 'Bersih Alami').";

    final prompt =
        '''
    Anda adalah pakar nutrisi digital MacroFit. Tugas Anda adalah menganalisis daftar restoran dari Google Maps berikut dan menentukan apakah cocok dengan profil diet pengguna.

    $bulkLanguageInstruction

    Profil Diet Pengguna:
    - Target Energi Harian: $userTargetCalorie kkal
    - Tujuan Program: ${isBulking ? "Bulking (Surplus Kalori, Sangat Tinggi Protein & Karbohidrat Kompleks)" : "Cutting/Weight Loss (Defisit Kalori, Makanan Bersih Rendah Lemak & Gula)"}

    Daftar Restoran dari Google:
    ${json.encode(simplifiedList)}

    Berikan keputusan untuk SETIAP restoran. Output HARUS berupa array JSON murni tanpa teks pembuka/penutup, dengan format struktur seperti ini:
    [
      {
        "place_id": "salin_place_id_restoran_terkait",
        "is_suitable": true atau false (apakah sangat direkomendasikan untuk program diet user),
        "ai_diet_tag": "${isEnglish ? 'Short custom diet label from you' : 'Nama label diet pendek kustom dari Anda, misal: Tinggi Protein / Rendah Kalori / Bersih Alami'}"
      }
    ]
    ''';

    try {
      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);

      if (response.text != null) {
        return json.decode(response.text!);
      }
      return [];
    } catch (e) {
      print("Error AI Bulk Filter: $e");
      return [];
    }
  }
}
