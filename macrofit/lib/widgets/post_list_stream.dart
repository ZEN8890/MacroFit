import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'post_card.dart';

class PostListStream extends StatelessWidget {
  final String? filterUid;
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;
  final Function(String, String?) onDeletePost;
  final Function(String, List<dynamic>) onLikeToggle;

  const PostListStream({
    super.key,
    required this.filterUid,
    required this.firestore,
    required this.auth,
    required this.onDeletePost,
    required this.onLikeToggle,
  });

  @override
  Widget build(BuildContext context) {
    Query query = firestore
        .collection('posts')
        .orderBy('timestamp', descending: true);
    if (filterUid != null) {
      query = query.where('uid', isEqualTo: filterUid);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(includeMetadataChanges: true),
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

        // === TIMPA BAGIAN ITEMBUILDER DI DALAM LISTVIEW.BUILDER POST_LIST_STREAM.DART ===
        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 80),
          shrinkWrap: true,
          physics:
              const NeverScrollableScrollPhysics(), // Mematikan scroll internal agar layout NestedScrollView lancar
          itemCount: posts.length,
          itemBuilder: (context, index) {
            // 🔥 1. DEKLARASIKAN VARIABEL UTAMA DI SINI TERLEBIH DAHULU
            final doc = posts[index];
            final data = doc.data() as Map<String, dynamic>;

            // 🔥 2. JEMBATAN KONVERSI DATA IMAGE MULTI-URL (Aman dari data lawas/baru)
            final List<dynamic> currentImageUrls = data['image_urls'] is List
                ? data['image_urls']
                : (data['image_url'] != null &&
                          data['image_url'].toString().isNotEmpty
                      ? [data['image_url']]
                      : []);

            // 🔥 3. KEMBALIKAN KOMPONEN POSTCARD YANG SUDAH TERHUBUNG SEMPURNA
            return PostCard(
              postId: doc.id,
              username: data['username'] ?? 'User MacroFit',
              content: data['content'] ?? '',
              imageUrls:
                  currentImageUrls, // Menggunakan variabel jembatan currentImageUrls
              profileImage: data['profile_image'] ?? '',
              likes: data['likes'] ?? [],
              commentCount: data['comment_count'] ?? 0,
              isLiked: (data['likes'] ?? []).contains(auth.currentUser?.uid),
              postUid: data['uid'] ?? '',
              timestamp: data['timestamp'] as Timestamp?,
              isOwner: (data['uid'] ?? '') == auth.currentUser?.uid,
              onDelete: () => onDeletePost(doc.id, data['image_url']),
              onLikeToggle: () => onLikeToggle(doc.id, data['likes'] ?? []),
            );
          },
        );
      },
    );
  }
}
