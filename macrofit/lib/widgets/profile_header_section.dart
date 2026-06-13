import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../utils/notification_helper.dart';
import '../utils/global_state.dart';

class ProfileHeaderSection extends StatefulWidget {
  final Map<String, dynamic> userData;

  const ProfileHeaderSection({super.key, required this.userData});

  @override
  State<ProfileHeaderSection> createState() => _ProfileHeaderSectionState();
}

class _ProfileHeaderSectionState extends State<ProfileHeaderSection> {
  bool _isPhotoUploading = false;

  int _getRemainingDaysToUpdateName(Timestamp? lastUpdate) {
    if (lastUpdate == null) return 0;
    return (14 - DateTime.now().difference(lastUpdate.toDate()).inDays).clamp(
      0,
      14,
    );
  }

  int _getRemainingDaysToUpdateUsername(Timestamp? lastUpdate) {
    if (lastUpdate == null) return 0;
    return (14 - DateTime.now().difference(lastUpdate.toDate()).inDays).clamp(
      0,
      14,
    );
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

      setState(() => _isPhotoUploading = true);
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
          isEnglishNotifier.value
              ? 'Profile picture updated!'
              : 'Foto profil berhasil diperbarui!',
        );
      }
    } catch (e) {
      if (mounted) {
        Notify.error(
          context,
          isEnglishNotifier.value
              ? 'Failed to update photo: $e'
              : 'Gagal memperbarui foto: $e',
        );
      }
    } finally {
      if (mounted) setState(() => _isPhotoUploading = false);
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
      } catch (e) {}

      if (mounted) {
        Notify.success(
          context,
          isEnglishNotifier.value
              ? 'Profile picture reset to default.'
              : 'Foto profil dikembalikan ke default.',
        );
      }
    } catch (e) {
      if (mounted) {
        Notify.error(
          context,
          isEnglishNotifier.value
              ? 'Failed to delete photo: $e'
              : 'Gagal menghapus foto: $e',
        );
      }
    }
  }

  void _showEditNameDialog(
    BuildContext context,
    String currentName,
    Timestamp? lastNameUpdate,
    String currentusername,
    Timestamp? lastUsernameUpdate,
  ) {
    final nameController = TextEditingController(text: currentName);
    final usernameController = TextEditingController(text: currentusername);
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
          isEnglishNotifier.value
              ? 'Edit Account Identity'
              : 'Ubah Identitas Akun',
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
                labelText: isEnglishNotifier.value
                    ? "Full Name"
                    : "Nama Lengkap",
                prefixIcon: const Icon(Icons.person_outline, size: 20),
                errorText: remainingNameDays > 0
                    ? (isEnglishNotifier.value
                          ? 'Wait $remainingNameDays days'
                          : 'Tunggu $remainingNameDays hari lagi')
                    : null,
              ),
              maxLength: 30,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: usernameController,
              enabled: remainingUsernameDays <= 0,
              decoration: InputDecoration(
                labelText: isEnglishNotifier.value
                    ? "Unique Username"
                    : "Username Unik",
                prefixText: "@",
                hintText: "contoh: steven_dev",
                prefixIcon: const Icon(Icons.alternate_email, size: 20),
                errorText: remainingUsernameDays > 0
                    ? (isEnglishNotifier.value
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
              isEnglishNotifier.value ? 'Cancel' : 'Batal',
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: (remainingNameDays > 0 && remainingUsernameDays > 0)
                ? null
                : () async {
                    String newName = nameController.text.trim();
                    String newusername = usernameController.text
                        .trim()
                        .toLowerCase()
                        .replaceAll(' ', '');

                    if (newName.isEmpty || newusername.isEmpty) return;
                    final Map<String, dynamic> updatePayload = {};

                    if (newName != currentName && remainingNameDays <= 0) {
                      updatePayload['full_name'] = newName;
                      updatePayload['last_name_update'] =
                          FieldValue.serverTimestamp();
                    }

                    if (newusername != currentusername &&
                        remainingUsernameDays <= 0) {
                      final checkDuplication = await FirebaseFirestore.instance
                          .collection('users')
                          .where('username', isEqualTo: newusername)
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
                            isEnglishNotifier.value
                                ? '⚠️ Username already taken!'
                                : '⚠️ Username telah digunakan oleh akun lain!',
                          );
                        }
                        return;
                      }
                      updatePayload['username'] = newusername;
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
              isEnglishNotifier.value ? 'Save' : 'Simpan',
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    String fullName = widget.userData['full_name'] ?? 'User MacroFit';
    String username = widget.userData['username'] ?? 'belum_diatur';
    String profilePic = widget.userData['profile_picture'] ?? '';
    String email = FirebaseAuth.instance.currentUser?.email ?? '';

    Timestamp? lastNameUpdate = widget.userData['last_name_update'];
    Timestamp? lastUsernameUpdate = widget.userData['last_username_update'];

    final int remainingNameDays = _getRemainingDaysToUpdateName(lastNameUpdate);
    final int remainingUsernameDays = _getRemainingDaysToUpdateUsername(
      lastUsernameUpdate,
    );

    return Column(
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
                      backgroundColor: theme.primaryColor.withOpacity(0.1),
                      backgroundImage:
                          (!_isPhotoUploading && profilePic.isNotEmpty)
                          ? NetworkImage(profilePic)
                          : null,
                      child: _isPhotoUploading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 3),
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
            style: TextButton.styleFrom(foregroundColor: Colors.grey.shade600),
            icon: const Icon(Icons.delete_outline, size: 16),
            label: Text(
              isEnglishNotifier.value
                  ? "Delete Profile Picture"
                  : "Hapus Foto Profil",
              style: const TextStyle(fontSize: 13),
            ),
            onPressed: () => _discardProfilePicture(context),
          ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(width: 32),
            Text(
              fullName,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: Icon(
                Icons.edit,
                size: 16,
                color: (remainingNameDays > 0 && remainingUsernameDays > 0)
                    ? Colors.grey.shade400
                    : Colors.grey,
              ),
              onPressed: () => _showEditNameDialog(
                context,
                fullName,
                lastNameUpdate,
                username,
                lastUsernameUpdate,
              ),
            ),
          ],
        ),
        Text(
          '@$username',
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
              isEnglishNotifier.value
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
              isEnglishNotifier.value
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
        Text(email, style: const TextStyle(color: Colors.grey, fontSize: 14)),
      ],
    );
  }
}
