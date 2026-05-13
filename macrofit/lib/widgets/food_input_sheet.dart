import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/ai_services.dart';

class FoodInputSheet extends StatefulWidget {
  const FoodInputSheet({super.key});

  @override
  State<FoodInputSheet> createState() => _FoodInputSheetState();
}

class _FoodInputSheetState extends State<FoodInputSheet> {
  final TextEditingController _foodController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  // --- HELPER SNACKBAR ---
  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 110,
          left: 20,
          right: 20,
        ),
      ),
    );
  }

  // --- PROSES HASIL AI (Hanya Kirim Balik ke Home) ---
  Future<void> _handleResult(Map<String, dynamic> result) async {
    if (result.containsKey('is_food') && result['is_food'] == false) {
      _showErrorSnackBar("Maaf, itu tidak terlihat seperti makanan.");
      return;
    }

    if (result.isNotEmpty && result.containsKey('calories')) {
      if (mounted) {
        // KUNCI: Navigator.pop mengirim data ke HomePage.
        // HomePage yang akan menangani verifikasi & simpan ke Firestore.
        Navigator.pop(context, result);
      }
    } else {
      _showErrorSnackBar("Gagal menganalisis nutrisi.");
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
      final result = await AIService().analyzeFoodImage(bytes);
      await _handleResult(result);
    } catch (e) {
      _showErrorSnackBar("Kesalahan kamera.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleAnalyze() async {
    final input = _foodController.text.trim();
    if (input.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final result = await AIService().analyzeFood(input);
      await _handleResult(result);
    } catch (e) {
      _showErrorSnackBar("Gagal memproses teks.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
            "Catat Nutrisi",
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _foodController,
            enabled: !_isLoading,
            decoration: InputDecoration(
              hintText: "Contoh: 1 porsi sate ayam",
              prefixIcon: IconButton(
                icon: Icon(Icons.camera_alt_rounded, color: theme.primaryColor),
                onPressed: _isLoading ? null : _handleCameraScan,
              ),
              suffixIcon: _isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : IconButton(
                      icon: Icon(Icons.send_rounded, color: theme.primaryColor),
                      onPressed: _handleAnalyze,
                    ),
            ),
            onSubmitted: (_) => _handleAnalyze(),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _foodController.dispose();
    super.dispose();
  }
}
