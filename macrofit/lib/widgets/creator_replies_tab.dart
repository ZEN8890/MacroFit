import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CreatorRepliesTab extends StatelessWidget {
  final String targetUserId;
  final bool englishActive;

  const CreatorRepliesTab({
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
          .collection('user_comments_history')
          .where('userId', isEqualTo: targetUserId)
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, historySnapshot) {
        if (historySnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!historySnapshot.hasData || historySnapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              englishActive
                  ? 'This creator hasn\'t written any reviews or comments yet.'
                  : 'Kreator ini belum pernah menulis ulasan atau komentar.',
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
          );
        }

        final historyDocs = historySnapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: historyDocs.length,
          itemBuilder: (context, index) {
            final hData = historyDocs[index].data() as Map<String, dynamic>;
            int reviewRating = hData['rating'] ?? 5;
            String recipeTitle =
                hData['recipeTitle'] ?? (englishActive ? 'Recipe' : 'Resep');

            String timeDisplay = '...';
            if (hData['timestamp'] != null) {
              final Timestamp ts = hData['timestamp'] as Timestamp;
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
              margin: const EdgeInsets.symmetric(vertical: 6),
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
                        Expanded(
                          child: Row(
                            children: [
                              const Icon(
                                Icons.reply_rounded,
                                color: Colors.grey,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  englishActive
                                      ? 'Reviewed in "$recipeTitle"'
                                      : 'Mengulas di "$recipeTitle"',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: theme.primaryColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: List.generate(5, (starIndex) {
                            return Icon(
                              starIndex < reviewRating
                                  ? Icons.star
                                  : Icons.star_border,
                              color: Colors.amber,
                              size: 13,
                            );
                          }),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      hData['commentText'] ?? '',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Text(
                        timeDisplay,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
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
