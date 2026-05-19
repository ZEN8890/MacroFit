import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../services/storage_services.dart';
import '../widgets/post_input_section.dart';
import '../widgets/post_list_stream.dart';

class ForumPage extends StatefulWidget {
  const ForumPage({super.key});

  @override
  State<ForumPage> createState() => _ForumPageState();
}

class _ForumPageState extends State<ForumPage> {
  final TextEditingController _postController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  XFile? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  final StorageService _storageService = StorageService();
  bool _isPosting = false;

  Future<void> _createPost() async {
    if (_postController.text.trim().isEmpty && _selectedImage == null) return;
    final user = _auth.currentUser;
    if (user == null) return;

    setState(() => _isPosting = true);

    try {
      String imageUrl = '';
      if (_selectedImage != null) {
        imageUrl = await _storageService.uploadImage(_selectedImage!, 'posts');
      }

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      String username = userDoc.exists
          ? (userDoc.data()?['username'] ?? 'Anonymous')
          : 'Anonymous';
      String profilePic = userDoc.exists
          ? (userDoc.data()?['profile_picture'] ?? '')
          : '';

      await _firestore.collection('posts').add({
        'uid': user.uid,
        'username': username,
        'profile_image': profilePic,
        'content': _postController.text.trim(),
        'image_url': imageUrl,
        'timestamp': FieldValue.serverTimestamp(),
        'likes': [],
        'comment_count': 0,
      });

      _postController.clear();
      setState(() => _selectedImage = null);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thread berhasil dibagikan!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal mengirim postingan: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isPosting = false);
      }
    }
  }

  Future<void> _toggleLike(String postId, List<dynamic> likes) async {
    final user = _auth.currentUser;
    if (user == null) return;
    final postRef = _firestore.collection('posts').doc(postId);

    try {
      if (likes.contains(user.uid)) {
        await postRef.update({
          'likes': FieldValue.arrayRemove([user.uid]),
        });
      } else {
        await postRef.update({
          'likes': FieldValue.arrayUnion([user.uid]),
        });
      }
    } catch (e) {
      debugPrint("Error toggling like: $e");
    }
  }

  Future<void> _deletePost(String postId, String? imageUrl) async {
    bool confirmDelete =
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'Hapus Thread',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: const Text(
              'Apakah Anda yakin ingin menghapus thread ini?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(
                  'Batal',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Hapus',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmDelete) return;

    try {
      if (imageUrl != null && imageUrl.isNotEmpty) {
        try {
          await FirebaseStorage.instance.refFromURL(imageUrl).delete();
        } catch (e) {
          debugPrint("Gagal hapus image di storage: $e");
        }
      }
      await _firestore.collection('posts').doc(postId).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thread berhasil dihapus.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal menghapus thread: $e')));
      }
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) setState(() => _selectedImage = image);
  }

  @override
  void dispose() {
    _postController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _auth.currentUser;
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: theme.scaffoldBackgroundColor,
        body: SafeArea(
          child: NestedScrollView(
            headerSliverBuilder:
                (BuildContext context, bool innerBoxIsScrolled) {
                  return <Widget>[
                    SliverAppBar(
                      title: const Text(
                        "MacroFit Community",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      pinned: true,
                      floating: true,
                      forceElevated: innerBoxIsScrolled,
                      backgroundColor: theme.appBarTheme.backgroundColor,
                      foregroundColor: theme.appBarTheme.foregroundColor,
                      elevation: 0,
                      bottom: TabBar(
                        labelColor: isDarkMode
                            ? Colors.white
                            : theme.primaryColor,
                        unselectedLabelColor: isDarkMode
                            ? Colors.white38
                            : Colors.black38,
                        indicatorColor: theme.primaryColor,
                        indicatorSize: TabBarIndicatorSize.tab,
                        tabs: const [
                          Tab(
                            text: 'Semua Forum',
                            icon: Icon(Icons.forum_outlined, size: 20),
                          ),
                          Tab(
                            text: 'Thread Saya',
                            icon: Icon(Icons.assignment_ind_outlined, size: 20),
                          ),
                        ],
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          PostInputSection(
                            controller: _postController,
                            selectedImage: _selectedImage,
                            onPickImage: _pickImage,
                            isPosting: _isPosting,
                            onCreatePost: _createPost,
                            onClearImage: () =>
                                setState(() => _selectedImage = null),
                          ),
                          const Divider(thickness: 1, height: 1),
                        ],
                      ),
                    ),
                  ];
                },
            // 🔥 PERBAIKAN MUTLAK: Pembungkus Padding bottom 50.0 dibuang total
            // Sekarang TabBarView terpasang bersih agar scrolling lancar seamless tanpa terpotong
            body: TabBarView(
              children: [
                PostListStream(
                  filterUid: null,
                  firestore: _firestore,
                  auth: _auth,
                  onDeletePost: _deletePost,
                  onLikeToggle: _toggleLike,
                ),
                PostListStream(
                  filterUid: currentUser?.uid,
                  firestore: _firestore,
                  auth: _auth,
                  onDeletePost: _deletePost,
                  onLikeToggle: _toggleLike,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
