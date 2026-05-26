import 'package:flutter/material.dart';
import 'reply_text_highlighter.dart';

class CommentCard extends StatelessWidget {
  final String commentId;
  final String postId;
  final Map<String, dynamic> commentData;
  final String currentUserId;
  final ThemeData theme;
  final bool isDarkMode;
  final Function(String, List<dynamic>?) onUnsend;
  final Function(String, String) onEdit;
  final Function(String) onReplyTrigger;
  final bool isRepliesHidden;
  final VoidCallback onToggleHideReplies;

  const CommentCard({
    super.key,
    required this.commentId,
    required this.postId,
    required this.commentData,
    required this.currentUserId,
    required this.theme,
    required this.isDarkMode,
    required this.onUnsend,
    required this.onEdit,
    required this.onReplyTrigger,
    required this.isRepliesHidden,
    required this.onToggleHideReplies,
  });

  // Fungsi untuk memotong teks preview
  String _getPreview(String text) {
    if (text.length <= 20) return text;
    return "${text.substring(0, 20)}...";
  }

  @override
  Widget build(BuildContext context) {
    final textColor =
        theme.textTheme.bodyMedium?.color ??
        (isDarkMode ? Colors.white : Colors.black87);

    final String content = commentData['content'] ?? '';
    final String profileImageUrl = commentData['profile_image'] ?? '';
    final String displayName =
        '@${(commentData['username_handle'] ?? 'user').toLowerCase()}';

    // Data balasan
    final String parentUsername = commentData['parent_username'] ?? '';
    final String parentContent = commentData['parent_content'] ?? '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🟢 Menampilkan Foto Profil
          CircleAvatar(
            radius: 16,
            backgroundColor: theme.primaryColor.withOpacity(0.15),
            backgroundImage: profileImageUrl.isNotEmpty
                ? NetworkImage(profileImageUrl)
                : null,
            child: profileImageUrl.isEmpty
                ? const Icon(Icons.person, size: 16)
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🟢 Visual Membalas ke @User: "..."
                if (parentUsername.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "Membalas ke @$parentUsername: \"${_getPreview(parentContent)}\"",
                      style: TextStyle(
                        fontSize: 10,
                        color: theme.primaryColor,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),

                Text(
                  displayName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                ReplyTextHighlighter(text: content),
                TextButton(
                  onPressed: () =>
                      onReplyTrigger(displayName.replaceAll('@', '')),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(50, 20),
                  ),
                  child: const Text("Reply", style: TextStyle(fontSize: 11)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
