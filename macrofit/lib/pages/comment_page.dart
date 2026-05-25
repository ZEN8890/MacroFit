import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
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
  String? _editingCommentId; // 🟢 STATE PENGATUR MODE EDIT

  @override
  void dispose() {
    _commentController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  Future<void> _pickCommentImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage();
      if (images.isNotEmpty) {
        int total = _selectedCommentImages.length + images.length;
        if (total > 3) {
          int sisa = 3 - _selectedCommentImages.length;
          if (sisa > 0)
            setState(() => _selectedCommentImages.addAll(images.take(sisa)));
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('⚠️ Maksimal 3 foto!')));
        } else {
          setState(() => _selectedCommentImages.addAll(images));
        }
      }
    } catch (e) {
      debugPrint("Gagal mengambil foto: $e");
    }
  }

  // 🟢 LOGIKA SUBMIT KOMBINASI (TAMBAH & EDIT)
  Future<void> _submitComment() async {
    if (_commentController.text.trim().isEmpty &&
        _selectedCommentImages.isEmpty)
      return;
    final user = _auth.currentUser;
    if (user == null) return;

    setState(() => _isCommentPosting = true);

    try {
      // --- MODE EDIT (Update) ---
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
        _editingCommentId = null; // Reset mode
      }
      // --- MODE TAMBAH BARU (Create) ---
      else {
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
        await _firestore
            .collection('posts')
            .doc(widget.postId)
            .collection('comments')
            .add({
              'uid': user.uid,
              'username': userDoc.data()?['username'] ?? 'User MacroFit',
              'username_handle': userDoc.data()?['username_handle'] ?? '',
              'profile_image': userDoc.data()?['profile_picture'] ?? '',
              'content': _commentController.text.trim(),
              'image_urls': uploadedImageUrls,
              'timestamp': FieldValue.serverTimestamp(),
            });

        await _firestore.collection('posts').doc(widget.postId).update({
          'comment_count': FieldValue.increment(1),
        });
      }

      _commentController.clear();
      setState(() => _selectedCommentImages.clear());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _editingCommentId == null
                  ? 'Balasan terkirim!'
                  : 'Pesan diperbarui',
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal: $e')));
    } finally {
      if (mounted) setState(() => _isCommentPosting = false);
    }
  }

  Future<void> _unsendComment(
    String commentId,
    List<dynamic>? imageUrls,
  ) async {
    // Implementasi unsend dengan dialog konfirmasi seperti kode sebelumnya...
    // (Penting: Hapus juga file dari Storage jika ada)
  }

  void _editComment(String commentId, String currentContent) {
    setState(() {
      _editingCommentId = commentId;
      _commentController.text = currentContent;
    });
    FocusScope.of(context).requestFocus(_inputFocusNode);
  }

  void _triggerReply(String targetUsername) {
    setState(() {
      _commentController.text = "@$targetUsername ";
      _commentController.selection = TextSelection.fromPosition(
        TextPosition(offset: _commentController.text.length),
      );
    });
    FocusScope.of(context).requestFocus(_inputFocusNode);
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _auth.currentUser;
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _editingCommentId != null ? 'Edit Balasan' : 'Balasan Thread',
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
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
                  Text(widget.postContent),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('posts')
                    .doc(widget.postId)
                    .collection('comments')
                    .orderBy('timestamp')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData)
                    return const Center(child: CircularProgressIndicator());
                  final comments = snapshot.data!.docs;
                  return ListView.builder(
                    itemCount: comments.length,
                    itemBuilder: (context, index) {
                      final doc = comments[index];
                      return CommentCard(
                        commentId: doc.id,
                        commentData: doc.data() as Map<String, dynamic>,
                        currentUserId: currentUser?.uid ?? '',
                        theme: theme,
                        isDarkMode: isDarkMode,
                        onEdit: _editComment,
                        onUnsend: _unsendComment,
                        onReplyTrigger: _triggerReply,
                      );
                    },
                  );
                },
              ),
            ),
            StreamBuilder<DocumentSnapshot>(
              stream: _firestore
                  .collection('users')
                  .doc(currentUser?.uid)
                  .snapshots(),
              builder: (context, snap) {
                String pic = snap.hasData && snap.data!.exists
                    ? (snap.data!.data() as Map)['profile_picture'] ?? ''
                    : '';
                return PostInputSection(
                  controller: _commentController,
                  focusNode: _inputFocusNode,
                  selectedImages: _selectedCommentImages,
                  currentUserImageUrl: pic,
                  onPickImage: _pickCommentImages,
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
      ),
    );
  }
}
