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
  bool _isPosting = false; // 🔥 Variabel penanda status loading postingan

  Future<void> _createPost() async {
    if (_postController.text.trim().isEmpty && _selectedImage == null) return;
    final user = _auth.currentUser;
    if (user == null) return;

    // 🔥 Mulai Loading Animasi
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal mengirim postingan: $e')));
    } finally {
      // 🔥 Matikan Loading Animasi (Baik sukses maupun gagal)
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
            title: const Text('Hapus Thread'),
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
          debugPrint("Gagal hapus image di storage: $e");
        }
      }
      await _firestore.collection('posts').doc(postId).delete();
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thread berhasil dihapus.')),
        );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal menghapus thread: $e')));
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
        // 🔥 PERBAIKAN 1: Memaksa Scaffold mengatur ulang layout saat keyboard muncul
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          title: const Text(
            "MacroFit Community",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          elevation: 0,
          // 🔥 OTOMATIS: Mengikuti warna backgroundLight (Putih) atau backgroundDark (Abu Gelap) dari tema Anda
          backgroundColor: theme.appBarTheme.backgroundColor,
          foregroundColor: theme.appBarTheme.foregroundColor,
          bottom: TabBar(
            // 🔥 MENYESUAIKAN TEMA: Teks aktif berwarna Biru Utama (Light) atau Putih Bersih (Dark)
            labelColor: isDarkMode ? Colors.white : theme.primaryColor,
            // Teks tidak aktif berwarna abu-abu proporsional
            unselectedLabelColor: isDarkMode ? Colors.white38 : Colors.black38,
            // 🔥 INDIKATOR: Menggunakan warna Biru Utama aplikasi Anda (primaryBlue)
            indicatorColor: theme.primaryColor,
            indicatorSize: TabBarIndicatorSize.tab,
            tabs: const [
              Tab(text: 'Semua Forum', icon: Icon(Icons.forum_outlined)),
              Tab(
                text: 'Thread Saya',
                icon: Icon(Icons.assignment_ind_outlined),
              ),
            ],
          ),
        ),
        // Menambahkan warna background scaffold agar sinkron dengan tema modular
        backgroundColor: theme.scaffoldBackgroundColor,
        // 🔥 PERBAIKAN MUTLAK: Mengubah struktur utama body agar memiliki toleransi scroll mikro
        body: ListView(
          shrinkWrap: true,
          physics:
              const ClampingScrollPhysics(), // Menjaga agar tidak ada efek membal yang memotong tab
          children: [
            PostInputSection(
              controller: _postController,
              selectedImage: _selectedImage,
              onPickImage: _pickImage,
              isPosting: _isPosting,
              onCreatePost: _createPost,
              onClearImage: () => setState(() => _selectedImage = null),
            ),

            const Divider(thickness: 1, height: 1),

            // 🔥 Gunakan SizedBox pembatas agar TabBarView mendapatkan tinggi maksimum yang aman
            SizedBox(
              height:
                  MediaQuery.of(context).size.height -
                  kToolbarHeight -
                  kTextTabBarHeight -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).viewInsets.bottom -
                  120, // Menghitung ruang sisa keyboard secara dinamis
              child: TabBarView(
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
          ],
        ),
      ),
    );
  }
}
