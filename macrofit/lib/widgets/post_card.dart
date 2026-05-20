import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../pages/comment_page.dart';

class PostCard extends StatelessWidget {
  final String postId;
  final String username;
  final String content;
  // 🔥 PERBAIKAN STRUCTURAL: Ubah String tunggal menjadi List untuk menampung multi-image URL
  final List<dynamic>? imageUrls;
  final String? profileImage;
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
    required this.imageUrls, // 🔥 Diubah menerima list array dari database
    this.profileImage,
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
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDarkMode ? Colors.white10 : Colors.black.withOpacity(0.03),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER SECTION: Avatar, Nama, Timestamp & Tombol Delete
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: theme.primaryColor.withOpacity(0.15),
                      backgroundImage:
                          (profileImage != null && profileImage!.isNotEmpty)
                          ? NetworkImage(profileImage!)
                          : null,
                      child: (profileImage == null || profileImage!.isEmpty)
                          ? Icon(
                              Icons.person,
                              size: 18,
                              color: theme.primaryColor,
                            )
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      username,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      _formatTimestamp(timestamp),
                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                    if (isOwner)
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
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
            const SizedBox(height: 12),

            // CONTENT TEXT SECTION
            Text(
              content,
              style: TextStyle(
                fontSize: 15,
                color: isDarkMode ? Colors.white : Colors.black87,
                height: 1.3,
              ),
            ),

            // 🔥 MULTI-IMAGE CAROUSEL SECTION (Menggunakan PageView Horizontal)
            if (imageUrls != null && imageUrls!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: SizedBox(
                  height: 230, // Tinggi area postingan foto
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: PageView.builder(
                      itemCount: imageUrls!.length,
                      physics: const BouncingScrollPhysics(),
                      itemBuilder: (context, index) {
                        return Stack(
                          children: [
                            Image.network(
                              imageUrls![index].toString(),
                              height: 230,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return const Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    );
                                  },
                            ),
                            // Indikator angka foto di pojok kanan atas jika foto lebih dari 1 (Contoh: 1/3)
                            if (imageUrls!.length > 1)
                              Positioned(
                                top: 12,
                                right: 12,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.65),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    "${index + 1}/${imageUrls!.length}",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 12),

            const Divider(height: 1),
            const SizedBox(height: 4),

            // BUTTON ACTION SECTION: Like & Comment Counters
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
                    Text(
                      '${likes.length}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 24),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.chat_bubble_outline,
                        color: Colors.grey,
                        size: 22,
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
                    Text(
                      '$commentCount',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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
