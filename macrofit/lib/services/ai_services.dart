import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart'; // Tambahkan untuk debugPrint
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AIService {
  // 🟢 MODIFIKASI: _basePrompt diubah menjadi instruksi inti, bahasa diatur dinamis di bawah
  static const String _basePrompt = '''
  Tugas Anda adalah menganalisis objek makanan dan minuman dalam gambar atau teks.
  
  LANGKAH ANALISIS:
  1. Identifikasi SEMUA objek makanan dan minuman.
  2. Jika YA, berikan estimasi nutrisi dalam format JSON tunggal.

  ATURAN KHUSUS VARIABEL:
  - "water_ml": HANYA diisi jika objek adalah MINUMAN (seperti air mineral, kopi, teh, jus) atau sup cair. Jika objek adalah MAKANAN PADAT (seperti telur, nasi, roti, daging), wajib isi 0 meskipun makanan tersebut mengandung air secara biologis.
  - "sugar": Estimasi kandungan gula dalam gram.
  - "is_food": Set true jika objek adalah makanan/minuman, false jika benda mati lainnya.

  FORMAT JSON:
  {
    "is_food": true,
    "food_name": "nama menu",
    "protein": angka,
    "carbs": angka,
    "fats": angka,
    "calories": angka,
    "sugar": angka,
    "water_ml": angka
  }
  
  Kembalikan HANYA JSON objek tunggal { }. 
  DILARANG menggunakan format List [ ] atau menambahkan teks penjelasan di luar JSON.
''';

  final _apiKey = dotenv.env['GEMINI_API_KEY']!;

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

  // 🟢 UPDATE PARAMETER: Menambahkan isEnglish wajib
  Future<Map<String, dynamic>> analyzeFood(
    String input, {
    required bool isEnglish,
  }) async {
    if (input.isEmpty) return {};
    final model = _getModel();

    // Sinkronisasi instruksi bahasa prompt teks
    String languageInstruction = isEnglish
        ? "Strictly output the 'food_name' string value in English language."
        : "Gunakan bahasa Indonesia untuk nilai properti 'food_name'.";

    final prompt = '$_basePrompt\n$languageInstruction\nInput: "$input"';
    return await _executeRequest(model, [Content.text(prompt)], isEnglish);
  }

  // 🟢 UPDATE PARAMETER: Menambahkan isEnglish wajib
  Future<Map<String, dynamic>> analyzeFoodImage(
    Uint8List imageBytes, {
    required bool isEnglish,
  }) async {
    final model = _getModel();

    // Sinkronisasi instruksi bahasa prompt gambar
    String languageInstruction = isEnglish
        ? "Strictly output the 'food_name' string value in English language."
        : "Gunakan bahasa Indonesia untuk nilai properti 'food_name'.";

    final fullPrompt = '$_basePrompt\n$languageInstruction';

    final content = [
      Content.multi([TextPart(fullPrompt), DataPart('image/jpeg', imageBytes)]),
    ];
    return await _executeRequest(model, content, isEnglish);
  }

  Future<Map<String, dynamic>> _executeRequest(
    GenerativeModel model,
    List<Content> content,
    bool isEnglish,
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

        // DECODE JSON
        final dynamic decoded = jsonDecode(cleanText);
        Map<String, dynamic> data;

        if (decoded is List) {
          if (decoded.isEmpty) return {};
          data = decoded.first as Map<String, dynamic>;
        } else {
          data = decoded as Map<String, dynamic>;
        }

        if (data['is_food'] == false) {
          return {'is_food': false};
        }

        return {
          'is_food': true,
          'food_name':
              data['food_name'] ??
              (isEnglish ? 'Detected Menu' : 'Menu Terdeteksi'),
          'protein': (data['protein'] ?? 0).toDouble(),
          'carbs': (data['carbs'] ?? 0).toDouble(),
          'fats': (data['fats'] ?? 0).toDouble(),
          'calories': (data['calories'] ?? 0).toDouble(),
          'sugar': (data['sugar'] ?? 0).toDouble(),
          'water_ml': (data['water_ml'] ?? 0).toDouble(),
        };
      }
    } on TimeoutException catch (_) {
      return {
        'error': isEnglish
            ? 'Connection too slow, please try again.'
            : 'Koneksi terlalu lambat, silakan coba lagi.',
      };
    } catch (e) {
      debugPrint("AI Error Detail: $e");
    }
    return {};
  }
}
