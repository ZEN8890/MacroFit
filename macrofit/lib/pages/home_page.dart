import 'package:flutter/material.dart';
import '../models/nutrition_model.dart';
import '../widgets/nutrition_progress_bar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/database_services.dart';
import '../services/ai_services.dart';
import '../widgets/food_input_sheet.dart';
import '../widgets/Daily_Insight_banner.dart';
import '../widgets/welcome_header.dart';
import '../widgets/calorie_target_card.dart';
import '../widgets/nutritional_card.dart';
import '../widgets/water_tracker_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Map<String, dynamic>? _tempFoodData;
  bool _isSaving = false;

  void _showVerificationCard(Map<String, dynamic> data) {
    setState(() {
      _tempFoodData = data;
    });
  }

  void _showAddFoodSheet(BuildContext context) async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => const FoodInputSheet(),
    );

    if (!mounted || result == null) return;

    // CEK: Jika hasil datang dari Input Teks (bukan kamera),
    // kita bisa buat agar langsung simpan tanpa verifikasi lagi.
    if (result['source'] == 'text') {
      _directSaveFood(result); // Fungsi baru untuk simpan langsung
    } else {
      // Jika dari kamera, tetap munculkan kartu verifikasi dulu
      setState(() {
        _tempFoodData = result;
      });
    }
  }

  // Fungsi Helper untuk Simpan Langsung (Input Teks)
  void _directSaveFood(Map<String, dynamic> data) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Tampilkan loading sebentar agar user tahu ada proses
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Mencatat nutrisi..."),
          duration: Duration(seconds: 1),
        ),
      );

      await DatabaseService().saveFoodLog(user.uid, data);

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Berhasil ditambahkan!")));
    }
  }

  void _confirmSaveFood() async {
    final user = FirebaseAuth.instance.currentUser;

    // Pastikan data ada dan tidak sedang dalam proses penyimpanan (mencegah double tap)
    if (user != null && _tempFoodData != null && !_isSaving) {
      setState(() {
        _isSaving = true;
      });

      try {
        // Menjalankan proses simpan ke Firestore
        await DatabaseService().saveFoodLog(user.uid, _tempFoodData!);

        // Pastikan widget masih ada di layar (mounted check)
        if (!mounted) return;

        setState(() {
          _tempFoodData = null;
          _isSaving = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Makanan berhasil dicatat!"),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        // Jika terjadi error (misal koneksi terputus), buka kembali kunci saving
        if (!mounted) return;

        setState(() {
          _isSaving = false;
        });

        debugPrint("MacroFit Error - Save Food: $e");

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Gagal mencatat makanan. Periksa koneksi internet."),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  // --- WIDGET COMPONENTS ---

  Widget _nutrisiMiniText(String label, String value, {Color? valueColor}) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: valueColor ?? Colors.black, // Default hitam jika tidak diisi
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, ColorScheme colorScheme) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: colorScheme.onSurface,
      ),
    );
  }

  Widget _buildCalorieCard(int targetCal, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outline),
      ),
      child: Stack(
        // Menggunakan Stack agar logo petir bisa diposisikan lebih bebas
        children: [
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Target Maksimal",
                    style: TextStyle(
                      color: colorScheme.onSurface.withOpacity(0.5),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4), // Memberi sedikit jarak vertikal
                  Text(
                    "$targetCal kkal",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 24, // Sedikit diperbesar agar lebih tegas
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Logo Petir diletakkan di posisi kanan tengah secara absolut
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(
                  0.1,
                ), // Efek glow halus di belakang petir
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.bolt_rounded, // Gunakan versi rounded agar lebih modern
                color: Colors.orange,
                size: 35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final user = FirebaseAuth.instance.currentUser;

    if (user == null)
      return const Scaffold(body: Center(child: Text("User not logged in")));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "MacroFit",
          style: TextStyle(
            color: colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Data tidak ditemukan"));
          }

          var userData = snapshot.data!.data() as Map<String, dynamic>;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              WelcomeHeader(name: userData['first_name'] ?? "User"),
              const DailyInsightCarousel(), // Panggil secara modular
              const SizedBox(height: 20),
              const SizedBox(height: 25),
              NutritionalCard(userData: userData, uid: user.uid),
              const SizedBox(height: 25),
              // Cari bagian _buildWaterTracker dan ganti menjadi:
              WaterTrackerCard(uid: user.uid, userData: userData),
              if (_tempFoodData != null)
                Card(
                  margin: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                    side: const BorderSide(color: Colors.blueAccent, width: 1),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "🔍 Verifikasi: ${_tempFoodData!['food_name']}",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _nutrisiMiniText(
                              "P",
                              "${_tempFoodData!['protein']}g",
                            ),
                            _nutrisiMiniText(
                              "K",
                              "${_tempFoodData!['carbs']}g",
                            ),
                            _nutrisiMiniText("L", "${_tempFoodData!['fats']}g"),
                            _nutrisiMiniText(
                              "Kal",
                              "${_tempFoodData!['calories']} kcal",
                            ),
                            _nutrisiMiniText(
                              "Air",
                              "${_tempFoodData!['water_ml']}ml",
                              valueColor: Colors
                                  .blue, // Sekarang parameter ini akan dikenali
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () =>
                                    setState(() => _tempFoodData = null),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                ),
                                child: const Text("Salah"),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _confirmSaveFood,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                ),
                                child: const Text("Benar"),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 25),
              _buildSectionTitle("Target Kalori", colorScheme),
              CalorieTargetCard(
                targetCal: userData['daily_calorie_target'] ?? 0,
              ),
              const SizedBox(height: 100),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddFoodSheet(context),
        label: const Text("Catat Makan"),
        icon: const Icon(Icons.auto_awesome),
        backgroundColor: colorScheme.primary,
        foregroundColor: Colors.white,
      ),
    );
  }
}
