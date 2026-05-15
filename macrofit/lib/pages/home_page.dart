import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/database_services.dart';
import '../widgets/food_input_sheet.dart';
import '../widgets/Daily_Insight_banner.dart';
import '../widgets/welcome_header.dart';
import '../widgets/calorie_target_card.dart';
import '../widgets/nutritional_card.dart';
import '../widgets/water_tracker_card.dart';
import '../widgets/food_verification_card.dart'; // Import widget baru

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

// Tambahkan AutomaticKeepAliveClientMixin agar state tidak hancur saat digeser
class _HomePageState extends State<HomePage>
    with AutomaticKeepAliveClientMixin {
  Map<String, dynamic>? _tempFoodData;
  bool _isSaving = false;

  // Wajib return true agar halaman tetap hidup di memori
  @override
  bool get wantKeepAlive => true;

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

    if (result['source'] == 'text') {
      _directSaveFood(result);
    } else {
      setState(() {
        _tempFoodData = result;
      });
    }
  }

  void _directSaveFood(Map<String, dynamic> data) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
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
    if (user != null && _tempFoodData != null && !_isSaving) {
      setState(() => _isSaving = true);

      try {
        await DatabaseService().saveFoodLog(user.uid, _tempFoodData!);
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
        if (!mounted) return;
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Gagal mencatat makanan."),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
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

  @override
  Widget build(BuildContext context) {
    // Wajib panggil super.build agar KeepAlive bekerja
    super.build(context);

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
              const DailyInsightCarousel(),
              const SizedBox(height: 25),
              NutritionalCard(userData: userData, uid: user.uid),
              const SizedBox(height: 25),
              // Tampilkan kartu verifikasi jika ada data sementara
              if (_tempFoodData != null)
                FoodVerificationCard(
                  data: _tempFoodData!,
                  onConfirm: _confirmSaveFood,
                  onCancel: () => setState(() => _tempFoodData = null),
                ),
              //water tracker card, bisa dibuat lebih menarik dengan progress bar atau animasi
              WaterTrackerCard(uid: user.uid, userData: userData),
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
