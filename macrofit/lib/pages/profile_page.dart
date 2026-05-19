import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // 🔥 Ubah ke Stateful hanya untuk mengelola state lokal loading foto profil
  bool _isPhotoUploading = false;

  Future<void> _pickAndUploadImage(BuildContext context) async {
    final auth = FirebaseAuth.instance;
    final storage = FirebaseStorage.instance;
    final firestore = FirebaseFirestore.instance;
    final ImagePicker picker = ImagePicker();

    try {
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 40, // Kompres gambar agar unggahan hemat data & cepat
      );

      if (pickedFile == null) return;

      // Pemicu animasi lingkaran loading di dalam avatar profil
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto profil berhasil diperbarui!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal memperbarui foto: $e')));
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
        // Abaikan jika file memang tidak ada
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto profil dikembalikan ke default.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal menghapus foto: $e')));
      }
    }
  }

  // 🔥 PERBAGUS: Desain Modern & Premium Dialog Konfirmasi Logout
  void _showLogoutConfirmationDialog(BuildContext context) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      barrierDismissible:
          false, // Wajib pilih opsi, tidak bisa asal ketuk luar layar
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 8,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Ikon Peringatan Estetis
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
              // Judul Dialog
              const Text(
                'Konfirmasi Keluar',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              // Deskripsi Teks
              Text(
                'Apakah Anda yakin ingin mengakhiri sesi dan keluar dari aplikasi MacroFit?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              // Tombol Aksi Jajaran Kanan-Kiri yang Seimbang
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
                        'Batal',
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
                      },
                      child: const Text(
                        'Keluar',
                        style: TextStyle(fontWeight: FontWeight.bold),
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

  void _showEditNameDialog(BuildContext context, String currentName) {
    final nameController = TextEditingController(text: currentName);
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Ubah Nama Pengguna',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: "Nama Pengguna",
            hintText: "Masukkan nama baru...",
          ),
          maxLength: 30,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              String newName = nameController.text.trim();
              if (newName.isEmpty) return;

              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(FirebaseAuth.instance.currentUser!.uid)
                  .update({'username': newName});

              if (context.mounted) Navigator.pop(context);
            },
            child: Text(
              'Simpan',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: theme.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('Sesi tidak ditemukan.')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profil Pengguna',
          style: TextStyle(fontWeight: FontWeight.bold),
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
              return const Center(child: Text('Gagal memuat database.'));
            }

            final userData = snapshot.data!.data() as Map<String, dynamic>;
            String username = userData['username'] ?? 'User MacroFit';
            String profilePic = userData['profile_picture'] ?? '';
            String bio = userData['bio'] ?? '';

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // 1. TAMPILAN FOTO PROFIL DENGAN CIRCULAR LOADING INTEGRASI
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
                                // 🔥 TAMBAHAN: Efek lingkaran loading interaktif tepat di tengah bulatan foto profil
                                child: _isPhotoUploading
                                    ? SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 3,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                theme.primaryColor,
                                              ),
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
                        // Sembunyikan ikon kamera kecil jika status sedang loading ganti foto
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
                      label: const Text(
                        "Hapus Foto Profil",
                        style: TextStyle(fontSize: 13),
                      ),
                      onPressed: () => _discardProfilePicture(context),
                    ),
                  const SizedBox(height: 8),

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
                        icon: const Icon(
                          Icons.edit,
                          size: 16,
                          color: Colors.grey,
                        ),
                        onPressed: () => _showEditNameDialog(context, username),
                      ),
                    ],
                  ),
                  Text(
                    user.email ?? '',
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  const SizedBox(height: 24),

                  // 2. SWITCH THEME
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
                      title: const Text(
                        'Mode Tampilan',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        themeProvider.isDarkMode
                            ? 'Mode Gelap (Lunar)'
                            : 'Mode Terang (Solar)',
                      ),
                      trailing: Switch(
                        value: themeProvider.isDarkMode,
                        activeColor: Colors.indigo.shade400,
                        activeTrackColor: Colors.indigo.shade900.withOpacity(
                          0.4,
                        ),
                        onChanged: (bool value) =>
                            themeProvider.toggleTheme(value),
                      ),
                    ),
                  ),

                  // 3. SEPARATED BIO CARD
                  InlineBioCard(
                    userId: user.uid,
                    initialBio: bio,
                    theme: theme,
                    isDarkMode: themeProvider.isDarkMode,
                  ),
                  const SizedBox(height: 16),

                  // 4. KARTU SERTIFIKASI SECURITY
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
                      title: const Text('Status Sertifikasi Account'),
                      subtitle: const Text(
                        'Terverifikasi Firebase Autentikasi',
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
                const Row(
                  children: [
                    Icon(Icons.badge_outlined, color: Colors.teal, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Bio & Identitas Diri',
                      style: TextStyle(
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
                    label: const Text(
                      'Simpan',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onPressed: () async {
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(widget.userId)
                          .update({'bio': _controller.text.trim()});
                      setState(() => _isChanged = false);
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
              decoration: const InputDecoration(
                hintText:
                    "Ceritakan sedikit tentang target diet Anda di sini...",
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
