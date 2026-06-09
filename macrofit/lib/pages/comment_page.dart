import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../services/storage_services.dart';
import '../widgets/post_input_section.dart';
import '../widgets/comment_card.dart';
import '../utils/notification_helper.dart';
import '../utils/global_state.dart';

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
  final FocusNode _inputFocusNode = FocusNode();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ImagePicker _picker = ImagePicker();
  final StorageService _storageService = StorageService();

  final List<XFile> _selectedCommentImages = [];
  bool _isCommentPosting = false;
  String? _editingCommentId;
  String? _replyToParentId;
  Map<String, dynamic>? _replyingToCommentData;

  // 🟢 PERBAIKAN STATE: Mengubah dari Map<String, bool> menjadi Map<String, int>
  // untuk melacak jumlah limit balasan yang diizinkan tampil per Komentar Utama
  final Map<String, int> _repliesLimitMap = {};

  @override
  void dispose() {
    _commentController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  Future<void> _submitComment() async {
    if (_commentController.text.trim().isEmpty &&
        _selectedCommentImages.isEmpty) {
      return;
    }
    final user = _auth.currentUser;
    if (user == null) return;

    setState(() => _isCommentPosting = true);

    try {
      if (_editingCommentId != null) {
        await _firestore
            .collection('posts')
            .doc(widget.postId)
            .collection('comments')
            .doc(_editingCommentId)
            .update({
              'content': _commentController.text.trim(),
              'is_edited': true,
            });
        Notify.success(
          context,
          isEnglishNotifier.value
              ? "Comment updated successfully"
              : "Komentar berhasil diperbarui",
        );
      } else {
        List<String> uploadedImageUrls = [];
        if (_selectedCommentImages.isNotEmpty) {
          uploadedImageUrls = await Future.wait(
            _selectedCommentImages.map(
              (img) => _storageService.uploadImage(img, 'comments'),
            ),
          );
        }

        final userDoc = await _firestore
            .collection('users')
            .doc(user.uid)
            .get();
        final userData = userDoc.data();

        await _firestore
            .collection('posts')
            .doc(widget.postId)
            .collection('comments')
            .add({
              'uid': user.uid,
              'parent_id': _replyToParentId,
              'parent_username': _replyingToCommentData?['username'] ?? '',
              'parent_content': _replyingToCommentData?['content'] ?? '',
              'postId_reference': widget.postId,
              'username': userData?['username'] ?? 'User',
              'username_handle': userData?['username_handle'] ?? '',
              'profile_image': userData?['profile_picture'] ?? '',
              'content': _commentController.text.trim(),
              'image_urls': uploadedImageUrls,
              'timestamp': FieldValue.serverTimestamp(),
              'is_edited': false,
            });

        await _firestore.collection('posts').doc(widget.postId).update({
          'comment_count': FieldValue.increment(1),
        });
        Notify.success(
          context,
          isEnglishNotifier.value
              ? "Comment posted successfully"
              : "Komentar berhasil dikirim",
        );
      }

      _commentController.clear();
      setState(() {
        _selectedCommentImages.clear();
        _editingCommentId = null;
        _replyToParentId = null;
        _replyingToCommentData = null;
      });
      FocusScope.of(context).unfocus();
    } catch (e) {
      Notify.error(
        context,
        isEnglishNotifier.value
            ? "Failed to post comment: $e"
            : "Gagal mengirim komentar: $e",
      );
    } finally {
      if (mounted) setState(() => _isCommentPosting = false);
    }
  }

  void _triggerReply(
    String targetHandle,
    String commentId,
    Map<String, dynamic> commentData,
  ) {
    setState(() {
      _replyToParentId = commentId;
      _replyingToCommentData = commentData;
      _commentController.text = "@${targetHandle.replaceAll('@', '')} ";
      _commentController.selection = TextSelection.fromPosition(
        TextPosition(offset: _commentController.text.length),
      );
    });
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) FocusScope.of(context).requestFocus(_inputFocusNode);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return ValueListenableBuilder<bool>(
      valueListenable: isEnglishNotifier,
      builder: (context, englishActive, child) {
        return Scaffold(
          resizeToAvoidBottomInset: true,
          appBar: AppBar(
            title: Text(
              _editingCommentId != null
                  ? (englishActive ? 'Edit Comment' : 'Edit Komentar')
                  : (englishActive ? 'Replies' : 'Balasan'),
            ),
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    widget.postContent,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _firestore
                      .collection('posts')
                      .doc(widget.postId)
                      .collection('comments')
                      .orderBy('timestamp', descending: false)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final allDocs = snapshot.data!.docs;
                    final List<QueryDocumentSnapshot> rootComments = [];
                    final Map<String, List<QueryDocumentSnapshot>>
                    directRepliesMap = {};
                    final Map<String, String> childToParentRelation = {};

                    for (var doc in allDocs) {
                      final data = doc.data() as Map<String, dynamic>?;
                      if (data == null) continue;
                      final String? pId = data['parent_id'];
                      if (pId != null && pId.trim().isNotEmpty) {
                        childToParentRelation[doc.id] = pId;
                      }
                    }

                    for (var doc in allDocs) {
                      final data = doc.data() as Map<String, dynamic>?;
                      if (data == null) continue;
                      final String? pId = data['parent_id'];

                      if (pId == null || pId.trim().isEmpty) {
                        rootComments.add(doc);
                      } else {
                        String topRootId = pId;
                        while (childToParentRelation.containsKey(topRootId)) {
                          topRootId = childToParentRelation[topRootId]!;
                        }
                        if (!directRepliesMap.containsKey(topRootId)) {
                          directRepliesMap[topRootId] = [];
                        }
                        directRepliesMap[topRootId]!.add(doc);
                      }
                    }

                    final List<Map<String, dynamic>> finalDisplayList = [];

                    for (var rootDoc in rootComments) {
                      finalDisplayList.add({
                        'type': 'parent',
                        'doc': rootDoc,
                        'rootId': rootDoc.id,
                      });

                      final String rootId = rootDoc.id;
                      final List<QueryDocumentSnapshot> allChainReplies =
                          directRepliesMap[rootId] ?? [];

                      if (allChainReplies.isNotEmpty) {
                        // 🟢 INITIAL LIMIT CONFIG: Default awal jika belum diklik, tampilkan 2 balasan teratas
                        if (!_repliesLimitMap.containsKey(rootId)) {
                          _repliesLimitMap[rootId] = 2;
                        }

                        final int currentLimit = _repliesLimitMap[rootId]!;
                        final List<QueryDocumentSnapshot> displayReplies =
                            allChainReplies.take(currentLimit).toList();

                        for (var replyDoc in displayReplies) {
                          finalDisplayList.add({
                            'type': 'reply',
                            'doc': replyDoc,
                            'rootId': rootId,
                          });
                        }

                        // Hitung sisa balasan yang masih tersembunyi
                        final int remainingRepliesCount =
                            allChainReplies.length - displayReplies.length;

                        // 🟢 RENDER LOGIKA TOMBOL DINAMIS (PAGINATION 3 PER 3)
                        if (remainingRepliesCount > 0) {
                          // Jika masih ada sisa komentar, tampilkan tombol "Lihat balasan" dengan sisa counternya
                          finalDisplayList.add({
                            'type': 'load_more_button',
                            'rootId': rootId,
                            'remainingCount': remainingRepliesCount,
                            'currentLimit': currentLimit,
                          });
                        }

                        if (displayReplies.length > 2) {
                          // Jika user sudah terlanjur membuka banyak balasan, munculkan tombol untuk menutup kembali
                          finalDisplayList.add({
                            'type': 'collapse_button',
                            'rootId': rootId,
                          });
                        }
                      }
                    }

                    if (finalDisplayList.isEmpty) {
                      return Center(
                        child: Text(
                          englishActive
                              ? 'No replies yet.'
                              : 'Belum ada balasan.',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.only(top: 8, bottom: 20),
                      itemCount: finalDisplayList.length,
                      itemBuilder: (_, index) {
                        final item = finalDisplayList[index];

                        // 🟢 1. HANDLER TOMBOL "LIHAT BALASAN (+3)"
                        if (item['type'] == 'load_more_button') {
                          final String rId = item['rootId'];
                          final int remaining = item['remainingCount'];
                          final int currentLimit = item['currentLimit'];

                          // Tentukan angka lompatan counter berikutnya (maksimal 3, atau sisa yang ada)
                          final int nextStepCount = remaining >= 3
                              ? 3
                              : remaining;

                          return Padding(
                            padding: const EdgeInsets.only(
                              left: 48.0,
                              bottom: 8.0,
                              top: 2.0,
                            ),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    // Tambah limit tampilan sebanyak 3 baris secara bertahap
                                    _repliesLimitMap[rId] = currentLimit + 3;
                                  });
                                },
                                borderRadius: BorderRadius.circular(4),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6.0,
                                    vertical: 4.0,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.expand_more,
                                        size: 16,
                                        color: theme.primaryColor,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        englishActive
                                            ? 'View more replies ($remaining left)'
                                            : 'Lihat balasan berikutnya ($remaining sisa)',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: theme.primaryColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }

                        // 🟢 2. HANDLER TOMBOL "SEMBUNYIKAN BALASAN"
                        if (item['type'] == 'collapse_button') {
                          final String rId = item['rootId'];
                          return Padding(
                            padding: const EdgeInsets.only(
                              left: 48.0,
                              bottom: 12.0,
                              top: 2.0,
                            ),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    // Kembalikan limit ke ukuran semula (2 baris)
                                    _repliesLimitMap[rId] = 2;
                                  });
                                },
                                borderRadius: BorderRadius.circular(4),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6.0,
                                    vertical: 4.0,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.expand_less,
                                        size: 16,
                                        color: Colors.grey.shade600,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        englishActive
                                            ? 'Hide replies'
                                            : 'Sembunyikan balasan',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }

                        // 3. RENDER KARTU KOMENTAR ASLI (PARENT & REPLIES)
                        final doc = item['doc'] as QueryDocumentSnapshot;
                        final data = doc.data() as Map<String, dynamic>;
                        final bool isReply = item['type'] == 'reply';

                        return Padding(
                          padding: EdgeInsets.only(
                            left: isReply ? 48.0 : 0.0,
                            bottom: 4.0,
                          ),
                          child: CommentCard(
                            commentId: doc.id,
                            postId: widget.postId,
                            commentData: data,
                            currentUserId: _auth.currentUser?.uid ?? '',
                            theme: theme,
                            isDarkMode: isDarkMode,
                            isRepliesHidden: isReply
                                ? false
                                : ((_repliesLimitMap[doc.id] ?? 2) <= 2),
                            onToggleHideReplies: () {},
                            onEdit: (id, content) => setState(() {
                              _editingCommentId = id;
                              _commentController.text = content;
                              FocusScope.of(
                                context,
                              ).requestFocus(_inputFocusNode);
                            }),
                            onUnsend: (id, _) {},
                            onReplyTrigger: (handle) =>
                                _triggerReply(handle, doc.id, data),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              StreamBuilder<DocumentSnapshot>(
                stream: _firestore
                    .collection('users')
                    .doc(_auth.currentUser?.uid)
                    .snapshots(),
                builder: (context, snap) {
                  String pic = (snap.hasData && snap.data!.exists)
                      ? (snap.data!.data() as Map)['profile_picture'] ?? ''
                      : '';
                  return PostInputSection(
                    controller: _commentController,
                    focusNode: _inputFocusNode,
                    selectedImages: _selectedCommentImages,
                    currentUserImageUrl: pic,
                    onPickImage: () async {
                      final List<XFile> images = await _picker.pickMultiImage();
                      if (images.isNotEmpty) {
                        setState(
                          () => _selectedCommentImages.addAll(images.take(3)),
                        );
                      }
                    },
                    isPosting: _isCommentPosting,
                    onCreatePost: _submitComment,
                    onClearImage: () =>
                        setState(() => _selectedCommentImages.clear()),
                    onRemoveSpecificImage: (i) =>
                        setState(() => _selectedCommentImages.removeAt(i)),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
