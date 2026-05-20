import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/storage_services.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../widgets/post_input_section.dart';

class CommentPage extends StatefulWidget {
  final String postId;
  final String postUsername;
  final String postContent;

  const CommentPage({
    super.key,
    required this.postId,
    required this.postUsername,
    required this.postContent,
  });

  @override
  State<CommentPage> createState() => _CommentPageState();
}

class _CommentPageState extends State<CommentPage> {
  final TextEditingController _commentController = TextEditingController();
  // 🔥 PARAMETER BARU: FocusNode untuk memaksa keyboard otomatis menyembul saat klik Reply
  final FocusNode _inputFocusNode = FocusNode();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<XFile> _selectedCommentImages = [];
  final ImagePicker _picker = ImagePicker();
  final StorageService _storageService = StorageService();
  bool _isCommentPosting = false;

  Future<void> _pickCommentImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage();
      if (images.isNotEmpty) {
        int totalImagesNow = _selectedCommentImages.length + images.length;

        if (totalImagesNow > 3) {
          int sisaSlot = 3 - _selectedCommentImages.length;
          if (sisaSlot > 0) {
            setState(() {
              _selectedCommentImages.addAll(images.take(sisaSlot));
            });
          }
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  '⚠️ Batas maksimal balasan komentar adalah 3 foto!',
                ),
                backgroundColor: Colors.amber,
              ),
            );
          }
        } else {
          setState(() {
            _selectedCommentImages.addAll(images);
          });
        }
      }
    } catch (e) {
      debugPrint("Gagal mengambil foto komentar: $e");
    }
  }

  Future<void> _submitComment() async {
    if (_commentController.text.trim().isEmpty &&
        _selectedCommentImages.isEmpty)
      return;
    final user = _auth.currentUser;
    if (user == null) return;

    setState(() => _isCommentPosting = true);

    try {
      List<String> uploadedImageUrls = [];
      if (_selectedCommentImages.isNotEmpty) {
        uploadedImageUrls = await Future.wait(
          _selectedCommentImages.map(
            (image) => _storageService.uploadImage(image, 'comments'),
          ),
        );
      }

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      String username = 'User MacroFit';
      String profilePic = '';

      if (userDoc.exists && userDoc.data() != null) {
        final userData = userDoc.data() as Map<String, dynamic>;
        username =
            userData['username'] ?? userData['displayName'] ?? 'User MacroFit';
        profilePic =
            userData['profile_picture'] ??
            userData['profile_image_url'] ??
            userData['photoUrl'] ??
            '';
      }

      await _firestore
          .collection('posts')
          .doc(widget.postId)
          .collection('comments')
          .add({
            'uid': user.uid,
            'username': username,
            'profile_image': profilePic,
            'content': _commentController.text.trim(),
            'image_urls': uploadedImageUrls,
            'timestamp': FieldValue.serverTimestamp(),
          });

      await _firestore.collection('posts').doc(widget.postId).update({
        'comment_count': FieldValue.increment(1),
      });

      _commentController.clear();
      setState(() {
        _selectedCommentImages.clear();
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal membalas: $e')));
    } finally {
      if (mounted) setState(() => _isCommentPosting = false);
    }
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'Baru saja';
    DateTime commentDate = timestamp.toDate();
    DateTime nowDate = DateTime.now();
    Duration difference = nowDate.difference(commentDate);

    String timeString =
        "${commentDate.hour.toString().padLeft(2, '0')}:${commentDate.minute.toString().padLeft(2, '0')}";

    List<String> months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    String monthName = months[commentDate.month - 1];

    if (difference.inSeconds < 60) {
      return 'Baru saja';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} mnt lalu';
    } else if (difference.inHours < 24 && commentDate.day == nowDate.day) {
      return 'Hari ini, $timeString';
    } else if (commentDate.year == nowDate.year) {
      return '${commentDate.day} $monthName, $timeString';
    } else {
      return '${commentDate.day} $monthName ${commentDate.year}, $timeString';
    }
  }

  Future<void> _unsendComment(
    String commentId,
    List<dynamic>? imageUrls,
  ) async {
    bool confirmUnsend =
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Tarik Balasan'),
            content: const Text('Apakah Anda yakin ingin menarik balasan ini?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Tarik', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmUnsend) return;

    try {
      if (imageUrls != null && imageUrls.isNotEmpty) {
        for (var url in imageUrls) {
          try {
            await FirebaseStorage.instance.refFromURL(url.toString()).delete();
          } catch (e) {
            debugPrint("Gagal hapus file lampiran: $e");
          }
        }
      }

      await _firestore
          .collection('posts')
          .doc(widget.postId)
          .collection('comments')
          .doc(commentId)
          .update({
            'content': 'telah menarik pesan ini',
            'image_urls': [],
            'is_unsent': true,
          });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pesan berhasil ditarik.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal menarik pesan: $e')));
    }
  }

  Future<void> _editComment(String commentId, String currentContent) async {
    final TextEditingController editController = TextEditingController(
      text: currentContent,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Balasan'),
        content: TextField(
          controller: editController,
          maxLines: null,
          decoration: const InputDecoration(hintText: "Ubah balasan Anda..."),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              String newContent = editController.text.trim();
              if (newContent.isEmpty) return;

              try {
                await _firestore
                    .collection('posts')
                    .doc(widget.postId)
                    .collection('comments')
                    .doc(commentId)
                    .update({'content': newContent, 'is_edited': true});

                if (context.mounted) Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Balasan berhasil diperbarui.')),
                );
              } catch (e) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Gagal mengedit: $e')));
              }
            },
            child: const Text(
              'Simpan',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // 🔥 FUNGSI REPLIKASI UX: Menyisipkan teks tag @username ke form input & buka keyboard
  void _triggerReply(String targetUsername) {
    setState(() {
      _commentController.text = "@$targetUsername ";
      // Pindahkan kursor teks ke baris paling kanan setelah nama user
      _commentController.selection = TextSelection.fromPosition(
        TextPosition(offset: _commentController.text.length),
      );
    });
    // Picu keyboard HP menyembul fokus ke kolom
    _inputFocusNode.requestFocus();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _inputFocusNode.dispose(); // Hapus focusNode dari memori
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _auth.currentUser;
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Balasan Thread',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.appBarTheme.foregroundColor,
        elevation: 0,
      ),
      resizeToAvoidBottomInset: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header: Isi Postingan Utama yang Dikomentari
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: isDarkMode ? const Color(0xFF161616) : Colors.grey[100],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.postUsername,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.teal,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.postContent,
                    style: const TextStyle(fontSize: 15),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 1),

            // Daftar Komentar Real-time
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('posts')
                    .doc(widget.postId)
                    .collection('comments')
                    .orderBy('timestamp', descending: false)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text(
                        'Belum ada balasan. Mulai obrolan!',
                        style: TextStyle(color: Colors.grey),
                      ),
                    );
                  }

                  final comments = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: comments.length,
                    itemBuilder: (context, index) {
                      final commentDoc = comments[index];
                      final commentId = commentDoc.id;
                      final commentData =
                          commentDoc.data() as Map<String, dynamic>;

                      String username = commentData['username'] ?? 'User';
                      String content = commentData['content'] ?? '';
                      String commentProfilePic =
                          commentData['profile_image'] ?? '';

                      final List<dynamic> commentImages =
                          commentData['image_urls'] is List
                          ? commentData['image_urls']
                          : (commentData['image_url'] != null &&
                                    commentData['image_url']
                                        .toString()
                                        .isNotEmpty
                                ? [commentData['image_url']]
                                : []);

                      String commentUid = commentData['uid'] ?? '';
                      bool isUnsent = commentData['is_unsent'] ?? false;
                      bool isEdited = commentData['is_edited'] ?? false;
                      bool isMyComment =
                          currentUser != null && commentUid == currentUser.uid;

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 14,
                                        backgroundColor: theme.primaryColor
                                            .withOpacity(0.15),
                                        backgroundImage:
                                            commentProfilePic.isNotEmpty
                                            ? NetworkImage(commentProfilePic)
                                            : null,
                                        child: commentProfilePic.isEmpty
                                            ? Icon(
                                                Icons.person,
                                                size: 14,
                                                color: theme.primaryColor,
                                              )
                                            : null,
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        username,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                        _formatTimestamp(
                                          commentData['timestamp']
                                              as Timestamp?,
                                        ),
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 11,
                                        ),
                                      ),
                                      if (isMyComment && !isUnsent)
                                        PopupMenuButton<String>(
                                          icon: const Icon(
                                            Icons.more_vert,
                                            size: 18,
                                            color: Colors.grey,
                                          ),
                                          padding: EdgeInsets.zero,
                                          onSelected: (value) {
                                            if (value == 'edit') {
                                              _editComment(commentId, content);
                                            } else if (value == 'unsend') {
                                              _unsendComment(
                                                commentId,
                                                commentImages,
                                              );
                                            }
                                          },
                                          itemBuilder: (context) => [
                                            const PopupMenuItem(
                                              value: 'edit',
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons.edit_outlined,
                                                    size: 18,
                                                    color: Colors.blue,
                                                  ),
                                                  SizedBox(width: 8),
                                                  Text('Edit Pesan'),
                                                ],
                                              ),
                                            ),
                                            const PopupMenuItem(
                                              value: 'unsend',
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons.undo,
                                                    size: 18,
                                                    color: Colors.redAccent,
                                                  ),
                                                  SizedBox(width: 8),
                                                  Text(
                                                    'Tarik Pesan',
                                                    style: TextStyle(
                                                      color: Colors.redAccent,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),

                              // AREA TEKS BALASAN KOMENTAR
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Expanded(
                                    // 🔥 INTEGRASI UX DETEKSI @MENTION:
                                    // Jika pesan diawali dengan karakter '@', kita beri warna khusus yang kontras menarik
                                    child: content.startsWith('@') && !isUnsent
                                        ? RichText(
                                            text: TextSpan(
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: isDarkMode
                                                    ? Colors.white
                                                    : Colors.black87,
                                              ),
                                              children: [
                                                TextSpan(
                                                  text:
                                                      content.split(' ').first +
                                                      ' ', // Ambil kata @username-nya
                                                  style: TextStyle(
                                                    color: theme
                                                        .primaryColor, // Warna teks mention mengikuti tema
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                TextSpan(
                                                  text: content.substring(
                                                    content.indexOf(' ') + 1,
                                                  ), // Ambil sisa isi pesannya
                                                ),
                                              ],
                                            ),
                                          )
                                        : Text(
                                            isUnsent
                                                ? '$username $content'
                                                : content,
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: isUnsent
                                                  ? Colors.grey
                                                  : (isDarkMode
                                                        ? Colors.white
                                                        : Colors.black87),
                                              fontStyle: isUnsent
                                                  ? FontStyle.italic
                                                  : FontStyle.normal,
                                            ),
                                          ),
                                  ),
                                  if (isEdited && !isUnsent)
                                    const Padding(
                                      padding: EdgeInsets.only(left: 6.0),
                                      child: Text(
                                        '(edited)',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ),
                                ],
                              ),

                              if (!isUnsent && commentImages.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: SizedBox(
                                    height: 110,
                                    child: ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: commentImages.length,
                                      itemBuilder: (context, imgIndex) {
                                        return Container(
                                          margin: const EdgeInsets.only(
                                            right: 8,
                                          ),
                                          width: 110,
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            child: Image.network(
                                              commentImages[imgIndex]
                                                  .toString(),
                                              fit: BoxFit.cover,
                                              loadingBuilder:
                                                  (context, child, progress) {
                                                    if (progress == null)
                                                      return child;
                                                    return const Center(
                                                      child:
                                                          CircularProgressIndicator(
                                                            strokeWidth: 1.5,
                                                          ),
                                                    );
                                                  },
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),

                              // 🔥 TOMBOL UTAMA ACTION REPLY
                              if (!isUnsent)
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton.icon(
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      minimumSize: const Size(50, 24),
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    icon: const Icon(
                                      Icons.reply_outlined,
                                      size: 14,
                                      color: Colors.grey,
                                    ),
                                    label: const Text(
                                      "Reply",
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    onPressed: () => _triggerReply(
                                      username,
                                    ), // Picu auto mention
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const Divider(height: 1, thickness: 1),

            StreamBuilder<DocumentSnapshot>(
              stream: _firestore
                  .collection('users')
                  .doc(currentUser?.uid)
                  .snapshots(),
              builder: (context, userSnapshot) {
                String currentUserAvatarUrl = '';
                if (userSnapshot.hasData && userSnapshot.data!.exists) {
                  final userData =
                      userSnapshot.data!.data() as Map<String, dynamic>?;
                  currentUserAvatarUrl =
                      userData?['profile_picture'] ??
                      userData?['profile_image_url'] ??
                      userData?['photoUrl'] ??
                      '';
                }

                // 🌟 CATATAN: Di dalam post_input_section.dart pastikan widget TextField-nya
                // dipasangkan properti focusNode: widget.focusNode (jika ingin keyboard menyembul otomatis)
                return PostInputSection(
                  controller: _commentController,
                  selectedImages: _selectedCommentImages,
                  currentUserImageUrl: currentUserAvatarUrl,
                  onPickImage: _pickCommentImages,
                  isPosting: _isCommentPosting,
                  onCreatePost: _submitComment,
                  onClearImage: () =>
                      setState(() => _selectedCommentImages.clear()),
                  onRemoveSpecificImage: (index) {
                    setState(() {
                      _selectedCommentImages.removeAt(index);
                    });
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
