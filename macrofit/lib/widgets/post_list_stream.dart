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

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 80),
          shrinkWrap: false,
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final doc = posts[index];
            final data = doc.data() as Map<String, dynamic>;

            // JEMBATAN KONVERSI DATA IMAGE MULTI-URL (Aman dari data lawas/baru)
            final List<dynamic> currentImageUrls = data['image_urls'] is List
                ? data['image_urls']
                : (data['image_url'] != null &&
                          data['image_url'].toString().isNotEmpty
                      ? [data['image_url']]
                      : []);

            final String postUid = data['uid'] ?? '';

            // 🟢 LOGIKA DYNAMIC HANDLE:
            // Mengambil handle langsung dari Firestore tanpa hardcoding UID.
            // Jika tidak ada handle, kita buat dari nama lengkap.
            final String rawHandle =
                data['username_handle']?.toString().trim() ?? '';
            final String fullName =
                data['username']?.toString().trim() ?? 'User MacroFit';

            final String displayName = rawHandle.isNotEmpty
                ? '@${rawHandle.toLowerCase()}'
                : '@user';

            return PostCard(
              postId: doc.id,
              username: displayName,
              content: data['content'] ?? '',
              imageUrls: currentImageUrls,
              profileImage: data['profile_image'] ?? '',
              likes: data['likes'] ?? [],
              commentCount: data['comment_count'] ?? 0,
              isLiked: (data['likes'] ?? []).contains(auth.currentUser?.uid),
              postUid: postUid,
              timestamp: data['timestamp'] as Timestamp?,
              isOwner: postUid == auth.currentUser?.uid,
              onDelete: () => onDeletePost(doc.id, data['image_url']),
              onLikeToggle: () => onLikeToggle(doc.id, data['likes'] ?? []),
            );
          },
        );
      },
    );
  }
}
