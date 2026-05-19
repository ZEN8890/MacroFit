import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../pages/comment_page.dart';

class PostCard extends StatelessWidget {
  final String postId;
  final String username;
  final String content;
  final String? imageUrl;
  final List<dynamic> likes;
  final int commentCount;
  final bool isLiked;
  final String postUid;
  final Timestamp? timestamp;
  final bool isOwner;
  final VoidCallback onDelete;
  final VoidCallback onLikeToggle;

  const PostCard({
    super.key,
    required this.postId,
    required this.username,
    required this.content,
    required this.imageUrl,
    required this.likes,
    required this.commentCount,
    required this.isLiked,
    required this.postUid,
    required this.timestamp,
    required this.isOwner,
    required this.onDelete,
    required this.onLikeToggle,
  });

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'Baru saja';
    DateTime postDate = timestamp.toDate();
    DateTime nowDate = DateTime.now();
    Duration difference = nowDate.difference(postDate);

    if (difference.inSeconds < 60) return 'Baru saja';
    if (difference.inMinutes < 60)
      return '${difference.inMinutes} menit yang lalu';
    if (difference.inHours < 24) return '${difference.inHours} jam yang lalu';
    return '${postDate.day}/${postDate.month}/${postDate.year}';
  }

  @override
  Widget build(BuildContext context) {
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
                      _formatTimestamp(timestamp),
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    if (isOwner)
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.redAccent,
                          size: 18,
                        ),
                        onPressed: onDelete,
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(content, style: const TextStyle(fontSize: 15)),
            if (imageUrl != null && imageUrl!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 10.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    imageUrl!,
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
                      onPressed: onLikeToggle,
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
}
