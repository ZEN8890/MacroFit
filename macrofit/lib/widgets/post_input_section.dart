import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../utils/global_state.dart'; // 🟢 IMPORT SAKLAR GLOBAL STATE

class PostInputSection extends StatelessWidget {
  final TextEditingController controller;
  final List<XFile> selectedImages;
  final String currentUserImageUrl;
  final VoidCallback onPickImage;
  final bool isPosting;
  final VoidCallback onCreatePost;
  final VoidCallback onClearImage;
  final Function(int index) onRemoveSpecificImage;
  final FocusNode? focusNode;

  const PostInputSection({
    super.key,
    required this.controller,
    required this.selectedImages,
    required this.currentUserImageUrl,
    required this.onPickImage,
    required this.isPosting,
    required this.onCreatePost,
    required this.onClearImage,
    required this.onRemoveSpecificImage,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // 🟢 REAKTIF MULTI-BAHASA: Membungkus area input dengan ValueListenableBuilder
    return ValueListenableBuilder<bool>(
      valueListenable: isEnglishNotifier,
      builder: (context, englishActive, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          color: theme.cardColor,
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: theme.primaryColor.withOpacity(0.15),
                      backgroundImage: currentUserImageUrl.isNotEmpty
                          ? NetworkImage(currentUserImageUrl)
                          : null,
                      child: currentUserImageUrl.isEmpty
                          ? Icon(
                              Icons.person,
                              size: 18,
                              color: theme.primaryColor,
                            )
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: controller,
                        focusNode: focusNode,
                        maxLines: 3,
                        minLines: 1,
                        keyboardType: TextInputType.multiline,
                        decoration: InputDecoration(
                          // 🟢 DINAMIS MULTI-BAHASA PADA HINT TEKS
                          hintText: englishActive
                              ? 'Type your thoughts here...'
                              : 'Tuliskan pikiranmu di sini...',
                          hintStyle: const TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 4,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                if (selectedImages.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 10.0, bottom: 2.0),
                    child: SizedBox(
                      height: 85,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: selectedImages.length,
                        itemBuilder: (context, index) {
                          return Stack(
                            children: [
                              Container(
                                margin: const EdgeInsets.only(
                                  top: 6,
                                  right: 10,
                                ),
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: theme.primaryColor.withOpacity(0.2),
                                  ),
                                  image: DecorationImage(
                                    image: FileImage(
                                      File(selectedImages[index].path),
                                    ),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 0,
                                right: 4,
                                child: GestureDetector(
                                  onTap: () => onRemoveSpecificImage(index),
                                  child: CircleAvatar(
                                    radius: 9,
                                    backgroundColor: Colors.red.shade600,
                                    child: const Icon(
                                      Icons.close,
                                      size: 11,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),

                const Divider(height: 12, thickness: 0.5),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: theme.primaryColor,
                        padding: EdgeInsets.zero,
                      ),
                      icon: Icon(
                        selectedImages.isNotEmpty
                            ? Icons.add_photo_alternate
                            : Icons.image_outlined,
                        size: 20,
                      ),
                      label: Text(
                        selectedImages.isEmpty
                            ? (englishActive ? "Photo/Media" : "Foto/Media")
                            : (englishActive
                                  ? "Add (${selectedImages.length}/5)"
                                  : "Tambah (${selectedImages.length}/5)"),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed: isPosting ? null : onPickImage,
                    ),

                    isPosting
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.primaryColor,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 0,
                              ),
                              minimumSize: const Size(70, 32),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: onCreatePost,
                            child: Text(
                              englishActive ? 'Post' : 'Post',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
