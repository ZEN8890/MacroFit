import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../services/storage_services.dart';
import '../widgets/post_input_section.dart';
import '../widgets/comment_card.dart';
import '../utils/notification_helper.dart';
import '../utils/global_state.dart'; // 🟢 IMPORT SAKLAR GLOBAL STATE

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

  final Map<String, bool> _hiddenRepliesMap = {};

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

  String _getPreview(String text) {
    if (text.length <= 20) return text;
    return "${text.substring(0, 20)}...";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    // 🟢 REAKTIF MULTI-BAHASA: Membungkus halaman Forum balasan dengan ValueListenableBuilder
    return ValueListenableBuilder<bool>(
      valueListenable: isEnglishNotifier,
      builder: (context, englishActive, child) {
        return Scaffold(
          resizeToAvoidBottomInset: true,
          appBar: AppBar(
            // 🟢 DINAMIS MULTI-BAHASA PADA TITLE APPBAR
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
                        if (!_hiddenRepliesMap.containsKey(rootId)) {
                          _hiddenRepliesMap[rootId] = true;
                        }

                        final bool isHidden = _hiddenRepliesMap[rootId]!;

                        final List<QueryDocumentSnapshot> displayReplies =
                            isHidden
                            ? allChainReplies.take(2).toList()
                            : allChainReplies;

                        for (var replyDoc in displayReplies) {
                          finalDisplayList.add({
                            'type': 'reply',
                            'doc': replyDoc,
                            'rootId': rootId,
                          });
                        }

                        finalDisplayList.add({
                          'type': 'button',
                          'rootId': rootId,
                          'totalReplies': allChainReplies.length,
                          'isHidden': isHidden,
                        });
                      }
                    }

                    if (finalDisplayList.isEmpty) {
                      return Center(
                        child: Text(
                          // 🟢 DINAMIS MULTI-BAHASA JIKA KOMENTAR MASIH KOSONG
                          englishActive
                              ? 'No replies yet. Be the first to reply!'
                              : 'Belum ada balasan. Jadilah yang pertama!',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.only(top: 8, bottom: 20),
                      itemCount: finalDisplayList.length,
                      itemBuilder: (_, index) {
                        final item = finalDisplayList[index];

                        if (item['type'] == 'button') {
                          final String rId = item['rootId'];
                          final bool isHidden = item['isHidden'];
                          final int total = item['totalReplies'];

                          return Padding(
                            padding: const EdgeInsets.only(
                              left: 48.0,
                              bottom: 12.0,
                              top: 4.0,
                            ),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    _hiddenRepliesMap[rId] = !isHidden;
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
                                        isHidden
                                            ? Icons.expand_more
                                            : Icons.expand_less,
                                        size: 16,
                                        color: theme.primaryColor,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        // 🟢 DINAMIS MULTI-BAHASA PADA TOMBOL EXPAND BALASAN THREAD
                                        isHidden
                                            ? (englishActive
                                                  ? 'View replies ($total)'
                                                  : 'Lihat balasan ($total)')
                                            : (englishActive
                                                  ? 'Hide replies'
                                                  : 'Sembunyikan balasan'),
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
                                : (_hiddenRepliesMap[doc.id] ?? true),
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
              if (_replyingToCommentData != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  color: theme.primaryColor.withOpacity(0.1),
                  child: Row(
                    children: [
                      Icon(Icons.reply, size: 16, color: theme.primaryColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          // 🟢 DINAMIS MULTI-BAHASA PADA LABEL PREVIEW TINDAKAN MEMBALAS KOMENTAR
                          englishActive
                              ? "Replying to @${_replyingToCommentData!['username']}: \"${_getPreview(_replyingToCommentData!['content'])}\""
                              : "Membalas ke @${_replyingToCommentData!['username']}: \"${_getPreview(_replyingToCommentData!['content'])}\"",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.primaryColor,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 16),
                        onPressed: () => setState(() {
                          _replyToParentId = null;
                          _replyingToCommentData = null;
                          _commentController.clear();
                        }),
                      ),
                    ],
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
