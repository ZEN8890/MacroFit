import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CreatorPostsTab extends StatelessWidget {
  final String targetUserId;
  final bool englishActive;

  const CreatorPostsTab({
    super.key,
    required this.targetUserId,
    required this.englishActive,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

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
            final pData = postDocs[index].data() as Map<String, dynamic>;

            String contentText = pData['content'] ?? '';
            List<dynamic> likesArray = pData['likes'] ?? [];
            int likeCount = likesArray.length;
            int commentCount = pData['comment_count'] ?? 0;

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
              final List<String> activeMonths = englishActive
                  ? monthsEN
                  : monthsID;

              final String minutes = dt.minute < 10
                  ? '0${dt.minute}'
                  : '${dt.minute}';
              timeDisplay =
                  '${dt.day} ${activeMonths[dt.month - 1]} ${dt.year}, ${dt.hour}:$minutes';
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

                    // 🟢 FIX EROR 1 (Baris 189): Menggunakan parameter padding luar & height bawaan Divider yang sah
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 4.0),
                      child: Divider(height: 10, thickness: 0.5),
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

                    // 🟢 FIX EROR 2 (Baris 196): Menggunakan parameter 'height' dan dibatasi lebar Box agar aman
                    if (postImageUrl.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0, bottom: 12.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            postImageUrl,
                            height:
                                200, // Mengubah maxHeight menjadi height standar pembatas objek gambarnya
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
                        Icon(
                          Icons.favorite_rounded,
                          size: 15,
                          color: likeCount > 0
                              ? Colors.redAccent
                              : Colors.grey.shade400,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "$likeCount",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(
                          Icons.mode_comment_outlined,
                          size: 14,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 4),
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
