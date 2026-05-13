import 'package:flutter/material.dart';
import '../models/nutrition_model.dart';
import '../widgets/nutrition_progress_bar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/database_services.dart';
import '../services/ai_services.dart';
import '../widgets/food_input_sheet.dart';
import '../widgets/Daily_Insight_banner.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Map<String, dynamic>? _tempFoodData;

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
    if (user != null && _tempFoodData != null) {
      await DatabaseService().saveFoodLog(user.uid, _tempFoodData!);

      // Cek mounted lagi sebelum setState
      if (!mounted) return;

      setState(() {
        _tempFoodData = null;
      });

      // Bagian SnackBar kamu sebenarnya sudah bagus karena sudah pakai cek mounted
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Makanan berhasil dicatat!")),
      );
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

  Widget _buildWelcomeHeader(String name, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Statistik Hari Ini,",
          style: TextStyle(
            color: colorScheme.onSurface.withOpacity(0.6),
            fontSize: 14,
          ),
        ),
        Text(
          name,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildNutritionalCard(
    Map<String, dynamic> userData,
    ColorScheme colorScheme,
  ) {
    // Helper fungsi untuk warna tetap di dalam atau bisa dipindah ke luar widget
    Color _getSugarColor(double current, double target) {
      if (current > target) {
        return Colors.red; // Bahaya
      } else if (current > target * 0.8) {
        return Colors.orange; // Peringatan
      }
      return Colors.purpleAccent; // Aman
    }

    final user = FirebaseAuth.instance.currentUser;
    String today = DateTime.now().toString().split(' ')[0];

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user?.uid)
          .collection('daily_logs')
          .doc(today)
          .snapshots(),
      builder: (context, logSnapshot) {
        // 1. Inisialisasi logData di dalam builder
        Map<String, dynamic> logData =
            logSnapshot.hasData && logSnapshot.data!.exists
            ? logSnapshot.data!.data() as Map<String, dynamic>
            : {
                'consumed_protein': 0,
                'consumed_carbs': 0,
                'consumed_fats': 0,
                'consumed_calories': 0,
                'consumed_sugar': 0, // Pastikan ada default untuk sugar
              };

        // 2. Definisikan variabel gula DI SINI agar logData sudah terdefinisi
        double currentSugar = (logData['consumed_sugar'] ?? 0).toDouble();
        double targetSugar = (userData['target_sugar'] ?? 50.0).toDouble();

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colorScheme.outline),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Makronutrisi (Gram)",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 20),
              NutritionProgressBar(
                label: "Protein",
                current: (logData['consumed_protein'] ?? 0).toDouble(),
                target: (userData['target_protein'] ?? 0).toDouble(),
                color: Colors.redAccent,
              ),
              NutritionProgressBar(
                label: "Karbohidrat",
                current: (logData['consumed_carbs'] ?? 0).toDouble(),
                target: (userData['target_carbs'] ?? 0).toDouble(),
                color: Colors.blueAccent,
              ),
              NutritionProgressBar(
                label: "Lemak",
                current: (logData['consumed_fats'] ?? 0).toDouble(),
                target: (userData['target_fats'] ?? 0).toDouble(),
                color: Colors.orangeAccent,
              ),
              // Sekarang Gula akan berjalan tanpa error
              NutritionProgressBar(
                label: "Gula",
                current: currentSugar,
                target: targetSugar,
                color: _getSugarColor(currentSugar, targetSugar),
              ),
            ],
          ),
        );
      },
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

  Widget _buildWaterTracker(
    String uid,
    ColorScheme colorScheme,
    Map<String, dynamic> userData,
  ) {
    String today = DateTime.now().toString().split(' ')[0];
    // Ambil target dari database, jika tidak ada gunakan default dari berat badan (jika tersedia)
    double targetWater = (userData['target_water'] ?? 2000).toDouble();

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('daily_logs')
          .doc(today)
          .snapshots(),
      builder: (context, snapshot) {
        double currentWater = 0;
        if (snapshot.hasData && snapshot.data!.exists) {
          currentWater =
              (snapshot.data!.data() as Map<String, dynamic>)['water_ml']
                  ?.toDouble() ??
              0.0;
        }

        double progress = (currentWater / targetWater).clamp(0.0, 1.0);

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colorScheme.outline),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.local_drink, color: Colors.blue, size: 30),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Hidrasi Hari Ini",
                          style: TextStyle(
                            color: colorScheme.onSurface.withOpacity(0.6),
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          "${currentWater.toInt()} / ${targetWater.toInt()} ml",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // --- BAGIAN TOMBOL MINUS & PLUS ---
                  Row(
                    children: [
                      // Tombol Minus (-)
                      IconButton(
                        onPressed: () =>
                            DatabaseService().removeWaterIntake(uid, 250),
                        icon: Icon(
                          Icons.remove_circle_outline,
                          color: Colors.redAccent.withOpacity(0.7),
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 2), // Jarak kecil antar tombol
                      // Tombol Plus (+)
                      IconButton(
                        onPressed: () =>
                            DatabaseService().updateWaterIntake(uid, 250),
                        icon: const Icon(
                          Icons.add_circle,
                          color: Colors.blue,
                          size: 32,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 15),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 10,
                  backgroundColor: Colors.blue.withOpacity(0.1),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                ),
              ),
              const SizedBox(height: 5),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  "${(progress * 100).toInt()}%",
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ),
            ],
          ),
        );
      },
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
              _buildWelcomeHeader(
                userData['first_name'] ?? "User",
                colorScheme,
              ),
              const DailyInsightCarousel(), // Panggil secara modular
              const SizedBox(height: 20),
              const SizedBox(height: 25),
              _buildNutritionalCard(userData, colorScheme),
              const SizedBox(height: 25),
              _buildWaterTracker(user.uid, colorScheme, userData),
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
              _buildCalorieCard(
                userData['daily_calorie_target'] ?? 0,
                colorScheme,
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
