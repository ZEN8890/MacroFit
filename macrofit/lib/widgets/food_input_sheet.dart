import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/ai_services.dart';
import '../utils/notification_helper.dart';
import '../utils/global_state.dart'; // 100% Mengikat perubahan dari isEnglishNotifier

class FoodInputSheet extends StatefulWidget {
  const FoodInputSheet({super.key});

  @override
  State<FoodInputSheet> createState() => _FoodInputSheetState();
}

class _FoodInputSheetState extends State<FoodInputSheet> {
  final TextEditingController _foodController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    Notify.error(context, message);
  }

  Future<void> _handleResult(Map<String, dynamic> result) async {
    final bool currentLangEn = isEnglishNotifier.value;

    if (result.containsKey('is_food') && result['is_food'] == false) {
      Notify.error(
        context,
        currentLangEn
            ? "Sorry, that doesn't look like food."
            : "Maaf, itu tidak terlihat seperti makanan.",
      );
      return;
    }

    if (result.isNotEmpty && result.containsKey('calories')) {
      if (mounted) {
        Navigator.pop(context, result);
      }
    } else {
      Notify.error(
        context,
        currentLangEn
            ? "Failed to analyze nutrition."
            : "Gagal menganalisis nutrisi.",
      );
    }
  }

  Future<void> _handleCameraScan() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 40,
        maxWidth: 1080,
      );
      if (photo == null) return;

      setState(() => _isLoading = true);
      final bytes = await photo.readAsBytes();

      // 🟢 PERBAIKAN UTAMA: Menyuntikkan parameter isEnglish secara dinamis
      final result = await AIService().analyzeFoodImage(
        bytes,
        isEnglish: isEnglishNotifier.value,
      );
      await _handleResult(result);
    } catch (e) {
      if (mounted) {
        Notify.error(
          context,
          isEnglishNotifier.value ? "Camera error: $e" : "Kesalahan kamera: $e",
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleAnalyze() async {
    final input = _foodController.text.trim();
    if (input.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      // 🟢 PERBAIKAN UTAMA: Menyuntikkan parameter isEnglish secara dinamis
      final result = await AIService().analyzeFood(
        input,
        isEnglish: isEnglishNotifier.value,
      );
      await _handleResult(result);
    } catch (e) {
      if (mounted) {
        Notify.error(
          context,
          isEnglishNotifier.value
              ? "Failed to process text: $e"
              : "Gagal memproses teks: $e",
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // 🟢 REAKTIF MULTI-BAHASA: Membungkus widget dengan ValueListenableBuilder agar UI langsung merespons switch profil
    return ValueListenableBuilder<bool>(
      valueListenable: isEnglishNotifier,
      builder: (context, englishActive, child) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 30,
            left: 20,
            right: 20,
            top: 15,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white10 : Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 25),
              Text(
                // 🟢 DINAMIS MULTI-BAHASA
                englishActive ? "Log Nutrition" : "Catat Nutrisi",
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _foodController,
                enabled: !_isLoading,
                decoration: InputDecoration(
                  // 🟢 DINAMIS MULTI-BAHASA
                  hintText: englishActive
                      ? "Example: 1 portion of chicken satay"
                      : "Contoh: 1 porsi sate ayam",
                  prefixIcon: IconButton(
                    icon: Icon(
                      Icons.camera_alt_rounded,
                      color: theme.primaryColor,
                    ),
                    onPressed: _isLoading ? null : _handleCameraScan,
                  ),
                  suffixIcon: _isLoading
                      ? const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : IconButton(
                          icon: Icon(
                            Icons.send_rounded,
                            color: theme.primaryColor,
                          ),
                          onPressed: _handleAnalyze,
                        ),
                ),
                onSubmitted: (_) => _handleAnalyze(),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _foodController.dispose();
    super.dispose();
  }
}
