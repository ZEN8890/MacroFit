import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../services/storage_services.dart';
import '../widgets/post_input_section.dart';
import '../widgets/post_list_stream.dart';
import '../utils/notification_helper.dart';
import '../utils/global_state.dart';

class ForumPage extends StatefulWidget {
  const ForumPage({super.key});

  @override
  State<ForumPage> createState() => _ForumPageState();
}

class _ForumPageState extends State<ForumPage> {
  final TextEditingController _postController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final List<XFile> _selectedImages = [];
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

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data();

      String fullName = 'User MacroFit';
      String profilePic = '';
      String username = '';

      if (userDoc.exists && userData != null) {
        fullName =
            userData['full_name'] ?? userData['displayName'] ?? 'User MacroFit';
        profilePic =
            userData['profile_picture'] ??
            userData['profile_image_url'] ??
            userData['photoUrl'] ??
            '';
        username = userData['username'] ?? '';
      }

      await _firestore.collection('posts').add({
        'uid': user.uid,
        'full_name': fullName,
        'username': username,
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
        Notify.success(
          context,
          isEnglishNotifier.value
              ? 'Thread shared successfully!'
              : 'Thread berhasil dibagikan!',
        );
      }
    } catch (e) {
      debugPrint("Error creating post: $e");
      if (mounted) {
        setState(() => _isPosting = false);
        Notify.error(
          context,
          isEnglishNotifier.value
              ? 'Failed to create post: $e'
              : 'Gagal mengirim postingan: $e',
        );
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
    final bool currentLangEn = isEnglishNotifier.value;

    bool confirmDelete =
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              currentLangEn ? 'Delete Thread' : 'Hapus Thread',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            content: Text(
              currentLangEn
                  ? 'Are you sure you want to delete this thread?'
                  : 'Apakah Anda yakin ingin menghapus thread ini?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(currentLangEn ? 'Cancel' : 'Batal'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  currentLangEn ? 'Delete' : 'Hapus',
                  style: const TextStyle(color: Colors.red),
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
          debugPrint("Gagal hapus image: $e");
        }
      }
      await _firestore.collection('posts').doc(postId).delete();
      if (mounted) {
        Notify.success(
          context,
          currentLangEn
              ? "Thread deleted successfully"
              : "Thread berhasil dihapus",
        );
      }
    } catch (e) {
      if (mounted) {
        Notify.error(
          context,
          currentLangEn ? 'Failed to delete thread: $e' : 'Gagal menghapus: $e',
        );
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage();
      if (images.isNotEmpty) {
        int total = _selectedImages.length + images.length;
        if (total > 5) {
          int sisa = 5 - _selectedImages.length;
          if (sisa > 0) {
            setState(() => _selectedImages.addAll(images.take(sisa)));
          }
          if (mounted) {
            Notify.error(
              context,
              isEnglishNotifier.value
                  ? 'Maximum 5 photos!'
                  : 'Maksimal 5 foto!',
            );
          }
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

    return ValueListenableBuilder<bool>(
      valueListenable: isEnglishNotifier,
      builder: (context, englishActive, child) {
        return DefaultTabController(
          length: 2,
          child: Scaffold(
            resizeToAvoidBottomInset: true,
            body: SafeArea(
              child: Column(
                children: [
                  Material(
                    child: ListTile(
                      title: Text(
                        englishActive
                            ? "MacroFit Community"
                            : "Komunitas MacroFit",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  TabBar(
                    tabs: [
                      Tab(
                        text: englishActive ? 'All Forums' : 'Semua Forum',
                        icon: const Icon(Icons.forum_outlined, size: 20),
                      ),
                      Tab(
                        text: englishActive ? 'My Threads' : 'Thread Saya',
                        icon: const Icon(
                          Icons.assignment_ind_outlined,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                  StreamBuilder<DocumentSnapshot>(
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
                  Expanded(
                    child: TabBarView(
                      children: [
                        RefreshIndicator(
                          color: Theme.of(context).primaryColor,
                          onRefresh: () async {
                            setState(() {
                              _forumRefreshKey = DateTime.now()
                                  .millisecondsSinceEpoch
                                  .toString();
                            });
                          },
                          child: PostListStream(
                            key: ValueKey('all_$_forumRefreshKey'),
                            filterUid: null,
                            firestore: _firestore,
                            auth: _auth,
                            onDeletePost: _deletePost,
                            onLikeToggle: _toggleLike,
                          ),
                        ),

                        RefreshIndicator(
                          color: Theme.of(context).primaryColor,
                          onRefresh: () async {
                            setState(() {
                              _forumRefreshKey = DateTime.now()
                                  .millisecondsSinceEpoch
                                  .toString();
                            });
                          },
                          child: PostListStream(
                            key: ValueKey(
                              'my_${currentUser?.uid}_$_forumRefreshKey',
                            ),
                            filterUid: currentUser?.uid,
                            firestore: _firestore,
                            auth: _auth,
                            onDeletePost: _deletePost,
                            onLikeToggle: _toggleLike,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
