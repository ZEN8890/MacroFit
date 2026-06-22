import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../utils/global_state.dart';

class RecipeCard extends StatelessWidget {
  final String title;
  final int calories;
  final String? imageUrl;
  final String type;
  final String author;
  final bool isSaved;
  final VoidCallback onTapCard;
  final VoidCallback onFavPressed;
  final String? imageKeyword;
  final VoidCallback? onTapAuthor;

  const RecipeCard({
    super.key,
    required this.title,
    required this.calories,
    this.imageUrl,
    required this.type,
    required this.author,
    required this.isSaved,
    required this.onTapCard,
    required this.onFavPressed,
    this.imageKeyword,
    this.onTapAuthor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    String resolvedImageUrl = imageUrl ?? '';
    final bool hasImage = resolvedImageUrl.isNotEmpty;

    if (!hasImage && type == 'AI') {
      final String keyword = (imageKeyword != null && imageKeyword!.isNotEmpty)
          ? imageKeyword!
          : 'healthy_food';
      resolvedImageUrl =
          'https://images.unsplash.com/featured/600x400/?$keyword';
    }

    String formatAuthor = author;
    if (type != 'AI' && !author.startsWith('@')) {
      formatAuthor = '@$author';
    }

    return ValueListenableBuilder<bool>(
      valueListenable: isEnglishNotifier,
      builder: (context, englishActive, child) {
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTapCard,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (resolvedImageUrl.isNotEmpty)
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                    child: SizedBox(
                      height: 180,
                      width: double.infinity,
                      child: Hero(
                        tag: 'recipe_image_${type}_$title',
                        child: CachedNetworkImage(
                          imageUrl: resolvedImageUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: theme.primaryColor.withOpacity(0.05),
                            child: const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.grey.shade200,
                            child: const Icon(
                              Icons.restaurant,
                              color: Colors.grey,
                              size: 40,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: type == 'AI'
                                  ? Colors.purple.withOpacity(0.1)
                                  : theme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              type == 'AI'
                                  ? (englishActive
                                        ? '✨ AI Recipe'
                                        : '✨ Resep AI')
                                  : (englishActive
                                        ? '👥 User Recipe'
                                        : '👥 Resep Pengguna'),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: type == 'AI'
                                    ? Colors.purple
                                    : theme.primaryColor,
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              Icon(
                                Icons.local_fire_department,
                                size: 18,
                                color: Colors.orange.shade700,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '$calories Kcal',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange.shade700,
                                ),
                              ),
                              const SizedBox(width: 10),
                              IconButton(
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                icon: Icon(
                                  isSaved
                                      ? Icons.bookmark
                                      : Icons.bookmark_border,
                                  color: isSaved
                                      ? theme.primaryColor
                                      : Colors.grey,
                                  size: 22,
                                ),
                                onPressed: onFavPressed,
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: type == 'AI' ? null : onTapAuthor,
                        borderRadius: BorderRadius.circular(4),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 2.0,
                            horizontal: 4.0,
                          ),
                          child: Text(
                            englishActive
                                ? 'By: $formatAuthor'
                                : 'Oleh: $formatAuthor',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: type == 'AI'
                                  ? FontWeight.normal
                                  : FontWeight.w600,
                              color: type == 'AI'
                                  ? (isDarkMode
                                        ? Colors.white60
                                        : Colors.black54)
                                  : theme.primaryColor,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
