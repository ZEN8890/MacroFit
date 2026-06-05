import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../pages/comment_page.dart'; // 🟢 FIX IMPOR: Pastikan lokasi impor berkas CommentPage Anda sudah benar

class CreatorPostsTab extends StatelessWidget {
  final String targetUserId;
  final bool englishActive;

  const CreatorPostsTab({
    super.key,
    required this.targetUserId,
    required this.englishActive,
  });

  // Fungsi Toggle Like secara Interaktif langsung ke Firestore Array
  Future<void> _toggleLikePost(
    String postId,
    List<dynamic> currentLikes,
    String currentUid,
  ) async {
    final docRef = FirebaseFirestore.instance.collection('posts').doc(postId);
    try {
      if (currentLikes.contains(currentUid)) {
        await docRef.update({
          'likes': FieldValue.arrayRemove([currentUid]),
        });
      } else {
        await docRef.update({
          'likes': FieldValue.arrayUnion([currentUid]),
        });
      }
    } catch (e) {
      debugPrint("Gagal menjalankan interaksi like: $e");
    }
  }

  // 🟢 FIX UTAMA: Mengalihkan Lembar BottomSheet lama langsung ke CommentPage Asli Anda
  void _openCommentSection(
    BuildContext context,
    String postId,
    String postUsername,
    String postContent,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CommentPage(
          postId: postId,
          postUsername: postUsername,
          postContent: postContent,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final String currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .where('uid', isEqualTo: targetUserId)
          .snapshots(),
      builder: (context, postSnapshot) {
        if (postSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final postDocs = postSnapshot.data?.docs ?? [];

        if (postDocs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Text(
                englishActive
                    ? 'This creator hasn\'t shared any forum posts yet.'
                    : 'Kreator ini belum pernah membagikan kiriman di forum.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: postDocs.length,
          itemBuilder: (context, index) {
            final docId = postDocs[index].id;
            final pData = postDocs[index].data() as Map<String, dynamic>;

            String contentText = pData['content'] ?? '';
            String authorName =
                pData['username'] ??
                'User MacroFit'; // Mengambil nama pembuat forum
            List<dynamic> likesArray = pData['likes'] ?? [];
            int commentCount = pData['comment_count'] ?? 0;

            bool isLikedByMe = likesArray.contains(currentUid);

            List<dynamic> imageList = pData['image_urls'] ?? [];
            String postImageUrl = imageList.isNotEmpty
                ? imageList[0].toString()
                : '';

            String timeDisplay = '...';
            if (pData['timestamp'] != null) {
              final Timestamp ts = pData['timestamp'] as Timestamp;
              final DateTime dt = ts.toDate();
              final List<String> monthsID = [
                'Jan',
                'Feb',
                'Mar',
                'Apr',
                'Mei',
                'Jun',
                'Jul',
                'Agu',
                'Sep',
                'Okt',
                'Nov',
                'Des',
              ];
              final List<String> monthsEN = [
                'Jan',
                'Feb',
                'Mar',
                'Apr',
                'May',
                'Jun',
                'Jul',
                'Aug',
                'Sep',
                'Oct',
                'Nov',
                'Dec',
              ];
              timeDisplay =
                  '${dt.day} ${(englishActive ? monthsEN : monthsID)[dt.month - 1]} ${dt.year}';
            }

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              elevation: 0.5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isDarkMode
                      ? Colors.white10
                      : Colors.black.withOpacity(0.04),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.dynamic_feed_rounded,
                              color: theme.primaryColor,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              englishActive ? "Forum Update" : "Kiriman Forum",
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          timeDisplay,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Divider(
                        height: 10,
                        thickness: 0.5,
                        color: isDarkMode ? Colors.white10 : Colors.black12,
                      ),
                    ),
                    if (contentText.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text(
                          contentText,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.4,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                    if (postImageUrl.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 4.0,
                          horizontal: 8.0,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            postImageUrl,
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const SizedBox(),
                          ),
                        ),
                      ),
                    const SizedBox(height: 4),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // 1. TOMBOL LIKE INTERAKTIF
                        InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () =>
                              _toggleLikePost(docId, likesArray, currentUid),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8.0,
                              vertical: 4.0,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isLikedByMe
                                      ? Icons.favorite_rounded
                                      : Icons.favorite_border_rounded,
                                  size: 18,
                                  color: isLikedByMe
                                      ? Colors.redAccent
                                      : Colors.grey.shade500,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  "${likesArray.length}",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isLikedByMe
                                        ? Colors.redAccent
                                        : Colors.grey.shade600,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // 2. TOMBOL KOMENTAR SEKARANG LANGSUNG MEMBUKA COMMENTPAGE ANDA
                        InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () => _openCommentSection(
                            context,
                            docId,
                            authorName,
                            contentText,
                          ), // 🟢 Oper parameter secara lengkap
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8.0,
                              vertical: 4.0,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.mode_comment_outlined,
                                  size: 16,
                                  color: Colors.grey.shade500,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  "$commentCount",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
