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
import '../utils/notification_helper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../navigation_menu.dart';
import '../utils/global_state.dart'; // 🟢 IMPORT SAKLAR GLOBAL STATE

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class ActivityOption {
  final String title;
  final String description;
  final String descriptionEn; // 🟢 Tambahan translasi deskripsi aktivitas
  final double value;

  ActivityOption({
    required this.title,
    required this.description,
    required this.descriptionEn,
    required this.value,
  });
}

final List<ActivityOption> activities = [
  ActivityOption(
    title: "Sedentary",
    description: "Banyak duduk, jarang olahraga (pekerja kantor/mahasiswa)",
    descriptionEn: "Mainly sitting, rarely exercise (office worker/student)",
    value: 1.2,
  ),
  ActivityOption(
    title: "Lightly Active",
    description: "Olahraga ringan 1-3 kali seminggu",
    descriptionEn: "Light exercise 1-3 times a week",
    value: 1.375,
  ),
  ActivityOption(
    title: "Moderately Active",
    description: "Olahraga intensitas sedang 3-5 kali seminggu",
    descriptionEn: "Moderate exercise 3-5 times a week",
    value: 1.55,
  ),
  ActivityOption(
    title: "Very Active",
    description: "Olahraga berat 6-7 kali seminggu atau kerja fisik",
    descriptionEn: "Heavy exercise 6-7 times a week or physical job",
    value: 1.725,
  ),
];

class GoalOption {
  final String title;
  final String titleEn; // 🟢 Tambahan translasi judul target
  final String subtitle;
  final String subtitleEn; // 🟢 Tambahan translasi sub-judul target
  final IconData icon;
  final String code;

  GoalOption({
    required this.title,
    required this.titleEn,
    required this.subtitle,
    required this.subtitleEn,
    required this.icon,
    required this.code,
  });
}

final List<GoalOption> dietGoals = [
  GoalOption(
    title: "Menurunkan Berat Badan",
    titleEn: "Weight Loss",
    subtitle: "Fokus pada defisit kalori dan pembakaran lemak.",
    subtitleEn: "Focus on calorie deficit and fat burning.",
    icon: Icons.trending_down,
    code: "Menurunkan Berat Badan",
  ),
  GoalOption(
    title: "Menaikkan Massa Otot",
    titleEn: "Gain Muscle",
    subtitle: "Surplus kalori dengan asupan protein tinggi.",
    subtitleEn: "Calorie surplus with high protein intake.",
    icon: Icons.fitness_center,
    code: "gain_muscle",
  ),
  GoalOption(
    title: "Gaya Hidup Sehat",
    titleEn: "Healthy Lifestyle",
    subtitle: "Menjaga berat badan ideal dan kebugaran tubuh.",
    subtitleEn: "Maintain ideal weight and body fitness.",
    icon: Icons.favorite,
    code: "healthy_lifestyle",
  ),
  GoalOption(
    title: "Diet Keto",
    titleEn: "Keto Diet",
    subtitle: "Rendah karbohidrat dan tinggi lemak sehat.",
    subtitleEn: "Low carbohydrates and high healthy fats.",
    icon: Icons.egg_alt,
    code: "keto_diet",
  ),
  GoalOption(
    title: "Vegetarian",
    titleEn: "Vegetarian",
    subtitle: "Fokus pada sumber nutrisi berbasis nabati.",
    subtitleEn: "Focus on plant-based nutrition sources.",
    icon: Icons.eco,
    code: "vegetarian",
  ),
];

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  double? _selectedActivityValue;
  bool _isSubmitting = false;

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
    final bool isEnglish = isEnglishNotifier.value;

    if (user == null) {
      Notify.error(
        context,
        isEnglish
            ? "Session expired, please log in again"
            : "Sesi login berakhir, silakan login ulang",
      );
      return;
    }

    debugPrint("DEBUG WRITER: Menyimpan ke dokumen ID: ${user.uid}");

    final int age = int.tryParse(_ageController.text) ?? 0;
    final double weight = double.tryParse(_weightController.text) ?? 0;
    final double height = double.tryParse(_heightController.text) ?? 0;

    if (age == 0 ||
        weight == 0 ||
        height == 0 ||
        _selectedGender == null ||
        _selectedDietCode == null) {
      Notify.error(
        context,
        isEnglish ? "Please complete all fields" : "Mohon lengkapi semua data",
      );
      return;
    }

    setState(() => _isSubmitting = true);

    double bmr = (_selectedGender == "Male")
        ? 66.5 + (13.75 * weight) + (5.003 * height) - (6.75 * age)
        : 655.1 + (9.563 * weight) + (1.85 * height) - (4.676 * age);

    double baseTdee = bmr * (_selectedActivityValue ?? 1.2);
    int targetCalories;

    switch (_selectedDietCode) {
      case 'Menurunkan Berat Badan':
        targetCalories = (baseTdee - 500).round();
        break;
      case 'gain_muscle':
        targetCalories = (baseTdee + 400).round();
        break;
      case 'keto_diet':
        targetCalories = (baseTdee - 200).round();
        break;
      case 'healthy_lifestyle':
      case 'vegetarian':
      default:
        targetCalories = baseTdee.round();
        break;
    }

    if (targetCalories < 1200) targetCalories = 1200;

    int targetCarbs;
    int targetProteins;
    int targetFats;

    switch (_selectedDietCode) {
      case 'Menurunkan Berat Badan':
        targetCarbs = ((targetCalories * 0.40) / 4).round();
        targetProteins = ((targetCalories * 0.40) / 4).round();
        targetFats = ((targetCalories * 0.20) / 9).round();
        break;
      case 'gain_muscle':
        targetCarbs = ((targetCalories * 0.50) / 4).round();
        targetProteins = ((targetCalories * 0.30) / 4).round();
        targetFats = ((targetCalories * 0.20) / 9).round();
        break;
      case 'keto_diet':
        targetCarbs = ((targetCalories * 0.05) / 4).round();
        targetProteins = ((targetCalories * 0.25) / 4).round();
        targetFats = ((targetCalories * 0.70) / 9).round();
        break;
      case 'healthy_lifestyle':
      case 'vegetarian':
      default:
        targetCarbs = ((targetCalories * 0.55) / 4).round();
        targetProteins = ((targetCalories * 0.20) / 4).round();
        targetFats = ((targetCalories * 0.25) / 9).round();
        break;
    }

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'age': age,
        'weight': weight,
        'height': height,
        'gender': _selectedGender,
        'activity_multiplier': _selectedActivityValue ?? 1.2,
        'diet_code': _selectedDietCode,
        'target_calories': targetCalories,
        'target_carbs': targetCarbs,
        'target_proteins': targetProteins,
        'target_fats': targetFats,
        'water_ml_target': (weight * 33).round(),
        'sugar_gram_target': ((targetCalories * 0.10) / 4).round(),
      }, SetOptions(merge: true));

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const NavigationMenu()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      Notify.error(
        context,
        isEnglish ? "Failed to save: $e" : "Gagal menyimpan: $e",
      );
    }
  }

  Widget _buildPhysicalDataStep(bool isEnglish) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isEnglish
                ? "Let's start with your physical data"
                : "Mari mulai dengan data fisik Anda",
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 30),
          Row(
            children: [
              Expanded(
                child: GenderCard(
                  label: isEnglish ? "Male" : "Pria",
                  icon: Icons.male,
                  isSelected: _selectedGender == "Male",
                  onTap_gender: () => setState(() => _selectedGender = "Male"),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Theme(
                  data: Theme.of(context).copyWith(
                    primaryColor: Colors.pink,
                    colorScheme: Theme.of(
                      context,
                    ).colorScheme.copyWith(primary: Colors.pink),
                  ),
                  child: GenderCard(
                    label: isEnglish ? "Female" : "Wanita",
                    icon: Icons.female,
                    isSelected: _selectedGender == "Female",
                    onTap_gender: () =>
                        setState(() => _selectedGender = "Female"),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
          CustomInputField(
            label: isEnglish ? "Age" : "Umur",
            controller: _ageController,
            suffix: isEnglish ? "years" : "tahun",
            icon: Icons.cake,
          ),
          const SizedBox(height: 20),
          CustomInputField(
            label: isEnglish ? "Weight" : "Berat Badan",
            controller: _weightController,
            suffix: "kg",
            icon: Icons.monitor_weight,
          ),
          const SizedBox(height: 20),
          CustomInputField(
            label: isEnglish ? "Height" : "Tinggi Badan",
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
                  Notify.error(
                    context,
                    isEnglish
                        ? "Please complete all fields"
                        : "Mohon lengkapi semua data",
                  );
                }
              },
              child: Text(isEnglish ? "Next" : "Lanjut"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityStep(bool isEnglish) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isEnglish ? "How active are you?" : "Seberapa aktif Anda?",
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 30),
          ...activities.map(
            (act) => ActivityCard(
              title: act.title,
              description: isEnglish ? act.descriptionEn : act.description,
              isSelected: _selectedActivityValue == act.value,
              onSelected: () =>
                  setState(() => _selectedActivityValue = act.value),
            ),
          ),
          const SizedBox(height: 40),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _pageController.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  ),
                  child: Text(isEnglish ? "Back" : "Kembali"),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _selectedActivityValue != null ? _nextPage : null,
                  child: Text(isEnglish ? "Next" : "Lanjut"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGoalStep(bool isEnglish) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isEnglish
                ? "What is your nutrition target?"
                : "Apa target nutrisi Anda?",
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 30),
          ...dietGoals.map(
            (diet) => GoalCard(
              title: isEnglish ? diet.titleEn : diet.title,
              subtitle: isEnglish ? diet.subtitleEn : diet.subtitle,
              icon: diet.icon,
              isSelected: _selectedDietCode == diet.code,
              onTap_goal: () => setState(() => _selectedDietCode = diet.code),
            ),
          ),
          const SizedBox(height: 40),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _pageController.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  ),
                  child: Text(isEnglish ? "Back" : "Kembali"),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _isSubmitting
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: _selectedDietCode != null
                            ? _submitData
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        child: Text(
                          isEnglish ? "Finish" : "Selesai",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isEnglishNotifier,
      builder: (context, englishActive, child) {
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
                      _buildPhysicalDataStep(englishActive),
                      _buildActivityStep(englishActive),
                      _buildGoalStep(englishActive),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
