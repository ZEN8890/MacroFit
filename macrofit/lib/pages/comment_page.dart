import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../services/storage_services.dart';
import '../widgets/post_input_section.dart';
import '../widgets/comment_card.dart';
import '../utils/notification_helper.dart'; // Import helper notifikasi

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

  List<XFile> _selectedCommentImages = [];
  bool _isCommentPosting = false;
  String? _editingCommentId;
  String? _replyToParentId;
  Map<String, dynamic>? _replyingToCommentData;

  @override
  void dispose() {
    _commentController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  Future<void> _submitComment() async {
    if (_commentController.text.trim().isEmpty &&
        _selectedCommentImages.isEmpty)
      return;
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
        Notify.success(context, "Komentar berhasil diperbarui");
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
        Notify.success(context, "Komentar berhasil dikirim");
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
      Notify.error(context, "Gagal mengirim komentar: $e");
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

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(_editingCommentId != null ? 'Edit Komentar' : 'Balasan'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              widget.postContent,
              style: const TextStyle(fontWeight: FontWeight.w500),
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
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());
                final allDocs = snapshot.data!.docs;
                return ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 20),
                  itemCount: allDocs.length,
                  itemBuilder: (_, index) {
                    final doc = allDocs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    return Padding(
                      padding: EdgeInsets.only(
                        left: (data['parent_id'] != null) ? 48.0 : 0.0,
                        bottom: 4.0,
                      ),
                      child: CommentCard(
                        commentId: doc.id,
                        postId: widget.postId,
                        commentData: data,
                        currentUserId: _auth.currentUser?.uid ?? '',
                        theme: theme,
                        isDarkMode: isDarkMode,
                        isRepliesHidden: false,
                        onToggleHideReplies: () {},
                        onEdit: (id, content) => setState(() {
                          _editingCommentId = id;
                          _commentController.text = content;
                          FocusScope.of(context).requestFocus(_inputFocusNode);
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: theme.primaryColor.withOpacity(0.1),
              child: Row(
                children: [
                  Icon(Icons.reply, size: 16, color: theme.primaryColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Membalas ke @${_replyingToCommentData!['username']}: \"${_getPreview(_replyingToCommentData!['content'])}\"",
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
                  if (images.isNotEmpty)
                    setState(
                      () => _selectedCommentImages.addAll(images.take(3)),
                    );
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
  }
}
