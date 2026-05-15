import 'dart:convert';
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart'; // Tambahkan untuk debugPrint
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AIService {
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
  
  Gunakan bahasa Indonesia. Kembalikan HANYA JSON objek tunggal { }. 
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

        // DECODE JSON
        final dynamic decoded = jsonDecode(cleanText);
        Map<String, dynamic> data;

        // SOLUSI ERROR: Cek apakah hasil adalah List atau Map
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
          'food_name': data['food_name'] ?? 'Menu Terdeteksi',
          'protein': (data['protein'] ?? 0).toDouble(),
          'carbs': (data['carbs'] ?? 0).toDouble(),
          'fats': (data['fats'] ?? 0).toDouble(),
          'calories': (data['calories'] ?? 0).toDouble(),
          'sugar': (data['sugar'] ?? 0).toDouble(),
          'water_ml': (data['water_ml'] ?? 0).toDouble(),
        };
      }
    } on TimeoutException catch (_) {
      return {'error': 'Koneksi terlalu lambat, silakan coba lagi.'};
    } catch (e) {
      debugPrint("AI Error Detail: $e");
    }
    return {};
  }
}
