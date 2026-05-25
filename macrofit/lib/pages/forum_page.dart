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
  List<XFile> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();
  final StorageService _storageService = StorageService();
  bool _isPosting = false;

  String _forumRefreshKey = DateTime.now().millisecondsSinceEpoch.toString();

  Future<void> _createPost() async {
    if (_postController.text.trim().isEmpty && _selectedImages.isEmpty) return;
    final user = _auth.currentUser;
    if (user == null) return;

    setState(() => _isPosting = true);

    try {
      List<String> imageUrls = [];
      if (_selectedImages.isNotEmpty) {
        imageUrls = await Future.wait(
          _selectedImages.map(
            (image) => _storageService.uploadImage(image, 'posts'),
          ),
        );
      }

      // Ambil data user untuk memastikan handle terbaru
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data();

      String username = 'User MacroFit';
      String profilePic = '';
      String handle = '';

      if (userDoc.exists && userData != null) {
        username =
            userData['username'] ?? userData['displayName'] ?? 'User MacroFit';
        profilePic =
            userData['profile_picture'] ??
            userData['profile_image_url'] ??
            userData['photoUrl'] ??
            '';
        handle = userData['username_handle'] ?? '';
      }

      // Menyimpan data postingan beserta handle dinamis
      await _firestore.collection('posts').add({
        'uid': user.uid,
        'username': username,
        'username_handle': handle,
        'profile_image': profilePic,
        'content': _postController.text.trim(),
        'image_urls': imageUrls,
        'timestamp': FieldValue.serverTimestamp(),
        'likes': [],
        'comment_count': 0,
      });

      _postController.clear();
      setState(() {
        _selectedImages.clear();
        _forumRefreshKey = DateTime.now().millisecondsSinceEpoch.toString();
        _isPosting = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thread berhasil dibagikan!')),
        );
      }
    } catch (e) {
      debugPrint("Error creating post: $e");
      if (mounted) {
        setState(() => _isPosting = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal mengirim postingan: $e')));
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
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Hapus', style: TextStyle(color: Colors.red)),
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
          debugPrint("Gagal hapus image: $e");
        }
      }
      await _firestore.collection('posts').doc(postId).delete();
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal: $e')));
    }
  }

  Future<void> _pickImage() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage();
      if (images.isNotEmpty) {
        int total = _selectedImages.length + images.length;
        if (total > 5) {
          int sisa = 5 - _selectedImages.length;
          if (sisa > 0)
            setState(() => _selectedImages.addAll(images.take(sisa)));
          if (mounted)
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Maksimal 5 foto!')));
        } else {
          setState(() => _selectedImages.addAll(images));
        }
      }
    } catch (e) {
      debugPrint("Gagal ambil foto: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _auth.currentUser;
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: SafeArea(
          child: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              SliverAppBar(
                title: const Text(
                  "MacroFit Community",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                pinned: true,
                floating: true,
                bottom: TabBar(
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
                child: StreamBuilder<DocumentSnapshot>(
                  stream: _firestore
                      .collection('users')
                      .doc(currentUser?.uid)
                      .snapshots(),
                  builder: (context, userSnapshot) {
                    String avatar =
                        (userSnapshot.hasData && userSnapshot.data!.exists)
                        ? (userSnapshot.data!.data()
                                  as Map)['profile_picture'] ??
                              ''
                        : '';
                    return PostInputSection(
                      controller: _postController,
                      selectedImages: _selectedImages,
                      currentUserImageUrl: avatar,
                      onPickImage: _pickImage,
                      isPosting: _isPosting,
                      onCreatePost: _createPost,
                      onClearImage: () =>
                          setState(() => _selectedImages.clear()),
                      onRemoveSpecificImage: (i) =>
                          setState(() => _selectedImages.removeAt(i)),
                    );
                  },
                ),
              ),
            ],
            body: TabBarView(
              children: [
                PostListStream(
                  key: ValueKey('all_$_forumRefreshKey'),
                  filterUid: null,
                  firestore: _firestore,
                  auth: _auth,
                  onDeletePost: _deletePost,
                  onLikeToggle: _toggleLike,
                ),
                PostListStream(
                  key: ValueKey('my_${currentUser?.uid}_$_forumRefreshKey'),
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
