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
      // 🔥 PERBAIKAN: Tambahkan includeMetadataChanges agar data pending timestamp langsung dirender
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
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final post = posts[index];
            final postData = post.data() as Map<String, dynamic>;
            final postId = post.id;

            String username = postData['username'] ?? 'Anonymous';
            String content = postData['content'] ?? '';
            List<dynamic> likes = postData['likes'] ?? [];
            int commentCount = postData['comment_count'] ?? 0;
            String? imageUrl = postData['image_url'];
            String postUid = postData['uid'] ?? '';

            bool isLiked = auth.currentUser != null
                ? likes.contains(auth.currentUser!.uid)
                : false;
            bool isOwner =
                auth.currentUser != null && postUid == auth.currentUser!.uid;

            return PostCard(
              postId: postId,
              username: username,
              content: content,
              imageUrl: imageUrl,
              likes: likes,
              commentCount: commentCount,
              isLiked: isLiked,
              postUid: postUid,
              timestamp: postData['timestamp'] as Timestamp?,
              isOwner: isOwner,
              onDelete: () => onDeletePost(postId, imageUrl),
              onLikeToggle: () => onLikeToggle(postId, likes),
            );
          },
        );
      },
    );
  }
}
