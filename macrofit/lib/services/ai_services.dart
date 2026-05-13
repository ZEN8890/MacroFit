import 'dart:convert';
import 'dart:async';
import 'dart:typed_data';
import 'package:google_generative_ai/google_generative_ai.dart';

class AIService {
  static const String _basePrompt = '''
  Tugas Anda adalah menganalisis objek makanan dan minuman dalam gambar atau teks.
  
  LANGKAH ANALISIS:
  1. Identifikasi SEMUA objek makanan dan minuman.
  2. Jika YA, berikan estimasi nutrisi lengkap dengan JSON:
  {
    "is_food": true,
    "food_name": "nama menu",
    "protein": angka,
    "carbs": angka,
    "fats": angka,
    "calories": angka,
    "sugar": angka,      // TAMBAHKAN INI (dalam gram)
    "water_ml": angka    // Tetap ada untuk hidrasi
  }
  
  Gunakan bahasa Indonesia. Kembalikan HANYA JSON mentah.
''';

  final String _apiKey = "AIzaSyCcAxphCcXchMFaxoJM82xt62a7ASeWsYo";

  GenerativeModel _getModel() {
    return GenerativeModel(
      model: 'gemini-3.1-flash-lite',
      apiKey: _apiKey,
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        temperature: 0.1,
      ),
    );
  }

  Future<Map<String, dynamic>> analyzeFood(String input) async {
    if (input.isEmpty) return {};
    final model = _getModel();
    final prompt = '$_basePrompt. Input: "$input"';
    return await _executeRequest(model, [Content.text(prompt)]);
  }

  Future<Map<String, dynamic>> analyzeFoodImage(Uint8List imageBytes) async {
    final model = _getModel();
    final content = [
      Content.multi([
        TextPart(_basePrompt),
        DataPart('image/jpeg', imageBytes),
      ]),
    ];
    return await _executeRequest(model, content);
  }

  Future<Map<String, dynamic>> _executeRequest(
    GenerativeModel model,
    List<Content> content,
  ) async {
    try {
      final response = await model
          .generateContent(content)
          .timeout(const Duration(seconds: 60));

      if (response.text != null && response.text!.isNotEmpty) {
        String cleanText = response.text!
            .replaceAll('```json', '')
            .replaceAll('```', '')
            .trim();

        Map<String, dynamic> data = jsonDecode(cleanText);

        if (data['is_food'] == false) {
          return {'is_food': false};
        }

        // Mapping hasil ke struktur yang konsisten
        return {
          'is_food': true,
          'food_name': data['food_name'] ?? 'Menu Terdeteksi',
          'protein': data['protein'] ?? 0,
          'carbs': data['carbs'] ?? 0,
          'fats': data['fats'] ?? 0,
          'calories': data['calories'] ?? 0,
          'sugar': data['sugar'] ?? 0, // Mapping baru
          'water_ml': data['water_ml'] ?? 0,
        };
      }
    } on TimeoutException catch (_) {
      return {'error': 'Koneksi terlalu lambat, silakan coba lagi.'};
    } catch (e) {
      print("AI Error: $e");
    }
    return {};
  }
}
