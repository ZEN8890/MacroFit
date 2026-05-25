import 'package:flutter/material.dart';
import '../pages/public_profile_page.dart';
import 'reply_text_highlighter.dart';

class CommentCard extends StatelessWidget {
  final String commentId;
  final String postId; // 🟢 Tambahkan ini
  final Map<String, dynamic> commentData;
  final String currentUserId;
  final ThemeData theme;
  final bool isDarkMode;
  final Function(String, List<dynamic>?) onUnsend;
  final Function(String, String) onEdit;
  final Function(String) onReplyTrigger;
  final bool isRepliesHidden; // 🟢 Tambahkan ini
  final VoidCallback onToggleHideReplies; // 🟢 Tambahkan ini

  const CommentCard({
    super.key,
    required this.commentId,
    required this.postId, // 🟢 Tambahkan ini
    required this.commentData,
    required this.currentUserId,
    required this.theme,
    required this.isDarkMode,
    required this.onUnsend,
    required this.onEdit,
    required this.onReplyTrigger,
    required this.isRepliesHidden, // 🟢 Tambahkan ini
    required this.onToggleHideReplies, // 🟢 Tambahkan ini
  });

  @override
  Widget build(BuildContext context) {
    final textColor =
        Theme.of(context).textTheme.bodyMedium?.color ??
        (isDarkMode ? Colors.white : Colors.black87);
    final secondaryTextColor = isDarkMode ? Colors.white70 : Colors.black54;

    final String commentUid = commentData['uid'] ?? '';
    final String content = commentData['content'] ?? '';
    final String commentProfilePic = commentData['profile_image'] ?? '';
    final String displayName =
        '@${(commentData['username_handle'] ?? 'user').toLowerCase()}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PublicProfilePage(targetUserId: commentUid),
              ),
            ),
            child: CircleAvatar(
              radius: 16,
              backgroundImage: commentProfilePic.isNotEmpty
                  ? NetworkImage(commentProfilePic)
                  : null,
              child: commentProfilePic.isEmpty
                  ? Icon(Icons.person, size: 16, color: theme.primaryColor)
                  : null,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 2),
                DefaultTextStyle(
                  style: TextStyle(color: textColor, fontSize: 14),
                  child: ReplyTextHighlighter(text: content),
                ),
                TextButton(
                  onPressed: () =>
                      onReplyTrigger(displayName.replaceAll('@', '')),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(40, 20),
                  ),
                  child: Text(
                    "Reply",
                    style: TextStyle(fontSize: 11, color: secondaryTextColor),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
