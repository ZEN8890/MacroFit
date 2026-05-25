import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../services/storage_services.dart';
import '../widgets/post_input_section.dart';
import '../widgets/comment_card.dart';

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
      }

      _commentController.clear();
      setState(() {
        _selectedCommentImages.clear();
        _editingCommentId = null;
        _replyToParentId = null;
      });
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal: $e')));
    } finally {
      if (mounted) setState(() => _isCommentPosting = false);
    }
  }

  void _triggerReply(String targetHandle, String commentId) {
    setState(() {
      _replyToParentId = commentId;
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
    final textColor =
        theme.textTheme.bodyMedium?.color ??
        (isDarkMode ? Colors.white : Colors.black87);

    return Scaffold(
      appBar: AppBar(
        title: Text(_editingCommentId != null ? 'Edit Komentar' : 'Balasan'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: RichText(
              text: TextSpan(
                style: TextStyle(color: textColor),
                children: [
                  TextSpan(
                    text: "${widget.postUsername} ",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: widget.postContent),
                ],
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
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());

                final allDocs = snapshot.data!.docs;

                // Mengurutkan komentar agar balasan selalu ada di bawah induknya
                // Logika: Induk muncul duluan, lalu anaknya (Level 2), lalu anaknya (Level 3)
                final List<QueryDocumentSnapshot> sortedDocs = [];
                final parents = allDocs
                    .where((d) => (d.data() as Map)['parent_id'] == null)
                    .toList();

                for (var p in parents) {
                  sortedDocs.add(p);
                  sortedDocs.addAll(
                    allDocs.where(
                      (d) => (d.data() as Map)['parent_id'] == p.id,
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: sortedDocs.length,
                  itemBuilder: (_, index) {
                    final doc = sortedDocs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final bool isReply =
                        data['parent_id'] != null &&
                        data['parent_id'].toString().isNotEmpty;

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
                        isRepliesHidden: false,
                        onToggleHideReplies: () {},
                        onEdit: (id, content) => setState(() {
                          _editingCommentId = id;
                          _commentController.text = content;
                          FocusScope.of(context).requestFocus(_inputFocusNode);
                        }),
                        onUnsend: (id, _) {},
                        onReplyTrigger: (handle) =>
                            _triggerReply(handle, doc.id),
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
                  if (images.isNotEmpty)
                    setState(
                      () => _selectedCommentImages.addAll(
                        images.take(3 - _selectedCommentImages.length),
                      ),
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
