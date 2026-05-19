import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Fungsi untuk mengirim komentar baru ke dalam sub-koleksi post
  Future<void> _submitComment() async {
    if (_commentController.text.trim().isEmpty) return;

    final user = _auth.currentUser;
    if (user == null) return;

    try {
      // Mengambil nama user yang sedang berkomentar
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      String username = userDoc.exists
          ? (userDoc.data()?['username'] ?? 'Anonymous')
          : 'Anonymous';

      final postRef = _firestore.collection('posts').doc(widget.postId);

      // 1. Tambahkan komentar ke sub-koleksi 'comments' di dalam postingan terkait
      await postRef.collection('comments').add({
        'uid': user.uid,
        'username': username,
        'content': _commentController.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
      });

      // 2. Update jumlah comment_count di dokumen utama postingan (+1)
      await postRef.update({'comment_count': FieldValue.increment(1)});

      _commentController.clear();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal mengirim komentar: $e')));
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 1. Memastikan Scaffold otomatis menggeser konten saat keyboard muncul
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text(
          "Thread Replies",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          // 1. Tampilan Postingan Asli (Header)
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Theme.of(context).colorScheme.surfaceContainerLowest,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.teal,
                      child: Icon(Icons.person, size: 18, color: Colors.white),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      widget.postUsername,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(widget.postContent, style: const TextStyle(fontSize: 16)),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1),

          // 2. Daftar Komentar (Real-time Stream - SUDAH DIPERBAIKI)
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('posts')
                  .doc(widget.postId)
                  .collection('comments')
                  .orderBy('timestamp', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      "Belum ada komentar.\nMari mulai obrolan sehat!",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                final comments = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final commentData =
                        comments[index].data() as Map<String, dynamic>;
                    String commenterName = commentData['username'] ?? 'User';
                    String commentContent = commentData['content'] ?? '';

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const CircleAvatar(
                            radius: 14,
                            backgroundColor: Colors.grey,
                            child: Icon(
                              Icons.person,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  commenterName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  commentContent,
                                  style: const TextStyle(fontSize: 14),
                                ),

                                // ========================================================
                                // 🔥 TAMBAHAN BARU: TAMPILKAN GAMBAR REPLIES JIKA ADA
                                // ========================================================
                                if (commentData['image_url'] != null &&
                                    commentData['image_url']
                                        .toString()
                                        .isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: Image.network(
                                        commentData['image_url'],
                                        height:
                                            140, // Tinggi disesuaikan lebih kecil agar pas untuk area komentar
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                        // Loading indicator saat gambar diunduh
                                        loadingBuilder:
                                            (context, child, loadingProgress) {
                                              if (loadingProgress == null)
                                                return child;
                                              return Container(
                                                height: 100,
                                                color: Colors.grey[200],
                                                child: const Center(
                                                  child:
                                                      CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                      ),
                                                ),
                                              );
                                            },
                                        // Menghindari crash layar merah jika tautan bermasalah
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                              return Container(
                                                padding: const EdgeInsets.all(
                                                  6,
                                                ),
                                                color: Colors.grey[100],
                                                child: const Row(
                                                  children: [
                                                    Icon(
                                                      Icons
                                                          .broken_image_outlined,
                                                      color: Colors.grey,
                                                      size: 16,
                                                    ),
                                                    SizedBox(width: 6),
                                                    Text(
                                                      "Gagal memuat gambar",
                                                      style: TextStyle(
                                                        color: Colors.grey,
                                                        fontSize: 11,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const Divider(height: 1),

          // 3. Kolom Input Komentar (Bagian Bawah - SUDAH DIPERBAIKI)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(
                left: 12,
                right: 12,
                top: 8,
                bottom:
                    12, // PERBAIKAN: Cukup gunakan padding statis karena Scaffold yang akan menghandle inset keyboard
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      decoration: const InputDecoration(
                        hintText: "Tulis balasan Anda...",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(24)),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      maxLines: null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send, color: Colors.teal),
                    onPressed: _submitComment,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
