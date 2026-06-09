import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../utils/notification_helper.dart';
import '../utils/global_state.dart';
import 'about_page.dart';
import '../widgets/profile_header_section.dart';
import '../widgets/inline_health_metrics_card.dart';
import '../widgets/inline_bio_card.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final List<Map<String, String>> _dietOptions = [
    {'name': 'Menurunkan Berat Badan', 'code': 'Menurunkan Berat Badan'},
    {'name': 'Menaikkan Massa Otot', 'code': 'gain_muscle'},
    {'name': 'Gaya Hidup Sehat', 'code': 'healthy_lifestyle'},
    {'name': 'Diet Keto', 'code': 'keto_diet'},
    {'name': 'Vegetarian', 'code': 'vegetarian'},
  ];

  int _calculateAgeFromBirthdate(dynamic dobData) {
    if (dobData == null) return 21;
    DateTime birthDate;
    if (dobData is Timestamp) {
      birthDate = dobData.toDate();
    } else if (dobData is String) {
      birthDate = DateTime.parse(dobData);
    } else {
      return 21;
    }
    DateTime today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  void _showLogoutConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 8,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  color: Colors.redAccent,
                  size: 36,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                isEnglishNotifier.value
                    ? 'Logout Confirmation'
                    : 'Konfirmasi Keluar',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                isEnglishNotifier.value
                    ? 'Are you sure you want to end your session and log out of MacroFit?'
                    : 'Apakah Anda yakin ingin mengakhiri sesi dan keluar dari aplikasi MacroFit?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        isEnglishNotifier.value ? 'Cancel' : 'Batal',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () async {
                        Navigator.pop(context);
                        await FirebaseAuth.instance.signOut();
                        if (context.mounted) {
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            '/login',
                            (route) => false,
                          );
                        }
                      },
                      child: Text(
                        isEnglishNotifier.value ? 'Logout' : 'Keluar',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDietConfirmationDialog(BuildContext context, String newDietCode) {
    final theme = Theme.of(context);
    String displayName =
        _dietOptions.firstWhere((opt) => opt['code'] == newDietCode)['name'] ??
        newDietCode;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: Colors.amber,
              size: 28,
            ),
            const SizedBox(width: 8),
            Text(
              isEnglishNotifier.value
                  ? 'Change Diet Program'
                  : 'Ubah Target Diet',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: Text(
          isEnglishNotifier.value
              ? 'Are you sure you want to change your program focus to "$displayName"?\n\nThis will automatically recalculate your daily calorie target and macro splits.'
              : 'Apakah Anda yakin ingin mengubah fokus program ke "$displayName"?\n\nTindakan ini akan mengkalkulasi ulang seluruh target kalori harian dan batas nutrisi makro (P/K/L) Anda secara otomatis.',
          style: const TextStyle(fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {});
            },
            child: Text(
              isEnglishNotifier.value ? 'Cancel' : 'Batal',
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primaryColor,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
              _updateDietProgram(newDietCode);
            },
            child: Text(
              isEnglishNotifier.value ? 'Change Program' : 'Ganti Program',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateDietProgram(String selectedDietCode) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
      final userDoc = await userRef.get();

      if (userDoc.data() == null) return;
      final data = userDoc.data() as Map<String, dynamic>;

      double weight = (data['weight'] ?? 60.0).toDouble();
      double height = (data['height'] ?? 165.0).toDouble();
      int calculatedAge = _calculateAgeFromBirthdate(data['date_of_birth']);
      String gender = data['gender'] ?? 'Laki-laki';
      double activityMultiplier = (data['activity_multiplier'] ?? 1.2)
          .toDouble();

      double bmr = (gender == 'Laki-laki' || gender == 'Male')
          ? 66.5 + (13.75 * weight) + (5.003 * height) - (6.75 * calculatedAge)
          : 655.1 +
                (9.563 * weight) +
                (1.85 * height) -
                (4.676 * calculatedAge);

      double baseTdee = bmr * activityMultiplier;
      int targetCalories;
      switch (selectedDietCode) {
        case 'txt_weight_loss':
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

      switch (selectedDietCode) {
        case 'txt_weight_loss':
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

      await userRef.update({
        'diet_code': selectedDietCode,
        'target_calories': targetCalories,
        'target_carbs': targetCarbs,
        'target_proteins': targetProteins,
        'target_fats': targetFats,
      });

      if (mounted) {
        String displayName = selectedDietCode;
        if (selectedDietCode == 'gain_muscle') {
          displayName = isEnglishNotifier.value
              ? 'Gain Muscle'
              : 'Menaikkan Massa Otot';
        }
        if (selectedDietCode == 'healthy_lifestyle') {
          displayName = isEnglishNotifier.value
              ? 'Healthy Lifestyle'
              : 'Gaya Hidup Sehat';
        }
        if (selectedDietCode == 'keto_diet') {
          displayName = isEnglishNotifier.value ? 'Keto Diet' : 'Diet Keto';
        }
        if (selectedDietCode == 'vegetarian') {
          displayName = isEnglishNotifier.value ? 'Vegetarian' : 'Vegetarian';
        }
        if (selectedDietCode == 'Menurunkan Berat Badan' ||
            selectedDietCode == 'txt_weight_loss') {
          displayName = isEnglishNotifier.value
              ? 'Lose Weight'
              : 'Menurunkan Berat Badan';
        }

        Notify.success(
          context,
          isEnglishNotifier.value
              ? '⚡ Program switched to $displayName!'
              : '⚡ Program diganti ke $displayName!',
        );
      }
    } catch (e) {
      debugPrint("Gagal mengkalkulasi ulang data diet program: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        body: Center(
          child: Text(
            isEnglishNotifier.value
                ? 'Session not found.'
                : 'Sesi tidak ditemukan.',
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEnglishNotifier.value ? 'User Profile' : 'Profil Pengguna',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.appBarTheme.foregroundColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: () => _showLogoutConfirmationDialog(context),
          ),
        ],
      ),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || !snapshot.data!.exists) {
              return Center(
                child: Text(
                  isEnglishNotifier.value
                      ? 'Failed to load database.'
                      : 'Gagal memuat database.',
                ),
              );
            }

            final userData = snapshot.data!.data() as Map<String, dynamic>;
            String bio = userData['bio'] ?? '';
            String currentDiet = userData['diet_code'] ?? 'healthy_lifestyle';
            double currentWeight = (userData['weight'] ?? 60.0).toDouble();
            double currentHeight = (userData['height'] ?? 165.0).toDouble();
            int dynamicAge = _calculateAgeFromBirthdate(
              userData['date_of_birth'],
            );

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // 🟢 FILE MODULAR 2: Bagian foto profil dan info identitas
                  ProfileHeaderSection(userData: userData),
                  const SizedBox(height: 24),

                  // 🟢 FILE MODULAR 3: Panel input metrik fisik 2 kolom + umur otomatis
                  InlineHealthMetricsCard(
                    userId: user.uid,
                    initialWeight: currentWeight,
                    initialHeight: currentHeight,
                    calculatedAge: dynamicAge,
                    theme: theme,
                    isDarkMode: themeProvider.isDarkMode,
                  ),
                  const SizedBox(height: 16),

                  // PENGATURAN BAHASA CARD
                  Card(
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.language, color: Colors.blue),
                      title: Text(
                        isEnglishNotifier.value
                            ? 'Language Settings'
                            : 'Pengaturan Bahasa',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        isEnglishNotifier.value
                            ? 'English (EN)'
                            : 'Bahasa Indonesia (ID)',
                      ),
                      trailing: Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () {
                            setState(() {
                              isEnglishNotifier.value =
                                  !isEnglishNotifier.value;
                            });
                            Notify.success(
                              context,
                              isEnglishNotifier.value
                                  ? 'Language changed to English'
                                  : 'Bahasa berhasil diubah ke Indonesia',
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              isEnglishNotifier.value ? "🇬🇧" : "🇮🇩",
                              style: const TextStyle(fontSize: 24),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // TENTANG APLIKASI CARD
                  Card(
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: const Icon(
                        Icons.info_outline,
                        color: Colors.blueGrey,
                      ),
                      title: Text(
                        isEnglishNotifier.value
                            ? 'About Application'
                            : 'Tentang Aplikasi',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        isEnglishNotifier.value
                            ? 'Version 1.0.0'
                            : 'Versi 1.0.0',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AboutPage(),
                          ),
                        );
                      },
                    ),
                  ),

                  // DISPLAY MODE SWITCH CARD
                  Card(
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: Icon(
                        themeProvider.isDarkMode
                            ? Icons.nightlight_round
                            : Icons.wb_sunny,
                        color: themeProvider.isDarkMode
                            ? Colors.indigo.shade300
                            : Colors.orange,
                      ),
                      title: Text(
                        isEnglishNotifier.value
                            ? 'Display Mode'
                            : 'Mode Tampilan',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        themeProvider.isDarkMode
                            ? (isEnglishNotifier.value
                                  ? 'Dark Mode (Lunar)'
                                  : 'Mode Gelap (Lunar)')
                            : (isEnglishNotifier.value
                                  ? 'Light Mode (Solar)'
                                  : 'Mode Terang (Solar)'),
                      ),
                      trailing: Switch(
                        value: themeProvider.isDarkMode,
                        activeThumbColor: Colors.indigo.shade400,
                        activeTrackColor: Colors.indigo.shade900.withOpacity(
                          0.4,
                        ),
                        onChanged: (bool value) =>
                            themeProvider.toggleTheme(value),
                      ),
                    ),
                  ),

                  // 🟢 FILE MODULAR 4: Input Bio Card reaktif
                  InlineBioCard(
                    userId: user.uid,
                    initialBio: bio,
                    theme: theme,
                    isDarkMode: themeProvider.isDarkMode,
                  ),
                  const SizedBox(height: 16),

                  // PROGRAM DIET FOCUS DROPDOWN CARD
                  Card(
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: themeProvider.isDarkMode
                            ? Colors.white10
                            : Colors.black.withOpacity(0.04),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 6.0,
                      ),
                      child: DropdownButtonFormField<String>(
                        key: UniqueKey(),
                        initialValue:
                            _dietOptions.any(
                              (opt) => opt['code'] == currentDiet,
                            )
                            ? currentDiet
                            : 'healthy_lifestyle',
                        dropdownColor: theme.cardColor,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: themeProvider.isDarkMode
                              ? Colors.white
                              : Colors.black87,
                        ),
                        decoration: InputDecoration(
                          labelText: isEnglishNotifier.value
                              ? 'Diet Program Focus'
                              : 'Fokus Target Program Diet',
                          labelStyle: TextStyle(
                            color: theme.primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                          border: InputBorder.none,
                          icon: const Icon(
                            Icons.track_changes,
                            color: Colors.green,
                            size: 24,
                          ),
                        ),
                        items: _dietOptions.map((Map<String, String> option) {
                          String translatedName = option['name']!;
                          if (isEnglishNotifier.value) {
                            if (option['code'] == 'Menurunkan Berat Badan') {
                              translatedName = 'Lose Weight';
                            }
                            if (option['code'] == 'gain_muscle') {
                              translatedName = 'Gain Muscle';
                            }
                            if (option['code'] == 'healthy_lifestyle') {
                              translatedName = 'Healthy Lifestyle';
                            }
                            if (option['code'] == 'keto_diet') {
                              translatedName = 'Keto Diet';
                            }
                            if (option['code'] == 'vegetarian') {
                              translatedName = 'Vegetarian';
                            }
                          }
                          return DropdownMenuItem<String>(
                            value: option['code'],
                            child: Text(translatedName),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null && newValue != currentDiet) {
                            _showDietConfirmationDialog(context, newValue);
                          }
                        },
                      ),
                    ),
                  ),

                  // STATUS SERTIFIKASI CARD
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: const Icon(
                        Icons.security_outlined,
                        color: Colors.blue,
                      ),
                      title: Text(
                        isEnglishNotifier.value
                            ? 'Account Certification Status'
                            : 'Status Sertifikasi Account',
                      ),
                      subtitle: Text(
                        isEnglishNotifier.value
                            ? 'Verified by Firebase Authentication'
                            : 'Terverifikasi Firebase Autentikasi',
                      ),
                      trailing: Icon(
                        Icons.check_circle,
                        color: Colors.green.shade600,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
