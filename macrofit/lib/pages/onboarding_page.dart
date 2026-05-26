import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/database_services.dart';
import '../models/user_model.dart';
import '../widgets/gender_card.dart';
import '../widgets/custom_input_field.dart';
import '../widgets/activity_card.dart';
import '../widgets/goal_card.dart';
import '../models/nutrition_model.dart';
import 'home_page.dart';
import '../utils/notification_helper.dart'; // 🟢 Import helper notifikasi

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class ActivityOption {
  final String title;
  final String description;
  final double value;

  ActivityOption({
    required this.title,
    required this.description,
    required this.value,
  });
}

final List<ActivityOption> activities = [
  ActivityOption(
    title: "Sedentary",
    description: "Banyak duduk, jarang olahraga (pekerja kantor/mahasiswa)",
    value: 1.2,
  ),
  ActivityOption(
    title: "Lightly Active",
    description: "Olahraga ringan 1-3 kali seminggu",
    value: 1.375,
  ),
  ActivityOption(
    title: "Moderately Active",
    description: "Olahraga intensitas sedang 3-5 kali seminggu",
    value: 1.55,
  ),
  ActivityOption(
    title: "Very Active",
    description: "Olahraga berat 6-7 kali seminggu atau kerja fisik",
    value: 1.725,
  ),
];

class GoalOption {
  final String title;
  final String subtitle;
  final IconData icon;
  final String code;

  GoalOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.code,
  });
}

final List<GoalOption> dietGoals = [
  GoalOption(
    title: "Menurunkan Berat Badan",
    subtitle: "Fokus pada defisit kalori dan pembakaran lemak.",
    icon: Icons.trending_down,
    code: "Menurunkan Berat Badan",
  ),
  GoalOption(
    title: "Menaikkan Massa Otot",
    subtitle: "Surplus kalori dengan asupan protein tinggi.",
    icon: Icons.fitness_center,
    code: "gain_muscle",
  ),
  GoalOption(
    title: "Gaya Hidup Sehat",
    subtitle: "Menjaga berat badan ideal dan kebugaran tubuh.",
    icon: Icons.favorite,
    code: "healthy_lifestyle",
  ),
  GoalOption(
    title: "Diet Keto",
    subtitle: "Rendah karbohidrat dan tinggi lemak sehat.",
    icon: Icons.egg_alt,
    code: "keto_diet",
  ),
  GoalOption(
    title: "Vegetarian",
    subtitle: "Fokus pada sumber nutrisi berbasis nabati.",
    icon: Icons.eco,
    code: "vegetarian",
  ),
];

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  double? _selectedActivityValue;

  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  String? _selectedGender;
  String? _selectedDietCode;

  @override
  void dispose() {
    _pageController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _submitData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Notify.error(context, "Sesi login berakhir, silakan login ulang");
      return;
    }

    final int age = int.tryParse(_ageController.text) ?? 0;
    final double weight = double.tryParse(_weightController.text) ?? 0;
    final double height = double.tryParse(_heightController.text) ?? 0;

    double bmr;
    if (_selectedGender == "Male") {
      bmr = (10 * weight) + (6.25 * height) - (5 * age) + 5;
    } else {
      bmr = (10 * weight) + (6.25 * height) - (5 * age) - 161;
    }

    double tdee = bmr * (_selectedActivityValue ?? 1.2);

    double goalCalories = tdee;
    if (_selectedDietCode == 'Menurunkan Berat Badan') goalCalories -= 500;
    if (_selectedDietCode == 'gain_muscle') goalCalories += 500;

    double sugarPercentage = (_selectedDietCode == 'keto_diet') ? 0.05 : 0.10;
    double sugarGramCalculated = (goalCalories * sugarPercentage) / 4;
    if (_selectedDietCode == 'keto_diet' && sugarGramCalculated > 25) {
      sugarGramCalculated = 25;
    }

    double calculatedWaterTarget = weight * 33;
    double proteinGram = (goalCalories * 0.25) / 4;
    double carbsGram = (goalCalories * 0.45) / 4;
    double fatsGram = (goalCalories * 0.30) / 9;

    final hasilNutrisi = NutritionModel(
      targetCalMin: (goalCalories - 100).round(),
      targetCalMax: (goalCalories + 100).round(),
      proteinGram: proteinGram.round(),
      carbsGram: carbsGram.round(),
      fatsGram: fatsGram.round(),
      sugarGram: sugarGramCalculated.round(),
      waterMl: calculatedWaterTarget.round(),
      dietCode: _selectedDietCode!,
    );

    try {
      await DatabaseService().updateOnboardingData(
        uid: user.uid,
        age: age,
        weight: weight,
        height: height,
        gender: _selectedGender!,
        nutrition: hasilNutrisi,
      );

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      Notify.error(context, "Gagal menyimpan data: $e");
    }
  }

  // ... (Widget _buildPhysicalDataStep, _buildActivityStep, _buildGoalStep tetap sama)
  // [Kode _buildPhysicalDataStep, _buildActivityStep, _buildGoalStep disisipkan di sini]

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: LinearProgressIndicator(
                value: (_currentPage + 1) / 3,
                backgroundColor: Theme.of(context).colorScheme.outline,
                color: Theme.of(context).primaryColor,
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (int page) =>
                    setState(() => _currentPage = page),
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildPhysicalDataStep(),
                  _buildActivityStep(),
                  _buildGoalStep(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Sisa method _build...Step tetap menggunakan Notify.error jika validasi gagal
  Widget _buildPhysicalDataStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Mari mulai dengan data fisik Anda",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 30),
          Row(
            children: [
              GenderCard(
                label: "Male",
                icon: Icons.male,
                isSelected: _selectedGender == "Male",
                onTap_gender: () => setState(() => _selectedGender = "Male"),
              ),
              const SizedBox(width: 20),
              GenderCard(
                label: "Female",
                icon: Icons.female,
                isSelected: _selectedGender == "Female",
                onTap_gender: () => setState(() => _selectedGender = "Female"),
              ),
            ],
          ),
          const SizedBox(height: 30),
          CustomInputField(
            label: "Umur",
            controller: _ageController,
            suffix: "tahun",
            icon: Icons.cake,
          ),
          const SizedBox(height: 20),
          CustomInputField(
            label: "Berat Badan",
            controller: _weightController,
            suffix: "kg",
            icon: Icons.monitor_weight,
          ),
          const SizedBox(height: 20),
          CustomInputField(
            label: "Tinggi Badan",
            controller: _heightController,
            suffix: "cm",
            icon: Icons.height,
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                if (_selectedGender != null &&
                    _ageController.text.isNotEmpty &&
                    _weightController.text.isNotEmpty &&
                    _heightController.text.isNotEmpty) {
                  _nextPage();
                } else {
                  Notify.error(context, "Mohon lengkapi semua data");
                }
              },
              child: const Text("Lanjut"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Seberapa aktif Anda?",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 30),
          ...activities
              .map(
                (act) => ActivityCard(
                  title: act.title,
                  description: act.description,
                  isSelected: _selectedActivityValue == act.value,
                  onSelected: () =>
                      setState(() => _selectedActivityValue = act.value),
                ),
              )
              .toList(),
          const SizedBox(height: 40),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _pageController.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  ),
                  child: const Text("Kembali"),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _selectedActivityValue != null ? _nextPage : null,
                  child: const Text("Lanjut"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGoalStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Apa target nutrisi Anda?",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 30),
          ...dietGoals
              .map(
                (diet) => GoalCard(
                  title: diet.title,
                  subtitle: diet.subtitle,
                  icon: diet.icon,
                  isSelected: _selectedDietCode == diet.code,
                  onTap_goal: () =>
                      setState(() => _selectedDietCode = diet.code),
                ),
              )
              .toList(),
          const SizedBox(height: 40),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _pageController.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  ),
                  child: const Text("Kembali"),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _selectedDietCode != null ? _submitData : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text(
                    "Selesai",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
