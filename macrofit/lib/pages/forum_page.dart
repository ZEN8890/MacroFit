import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/storage_services.dart';
import 'comment_page.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ForumPage extends StatefulWidget {
  const ForumPage({super.key});

  @override
  State<ForumPage> createState() => _ForumPageState();
}

class _ForumPageState extends State<ForumPage> {
  final TextEditingController _postController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  XFile? _selectedImage; // Menyimpan file foto yang dipilih user sementara
  final ImagePicker _picker = ImagePicker();
  final StorageService _storageService = StorageService();

  // Fungsi untuk mengirim postingan (Thread) baru ke Firestore
  Future<void> _createPost() async {
    if (_postController.text.trim().isEmpty && _selectedImage == null) return;

    final user = _auth.currentUser;
    if (user == null) return;

    try {
      String imageUrl = '';

      // Jika user memilih gambar, upload ke Storage terlebih dahulu
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
        'image_url': imageUrl, // MENYIMPAN LINK FOTO
        'timestamp': FieldValue.serverTimestamp(),
        'likes': [],
        'comment_count': 0,
      });

      _postController.clear();
      setState(() {
        _selectedImage = null; // Reset foto setelah berhasil dikirim
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thread berhasil dibagikan!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal mengirim postingan: $e')));
    }
  }

  // Fungsi untuk handle Like / Unlike ala Threads (SUDAH DIPERBAIKI)
  Future<void> _toggleLike(String postId, List<dynamic> likes) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final postRef = _firestore.collection('posts').doc(postId);

    try {
      if (likes.contains(user.uid)) {
        // Jika sudah di-like, hapus dari list (Unlike)
        await postRef.update({
          'likes': FieldValue.arrayRemove([user.uid]),
        });
      } else {
        // Jika belum di-like, tambahkan ke list (Like)
        await postRef.update({
          'likes': FieldValue.arrayUnion([user.uid]),
        });
      }
    } catch (e) {
      print("Error toggling like: $e");
    }
  }

  // Fungsi pembantu untuk memformat waktu postingan ala sosial media
  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'Baru saja';

    DateTime postDate = timestamp.toDate();
    DateTime nowDate = DateTime.now();
    Duration difference = nowDate.difference(postDate);

    if (difference.inSeconds < 60) {
      return 'Baru saja';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} menit yang lalu';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} jam yang lalu';
    } else {
      return '${postDate.day}/${postDate.month}/${postDate.year}';
    }
  }

  //Fungsi untuk memilih gambar dari galeri
  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = image;
      });
    }
  }

  // 🔥 FUNGSI BARU: Menghapus Thread dari Firestore & Gambar dari Storage
  Future<void> _deletePost(String postId, String? imageUrl) async {
    // Tampilkan dialog konfirmasi terlebih dahulu agar aman
    bool confirmDelete =
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Hapus Thread'),
            content: const Text(
              'Apakah Anda yakin ingin menghapus thread ini? Tindakan ini tidak dapat dibatalkan.',
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
      // 1. Jika postingan memiliki gambar, hapus file gambarnya dulu di Firebase Storage
      if (imageUrl != null && imageUrl.isNotEmpty) {
        try {
          await FirebaseStorage.instance.refFromURL(imageUrl).delete();
        } catch (storageError) {
          // Tetap lanjutkan hapus dokumen jika gambar gagal dihapus (misal file sudah hilang di server)
          debugPrint("Gagal menghapus file di Storage: $storageError");
        }
      }

      // 2. Hapus dokumen utama postingan di Cloud Firestore
      await _firestore.collection('posts').doc(postId).delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thread berhasil dihapus.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal menghapus thread: $e')));
    }
  }

  // 🔥 WIDGET HELPER 1: Wadah Komponen Input Pembuatan Thread Baru
  Widget _buildPostInputSection() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: [
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: Colors.grey,
                child: Icon(Icons.person, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _postController,
                  decoration: const InputDecoration(
                    hintText: "Bagikan progres diet atau menumu...",
                    border: InputBorder.none,
                  ),
                  maxLines: null,
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.image_outlined,
                  color: _selectedImage != null ? Colors.teal : Colors.grey,
                ),
                onPressed: _pickImage,
              ),
              IconButton(
                icon: const Icon(Icons.send, color: Colors.teal),
                onPressed: _createPost,
              ),
            ],
          ),
          if (_selectedImage != null)
            Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: Stack(
                alignment: Alignment.topRight,
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        File(_selectedImage!.path),
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedImage = null),
                      child: const CircleAvatar(
                        radius: 14,
                        backgroundColor: Colors.black54,
                        child: Icon(Icons.close, color: Colors.white, size: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // Helper Widget untuk memuat data list secara kondisional
  Widget _buildPostListStream(String? filterUid) {
    Query query = _firestore
        .collection('posts')
        .orderBy('timestamp', descending: true);
    if (filterUid != null) {
      query = query.where('uid', isEqualTo: filterUid);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              filterUid == null
                  ? 'Belum ada diskusi di forum ini.'
                  : 'Anda belum membuat thread apa pun.',
              style: const TextStyle(color: Colors.grey),
            ),
          );
        }

        final posts = snapshot.data!.docs;

        return ListView.builder(
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final postData = posts[index].data() as Map<String, dynamic>;
            final postId = posts[index].id;

            String username = postData['username'] ?? 'Anonymous';
            String content = postData['content'] ?? '';
            List likes = postData['likes'] ?? [];
            int commentCount = postData['comment_count'] ?? 0;
            String? imageUrl = postData['image_url'];
            String postUid = postData['uid'] ?? '';

            bool isLiked = _auth.currentUser != null
                ? likes.contains(_auth.currentUser!.uid)
                : false;

            return _buildPostCard(
              postId,
              username,
              content,
              imageUrl,
              likes,
              commentCount,
              isLiked,
              postData,
              postUid,
            );
          },
        );
      },
    );
  }

  Widget _buildPostCard(
    String postId,
    String username,
    String content,
    String? imageUrl,
    List likes,
    int commentCount,
    bool isLiked,
    Map<String, dynamic> postData,
    String postUid,
  ) {
    final currentUser = _auth.currentUser;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.teal,
                      child: Icon(Icons.person, size: 20, color: Colors.white),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      username,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      _formatTimestamp(postData['timestamp'] as Timestamp?),
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    if (currentUser != null && postUid == currentUser.uid)
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.redAccent,
                          size: 18,
                        ),
                        onPressed: () => _deletePost(postId, imageUrl),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(content, style: const TextStyle(fontSize: 15)),

            if (imageUrl != null && imageUrl.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 10.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    imageUrl,
                    height: 220,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            const SizedBox(height: 12),

            Row(
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        isLiked ? Icons.favorite : Icons.favorite_border,
                        color: isLiked ? Colors.red : Colors.grey,
                      ),
                      onPressed: () => _toggleLike(postId, likes),
                    ),
                    Text('${likes.length}'),
                  ],
                ),
                const SizedBox(width: 20),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.chat_bubble_outline,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CommentPage(
                              postId: postId,
                              postUsername: username,
                              postContent: content,
                            ),
                          ),
                        );
                      },
                    ),
                    Text('$commentCount'),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _postController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _auth.currentUser;

    return DefaultTabController(
      length: 2, // Membuka 2 halaman tab: Semua & Thread Saya
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            "MacroFit Community",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          elevation: 0,
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: 'Semua Forum', icon: Icon(Icons.forum_outlined)),
              Tab(
                text: 'Thread Saya',
                icon: Icon(Icons.assignment_ind_outlined),
              ),
            ],
          ),
        ),
        body: Column(
          children: [
            _buildPostInputSection(),

            const Divider(thickness: 1, height: 1),

            Expanded(
              child: TabBarView(
                children: [
                  _buildPostListStream(null),
                  _buildPostListStream(currentUser?.uid),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
