import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class PostInputSection extends StatelessWidget {
  final TextEditingController controller;
  final XFile? selectedImage;
  final bool isPosting; // 🔥 Tambahkan ini
  final VoidCallback onPickImage;
  final VoidCallback onCreatePost;
  final VoidCallback onClearImage;

  const PostInputSection({
    super.key,
    required this.controller,
    required this.selectedImage,
    required this.isPosting, // 🔥 Tambahkan ini
    required this.onPickImage,
    required this.onCreatePost,
    required this.onClearImage,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Colors.grey,
                  child: Icon(Icons.person, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: controller,
                    enabled: !isPosting, // Matikan input saat sedang posting
                    decoration: const InputDecoration(
                      hintText: "Bagikan progres diet atau menumu...",
                      border: InputBorder.none,
                    ),
                    maxLines: null,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.image_outlined,
                    color: selectedImage != null
                        ? theme.primaryColor
                        : Colors.grey,
                  ),
                  onPressed: isPosting
                      ? null
                      : onPickImage, // Matikan tombol saat posting
                ),

                // 🔥 ANIMASI TRANSISI TOMBOL KIRIM
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: isPosting
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              theme.primaryColor,
                            ),
                          ),
                        )
                      : IconButton(
                          key: const ValueKey('send_icon'),
                          icon: Icon(Icons.send, color: theme.primaryColor),
                          onPressed: onCreatePost,
                        ),
                ),
              ],
            ),
            if (selectedImage != null)
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Stack(
                  alignment: Alignment.topRight,
                  children: [
                    AspectRatio(
                      aspectRatio: 21 / 9,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          File(selectedImage!.path),
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    if (!isPosting) // Sembunyikan tombol silang saat sedang diupload
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: GestureDetector(
                          onTap: onClearImage,
                          child: const CircleAvatar(
                            radius: 14,
                            backgroundColor: Colors.black54,
                            child: Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
