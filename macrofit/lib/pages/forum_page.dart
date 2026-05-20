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
  List<XFile> _selectedImages = []; // Array list penampung banyak foto
  final ImagePicker _picker = ImagePicker();
  final StorageService _storageService = StorageService();
  bool _isPosting = false;

  Future<void> _pickMultiImages() async {
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(images);
      });
    }
  }

  Future<void> _createPost() async {
    if (_postController.text.trim().isEmpty && _selectedImages.isEmpty) return;
    final user = _auth.currentUser;
    if (user == null) return;

    setState(() => _isPosting = true);

    try {
      // Proses upload paralel multiple images ke Firebase Storage
      List<String> imageUrls = [];
      if (_selectedImages.isNotEmpty) {
        imageUrls = await Future.wait(
          _selectedImages.map(
            (image) => _storageService.uploadImage(image, 'posts'),
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

      await _firestore.collection('posts').add({
        'uid': user.uid,
        'username': username,
        'profile_image': profilePic,
        'content': _postController.text.trim(),
        'image_urls': imageUrls, // Menyimpan array string URL foto
        'timestamp': FieldValue.serverTimestamp(),
        'likes': [],
        'comment_count': 0,
      });

      _postController.clear();
      setState(() => _selectedImages.clear());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thread foto berhasil dibagikan!')),
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

  // 🔥 PERBAIKAN FUNGSIONAL: Ubah Single Picker Menjadi Multi Picker dengan Batas Maksimal 5 Foto
  Future<void> _pickImage() async {
    try {
      // 1. Panggil pickMultiImage untuk mengizinkan user menyeleksi banyak foto sekaligus di galeri
      final List<XFile> images = await _picker.pickMultiImage();

      if (images.isNotEmpty) {
        // Hitung total kombinasi foto yang sudah ada + foto yang baru dipilih
        int totalImagesNow = _selectedImages.length + images.length;

        if (totalImagesNow > 5) {
          // Jika melampaui limit, hitung berapa slot sisa yang masih tersedia
          int sisaSlot = 5 - _selectedImages.length;

          if (sisaSlot > 0) {
            // Ambil foto baru hanya sebanyak sisa slot yang tersedia
            setState(() {
              _selectedImages.addAll(images.take(sisaSlot));
            });
          }

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  '⚠️ Batas maksimal adalah 5 foto! Foto selebihnya otomatis diabaikan.',
                ),
                backgroundColor: Colors.amber,
                duration: Duration(seconds: 3),
              ),
            );
          }
        } else {
          // Jika totalnya masih di bawah atau pas 5 foto, masukkan semua tanpa potongan
          setState(() {
            _selectedImages.addAll(images);
          });
        }
      }
    } catch (e) {
      debugPrint("Gagal mengambil banyak foto: $e");
    }
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
            headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
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
                  // 🌟 SOLUSI UTAMA 1: Tambahkan toolbarHeight dan tentukan space yang cukup
                  // agar ketika appBar menciut/pinned, dia tidak mencekik tab bar di bawahnya.
                  toolbarHeight: 56.0,

                  // 🌟 SOLUSI UTAMA 2: Ubah dari 48 menjadi 74 mengikuti tinggi asli Tab + Icon
                  bottom: PreferredSize(
                    preferredSize: const Size.fromHeight(74.0),
                    child: Material(
                      color:
                          theme.appBarTheme.backgroundColor ??
                          theme.scaffoldBackgroundColor,
                      child: TabBar(
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
                  ),
                ),
                SliverToBoxAdapter(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Gunakan StreamBuilder/FutureBuilder ringan jika ingin realtime, atau baca langsung data profile yang sudah ada
                      StreamBuilder<DocumentSnapshot>(
                        stream: _firestore
                            .collection('users')
                            .doc(currentUser?.uid)
                            .snapshots(),
                        builder: (context, userSnapshot) {
                          String userAvatarUrl = '';
                          if (userSnapshot.hasData &&
                              userSnapshot.data!.exists) {
                            final userData =
                                userSnapshot.data!.data()
                                    as Map<String, dynamic>?;
                            userAvatarUrl =
                                userData?['profile_picture'] ??
                                userData?['profile_image_url'] ??
                                userData?['photoUrl'] ??
                                '';
                          }

                          return PostInputSection(
                            controller: _postController,
                            // 🔥 1. PREVIEW MULTI-IMAGE: Oper seluruh list agar bisa dirender menyamping
                            selectedImages: _selectedImages,
                            // 🔥 2. FOTO PROFIL AKTIF: Berikan URL foto profil user saat ini
                            currentUserImageUrl: userAvatarUrl,
                            onPickImage: _pickImage,
                            isPosting: _isPosting,
                            onCreatePost: _createPost,
                            onClearImage: () =>
                                setState(() => _selectedImages.clear()),
                            // Fungsi hapus satu foto tertentu di baris preview
                            onRemoveSpecificImage: (index) {
                              setState(() {
                                _selectedImages.removeAt(index);
                              });
                            },
                          );
                        },
                      ),
                      const Divider(thickness: 1, height: 1),
                    ],
                  ),
                ),
              ];
            },
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
