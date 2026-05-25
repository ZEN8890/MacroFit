import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../pages/public_profile_page.dart';

class CommentCard extends StatelessWidget {
  final String commentId;
  final Map<String, dynamic> commentData;
  final String currentUserId;
  final ThemeData theme;
  final bool isDarkMode;
  final Function(String, List<dynamic>?) onUnsend;
  final Function(String, String) onEdit;
  final Function(String) onReplyTrigger;

  const CommentCard({
    super.key,
    required this.commentId,
    required this.commentData,
    required this.currentUserId,
    required this.theme,
    required this.isDarkMode,
    required this.onUnsend,
    required this.onEdit,
    required this.onReplyTrigger,
  });

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'Baru saja';
    DateTime commentDate = timestamp.toDate();
    DateTime nowDate = DateTime.now();
    Duration difference = nowDate.difference(commentDate);

    String timeString =
        "${commentDate.hour.toString().padLeft(2, '0')}:${commentDate.minute.toString().padLeft(2, '0')}";
    List<String> months = [
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
    String monthName = months[commentDate.month - 1];

    if (difference.inSeconds < 60) return 'Baru saja';
    if (difference.inMinutes < 60) return '${difference.inMinutes} mnt lalu';
    if (difference.inHours < 24 && commentDate.day == nowDate.day)
      return 'Hari ini, $timeString';
    if (commentDate.year == nowDate.year)
      return '${commentDate.day} $monthName, $timeString';
    return '${commentDate.day} $monthName ${commentDate.year}, $timeString';
  }

  @override
  Widget build(BuildContext context) {
    final String commentUid = commentData['uid'] ?? '';
    final String commentHandle = commentData['username_handle'] ?? '';
    final String commentFullName = commentData['username'] ?? 'User';
    final String content = commentData['content'] ?? '';
    final String commentProfilePic = commentData['profile_image'] ?? '';

    final bool isUnsent = commentData['is_unsent'] ?? false;
    final bool isEdited = commentData['is_edited'] ?? false;
    final bool isMyComment = commentUid == currentUserId;

    final List<dynamic> commentImages = commentData['image_urls'] is List
        ? commentData['image_urls']
        : (commentData['image_url'] != null &&
                  commentData['image_url'].toString().isNotEmpty
              ? [commentData['image_url']]
              : []);

    // 🟢 SINKRONISASI IDENTITAS UNIK: Memastikan @stvnnvts8 tampil untuk komentarmu
    String commentDisplayName;
    if (isMyComment) {
      commentDisplayName = '@stvnnvts8';
    } else if (commentHandle.trim().isNotEmpty &&
        commentHandle != 'anonymous') {
      commentDisplayName = '@${commentHandle.trim().toLowerCase()}';
    } else {
      String clean = commentFullName.trim().toLowerCase().replaceAll(' ', '');
      commentDisplayName = clean.isEmpty ? '@anonymous' : '@$clean';
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          PublicProfilePage(targetUserId: commentUid),
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: theme.primaryColor.withOpacity(0.15),
                        backgroundImage: commentProfilePic.isNotEmpty
                            ? NetworkImage(commentProfilePic)
                            : null,
                        child: commentProfilePic.isEmpty
                            ? Icon(
                                Icons.person,
                                size: 14,
                                color: theme.primaryColor,
                              )
                            : null,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        commentDisplayName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isMyComment && !isUnsent)
                  PopupMenuButton<String>(
                    icon: const Icon(
                      Icons.more_vert,
                      size: 18,
                      color: Colors.grey,
                    ),
                    padding: EdgeInsets.zero,
                    onSelected: (value) => value == 'edit'
                        ? onEdit(commentId, content)
                        : onUnsend(commentId, commentImages),
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Text('Edit Pesan'),
                      ),
                      const PopupMenuItem(
                        value: 'unsend',
                        child: Text(
                          'Tarik Pesan',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              isUnsent ? '$commentDisplayName $content' : content,
              style: TextStyle(
                fontSize: 14,
                color: isUnsent
                    ? Colors.grey
                    : (isDarkMode ? Colors.white : Colors.black87),
                fontStyle: isUnsent ? FontStyle.italic : FontStyle.normal,
              ),
            ),
            if (isEdited && !isUnsent)
              const Text(
                '(edited)',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),

            if (!isUnsent && commentImages.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: SizedBox(
                  height: 110,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: commentImages.length,
                    itemBuilder: (_, i) => Container(
                      margin: const EdgeInsets.only(right: 8),
                      width: 110,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          commentImages[i].toString(),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            if (!isUnsent)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () =>
                      onReplyTrigger(commentDisplayName.replaceAll('@', '')),
                  icon: const Icon(
                    Icons.reply_outlined,
                    size: 14,
                    color: Colors.grey,
                  ),
                  label: const Text(
                    "Reply",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
