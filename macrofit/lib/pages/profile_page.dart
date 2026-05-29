import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../utils/notification_helper.dart';
import '../utils/global_state.dart'; // 🟢 IMPORT SAKLAR GLOBAL STATE
import 'about_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isPhotoUploading = false;

  final List<Map<String, String>> _dietOptions = [
    {'name': 'Menurunkan Berat Badan', 'code': 'Menurunkan Berat Badan'},
    {'name': 'Menaikkan Massa Otot', 'code': 'gain_muscle'},
    {'name': 'Gaya Hidup Sehat', 'code': 'healthy_lifestyle'},
    {'name': 'Diet Keto', 'code': 'keto_diet'},
    {'name': 'Vegetarian', 'code': 'vegetarian'},
  ];

  int _getRemainingDaysToUpdateName(Timestamp? lastUpdate) {
    if (lastUpdate == null) return 0;

    final DateTime lastUpdateDateTime = lastUpdate.toDate();
    final DateTime now = DateTime.now();

    final int differenceInDays = now.difference(lastUpdateDateTime).inDays;
    final int remainingDays = 14 - differenceInDays;

    return remainingDays > 0 ? remainingDays : 0;
  }

  int _getRemainingDaysToUpdateUsername(Timestamp? lastUpdate) {
    if (lastUpdate == null) return 0;

    final DateTime lastUpdateDateTime = lastUpdate.toDate();
    final DateTime now = DateTime.now();

    final int differenceInDays = now.difference(lastUpdateDateTime).inDays;
    final int remainingDays = 14 - differenceInDays;

    return remainingDays > 0 ? remainingDays : 0;
  }

  Future<void> _pickAndUploadImage(BuildContext context) async {
    final auth = FirebaseAuth.instance;
    final storage = FirebaseStorage.instance;
    final firestore = FirebaseFirestore.instance;
    final ImagePicker picker = ImagePicker();

    try {
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 40,
      );

      if (pickedFile == null) return;

      setState(() {
        _isPhotoUploading = true;
      });

      final user = auth.currentUser;
      if (user == null) return;

      Reference storageRef = storage
          .ref()
          .child('profile_pictures')
          .child('${user.uid}.jpg');
      await storageRef.putFile(File(pickedFile.path));

      String downloadUrl = await storageRef.getDownloadURL();
      await firestore.collection('users').doc(user.uid).update({
        'profile_picture': downloadUrl,
      });

      if (mounted) {
        Notify.success(
          context,
          isEnglish
              ? 'Profile picture updated!'
              : 'Foto profil berhasil diperbarui!',
        );
      }
    } catch (e) {
      if (mounted) {
        Notify.error(
          context,
          isEnglish
              ? 'Failed to update photo: $e'
              : 'Gagal memperbarui foto: $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPhotoUploading = false;
        });
      }
    }
  }

  Future<void> _discardProfilePicture(BuildContext context) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(
        {'profile_picture': FieldValue.delete()},
      );

      try {
        await FirebaseStorage.instance
            .ref()
            .child('profile_pictures')
            .child('${user.uid}.jpg')
            .delete();
      } catch (e) {
        // Abaikan jika file tidak ada
      }

      if (mounted) {
        Notify.success(
          context,
          isEnglish
              ? 'Profile picture reset to default.'
              : 'Foto profil dikembalikan ke default.',
        );
      }
    } catch (e) {
      if (mounted) {
        Notify.error(
          context,
          isEnglish ? 'Failed to delete photo: $e' : 'Gagal menghapus foto: $e',
        );
      }
    }
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
                isEnglish ? 'Logout Confirmation' : 'Konfirmasi Keluar',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                isEnglish
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
                        isEnglish ? 'Cancel' : 'Batal',
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
                        isEnglish ? 'Logout' : 'Keluar',
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

  void _showEditNameDialog(
    BuildContext context,
    String currentName,
    Timestamp? lastNameUpdate,
    String currentHandle,
    Timestamp? lastUsernameUpdate,
  ) {
    final nameController = TextEditingController(text: currentName);
    final handleController = TextEditingController(text: currentHandle);
    final theme = Theme.of(context);

    final int remainingNameDays = _getRemainingDaysToUpdateName(lastNameUpdate);
    final int remainingUsernameDays = _getRemainingDaysToUpdateUsername(
      lastUsernameUpdate,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          isEnglish ? 'Edit Account Identity' : 'Ubah Identitas Akun',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: nameController,
              enabled: remainingNameDays <= 0,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: isEnglish ? "Full Name" : "Nama Lengkap",
                prefixIcon: const Icon(Icons.person_outline, size: 20),
                errorText: remainingNameDays > 0
                    ? (isEnglish
                          ? 'Wait $remainingNameDays days'
                          : 'Tunggu $remainingNameDays hari lagi')
                    : null,
              ),
              maxLength: 30,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: handleController,
              enabled: remainingUsernameDays <= 0,
              decoration: InputDecoration(
                labelText: isEnglish ? "Unique Username" : "Username Unik",
                prefixText: "@",
                hintText: "contoh: steven_dev",
                prefixIcon: const Icon(Icons.alternate_email, size: 20),
                errorText: remainingUsernameDays > 0
                    ? (isEnglish
                          ? 'Wait $remainingUsernameDays days'
                          : 'Tunggu $remainingUsernameDays hari lagi')
                    : null,
              ),
              maxLength: 20,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              isEnglish ? 'Cancel' : 'Batal',
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: (remainingNameDays > 0 && remainingUsernameDays > 0)
                ? null
                : () async {
                    String newName = nameController.text.trim();
                    String newHandle = handleController.text
                        .trim()
                        .toLowerCase()
                        .replaceAll(' ', '');

                    if (newName.isEmpty || newHandle.isEmpty) return;

                    final Map<String, dynamic> updatePayload = {};

                    if (newName != currentName && remainingNameDays <= 0) {
                      updatePayload['username'] = newName;
                      updatePayload['last_name_update'] =
                          FieldValue.serverTimestamp();
                    }

                    if (newHandle != currentHandle &&
                        remainingUsernameDays <= 0) {
                      final checkDuplication = await FirebaseFirestore.instance
                          .collection('users')
                          .where('username_handle', isEqualTo: newHandle)
                          .get();

                      bool isTakenByOthers = false;
                      for (var doc in checkDuplication.docs) {
                        if (doc.id != FirebaseAuth.instance.currentUser!.uid) {
                          isTakenByOthers = true;
                        }
                      }

                      if (isTakenByOthers) {
                        if (context.mounted) {
                          Notify.error(
                            context,
                            isEnglish
                                ? '⚠️ Username already taken!'
                                : '⚠️ Username telah digunakan oleh akun lain!',
                          );
                        }
                        return;
                      }

                      updatePayload['username_handle'] = newHandle;
                      updatePayload['last_username_update'] =
                          FieldValue.serverTimestamp();
                    }

                    if (updatePayload.isNotEmpty) {
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(FirebaseAuth.instance.currentUser!.uid)
                          .update(updatePayload);
                    }

                    if (context.mounted) Navigator.pop(context);
                  },
            child: Text(
              isEnglish ? 'Save' : 'Simpan',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: (remainingNameDays > 0 && remainingUsernameDays > 0)
                    ? Colors.grey
                    : theme.primaryColor,
              ),
            ),
          ),
        ],
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
              isEnglish ? 'Change Diet Program' : 'Ubah Target Diet',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: Text(
          isEnglish
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
              isEnglish ? 'Cancel' : 'Batal',
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
              isEnglish ? 'Change Program' : 'Ganti Program',
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

      if (!userRef.id.isNotEmpty || userDoc.data() == null) return;
      final data = userDoc.data() as Map<String, dynamic>;

      double weight = (data['weight'] ?? 60.0).toDouble();
      double height = (data['height'] ?? 165.0).toDouble();
      int age = data['age'] ?? 21;
      String gender = data['gender'] ?? 'Laki-laki';
      double activityMultiplier = (data['activity_multiplier'] ?? 1.2)
          .toDouble();

      double bmr;
      if (gender == 'Laki-laki' || gender == 'Male') {
        bmr = 66.5 + (13.75 * weight) + (5.003 * height) - (6.75 * age);
      } else {
        bmr = 655.1 + (9.563 * weight) + (1.85 * height) - (4.676 * age);
      }

      double baseTdee = bmr * activityMultiplier;

      int targetCalories;
      switch (selectedDietCode) {
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
          displayName = isEnglish ? 'Gain Muscle' : 'Menaikkan Massa Otot';
        }
        if (selectedDietCode == 'healthy_lifestyle') {
          displayName = isEnglish ? 'Healthy Lifestyle' : 'Gaya Hidup Sehat';
        }
        if (selectedDietCode == 'keto_diet') {
          displayName = isEnglish ? 'Keto Diet' : 'Diet Keto';
        }
        if (selectedDietCode == 'vegetarian') {
          displayName = isEnglish ? 'Vegetarian' : 'Vegetarian';
        }
        if (selectedDietCode == 'Menurunkan Berat Badan') {
          displayName = isEnglish ? 'Lose Weight' : 'Menurunkan Berat Badan';
        }

        Notify.success(
          context,
          isEnglish
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
            isEnglish ? 'Session not found.' : 'Sesi tidak ditemukan.',
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEnglish ? 'User Profile' : 'Profil Pengguna',
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
                  isEnglish
                      ? 'Failed to load database.'
                      : 'Gagal memuat database.',
                ),
              );
            }

            final userData = snapshot.data!.data() as Map<String, dynamic>;
            String username = userData['username'] ?? 'User MacroFit';
            String usernameHandle =
                userData['username_handle'] ?? 'belum_diatur';
            String profilePic = userData['profile_picture'] ?? '';
            String bio = userData['bio'] ?? '';
            String currentDiet = userData['diet_code'] ?? 'healthy_lifestyle';

            Timestamp? lastNameUpdate = userData['last_name_update'];
            Timestamp? lastUsernameUpdate = userData['last_username_update'];

            final int remainingNameDays = _getRemainingDaysToUpdateName(
              lastNameUpdate,
            );
            final int remainingUsernameDays = _getRemainingDaysToUpdateUsername(
              lastUsernameUpdate,
            );

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Center(
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        GestureDetector(
                          onTap: _isPhotoUploading
                              ? null
                              : () => _pickAndUploadImage(context),
                          child: CircleAvatar(
                            radius: 53,
                            backgroundColor: theme.primaryColor,
                            child: CircleAvatar(
                              radius: 51,
                              backgroundColor: theme.scaffoldBackgroundColor,
                              child: CircleAvatar(
                                radius: 48,
                                backgroundColor: theme.primaryColor.withOpacity(
                                  0.1,
                                ),
                                backgroundImage:
                                    (!_isPhotoUploading &&
                                        profilePic.isNotEmpty)
                                    ? NetworkImage(profilePic)
                                    : null,
                                child: _isPhotoUploading
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 3,
                                        ),
                                      )
                                    : (profilePic.isEmpty
                                          ? Icon(
                                              Icons.person,
                                              size: 50,
                                              color: theme.primaryColor,
                                            )
                                          : null),
                              ),
                            ),
                          ),
                        ),
                        if (!_isPhotoUploading)
                          GestureDetector(
                            onTap: () => _pickAndUploadImage(context),
                            child: CircleAvatar(
                              radius: 16,
                              backgroundColor: theme.primaryColor,
                              child: const Icon(
                                Icons.camera_alt,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (profilePic.isNotEmpty && !_isPhotoUploading)
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey.shade600,
                      ),
                      icon: const Icon(Icons.delete_outline, size: 16),
                      label: Text(
                        isEnglish
                            ? "Delete Profile Picture"
                            : "Hapus Foto Profil",
                        style: const TextStyle(fontSize: 13),
                      ),
                      onPressed: () => _discardProfilePicture(context),
                    ),
                  const SizedBox(height: 8),

                  Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(width: 32),
                          Text(
                            username,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.edit,
                              size: 16,
                              color:
                                  (remainingNameDays > 0 &&
                                      remainingUsernameDays > 0)
                                  ? Colors.grey.shade400
                                  : Colors.grey,
                            ),
                            onPressed: () => _showEditNameDialog(
                              context,
                              username,
                              lastNameUpdate,
                              usernameHandle,
                              lastUsernameUpdate,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '@$usernameHandle',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: theme.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 8),

                      if (remainingNameDays > 0)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4.0),
                          child: Text(
                            isEnglish
                                ? "*Profile name can be changed again in $remainingNameDays days."
                                : "*Nama Profil dapat diubah kembali dalam $remainingNameDays hari.",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.amber.shade700,
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),

                      if (remainingUsernameDays > 0)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: Text(
                            isEnglish
                                ? "*Unique username (@) can be changed again in $remainingUsernameDays days."
                                : "*Username unik (@) dapat diubah kembali dalam $remainingUsernameDays hari.",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.purple.shade400,
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                  Text(
                    user.email ?? '',
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  const SizedBox(height: 24),

                  // 🟢 SEKSI TERINTEGRASI: TOMBOL BERALIH BAHASA INDONESIA / INGGRIS (SWITCH)
                  Card(
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.language, color: Colors.blue),
                      title: Text(
                        isEnglish ? 'Language Settings' : 'Pengaturan Bahasa',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        isEnglish ? 'English (EN)' : 'Bahasa Indonesia (ID)',
                      ),
                      // 🟢 TOMBOL BENDERA SESUAI DENGAN BAHASA AKTIF
                      trailing: Card(
                        elevation:
                            2, // Memberikan sedikit bayangan agar terlihat seperti tombol kartu
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            8,
                          ), // Sudut tumpul agar senada dengan UI Anda
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () {
                            setState(() {
                              isEnglish = !isEnglish;
                              isEnglishNotifier.value = isEnglish;
                            });

                            Notify.success(
                              context,
                              isEnglish
                                  ? 'Language changed to English'
                                  : 'Bahasa berhasil diubah ke Indonesia',
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(
                              8.0,
                            ), // Padding agar ikon tidak terlalu mepet
                            child: Text(
                              isEnglish ? "🇬🇧" : "🇮🇩",
                              style: const TextStyle(fontSize: 24),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
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
                        isEnglish ? 'About Application' : 'Tentang Aplikasi',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        isEnglish ? 'Version 1.0.0' : 'Versi 1.0.0',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        // 🟢 NAVIGASI KE ABOUT PAGE
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AboutPage(),
                          ),
                        );
                      },
                    ),
                  ),
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
                        isEnglish ? 'Display Mode' : 'Mode Tampilan',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        themeProvider.isDarkMode
                            ? (isEnglish
                                  ? 'Dark Mode (Lunar)'
                                  : 'Mode Gelap (Lunar)')
                            : (isEnglish
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

                  InlineBioCard(
                    userId: user.uid,
                    initialBio: bio,
                    theme: theme,
                    isDarkMode: themeProvider.isDarkMode,
                  ),
                  const SizedBox(height: 16),

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
                          labelText: isEnglish
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
                          if (isEnglish) {
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
                        isEnglish
                            ? 'Account Certification Status'
                            : 'Status Sertifikasi Account',
                      ),
                      subtitle: Text(
                        isEnglish
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

class InlineBioCard extends StatefulWidget {
  final String userId;
  final String initialBio;
  final ThemeData theme;
  final bool isDarkMode;

  const InlineBioCard({
    super.key,
    required this.userId,
    required this.initialBio,
    required this.theme,
    required this.isDarkMode,
  });

  @override
  State<InlineBioCard> createState() => _InlineBioCardState();
}

class _InlineBioCardState extends State<InlineBioCard> {
  late TextEditingController _controller;
  bool _isChanged = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialBio);
  }

  @override
  void didUpdateWidget(covariant InlineBioCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialBio != oldWidget.initialBio && !_isChanged) {
      _controller.text = widget.initialBio;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.badge_outlined,
                      color: Colors.teal,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isEnglish ? 'Bio & Identity' : 'Bio & Identitas Diri',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (_isChanged)
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: widget.theme.primaryColor,
                    ),
                    icon: const Icon(Icons.check, size: 16),
                    label: Text(
                      isEnglish ? 'Save' : 'Simpan',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onPressed: () async {
                      try {
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(widget.userId)
                            .update({'bio': _controller.text.trim()});

                        setState(() => _isChanged = false);

                        if (mounted) {
                          Notify.success(
                            context,
                            isEnglish
                                ? "Bio updated successfully!"
                                : "Bio berhasil diperbarui!",
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          Notify.error(
                            context,
                            isEnglish
                                ? "Failed to update bio: $e"
                                : "Gagal memperbarui bio: $e",
                          );
                        }
                      }
                    },
                  ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 6),
            TextField(
              controller: _controller,
              minLines: 2,
              maxLines: 4,
              keyboardType: TextInputType.multiline,
              style: TextStyle(
                fontSize: 14,
                color: widget.isDarkMode ? Colors.white : Colors.black87,
              ),
              decoration: InputDecoration(
                hintText: isEnglish
                    ? "Tell us a bit about your diet goals here..."
                    : "Ceritakan sedikit tentang target diet Anda di sini...",
                border: InputBorder.none,
                isDense: true,
                counterText: "",
              ),
              onChanged: (text) {
                setState(() => _isChanged = text.trim() != widget.initialBio);
              },
            ),
          ],
        ),
      ),
    );
  }
}
