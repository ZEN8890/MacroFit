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
                            onPressed: () async {
                              // Validasi dasar: Jangan ijinkan posting jika teks dan gambar kosong
                              if (controller.text.trim().isEmpty &&
                                  selectedImages.isEmpty) {
                                return;
                              }

                              final isDark =
                                  theme.brightness == Brightness.dark;

                              // 1. TAMPILKAN POP-UP KONFIRMASI POSTING
                              bool confirmPost =
                                  await showDialog<bool>(
                                    context: context,
                                    builder: (confirmContext) => AlertDialog(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      title: Text(
                                        englishActive
                                            ? 'Confirm Post'
                                            : 'Konfirmasi Postingan',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      ),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            englishActive
                                                ? 'Are you sure you want to publish this to the forum community?'
                                                : 'Apakah Anda yakin ingin membagikan ini ke forum komunitas?',
                                            style: TextStyle(
                                              fontSize: 13,
                                              // Menyesuaikan kontras teks deskripsi dialog
                                              color: isDark
                                                  ? Colors.white60
                                                  : Colors.black54,
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          // PRATINJAU ISI POSTINGAN
                                          Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: theme.primaryColor
                                                  .withOpacity(0.08),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              border: Border.all(
                                                color: theme.primaryColor
                                                    .withOpacity(0.15),
                                              ),
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  controller.text
                                                          .trim()
                                                          .isNotEmpty
                                                      ? '"${controller.text.trim()}"'
                                                      : (englishActive
                                                            ? '(No text content)'
                                                            : '(Tanpa konten teks)'),
                                                  maxLines: 4,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontStyle:
                                                        controller.text
                                                            .trim()
                                                            .isNotEmpty
                                                        ? FontStyle.italic
                                                        : FontStyle.normal,
                                                    // 🟢 ADAPTIF KONTRAS TINGGI: menggunakan onSurface (Putih di Dark / Hitam di Light)
                                                    color:
                                                        controller.text
                                                            .trim()
                                                            .isNotEmpty
                                                        ? theme
                                                              .colorScheme
                                                              .onSurface
                                                        : (isDark
                                                              ? Colors.white38
                                                              : Colors.black38),
                                                  ),
                                                ),
                                                if (selectedImages
                                                    .isNotEmpty) ...[
                                                  const SizedBox(height: 8),
                                                  Row(
                                                    children: [
                                                      Icon(
                                                        Icons.image,
                                                        size: 16,
                                                        color:
                                                            theme.primaryColor,
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        englishActive
                                                            ? 'Attached: ${selectedImages.length} photo(s)'
                                                            : 'Terlampir: ${selectedImages.length} foto',
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: theme
                                                              .primaryColor,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(
                                            confirmContext,
                                            false,
                                          ),
                                          child: Text(
                                            englishActive
                                                ? 'Check Again'
                                                : 'Periksa Kembali',
                                            style: const TextStyle(
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: () => Navigator.pop(
                                            confirmContext,
                                            true,
                                          ),
                                          child: Text(
                                            englishActive
                                                ? 'Yes, Post'
                                                : 'Ya, Kirim',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: theme.primaryColor,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ) ??
                                  false;

                              // 2. Jika user membatalkan, jangan teruskan fungsi eksekusi
                              if (!confirmPost) return;

                              // 3. Panggil fungsi asli untuk memproses pembuatan post di Firestore
                              onCreatePost();
                            },
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
