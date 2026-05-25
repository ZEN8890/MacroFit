import 'package:flutter/material.dart';

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
  // 🟢 1. SUNTIKKAN CALLBACK BARU UNTUK NAVIGASI PROFIL PUBLIK
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
    this.onTapAuthor, // 🟢 2. MASUKKAN KE DALAM CONSTRUCTOR
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    String finalImageUrl = imageUrl ?? '';

    if (finalImageUrl.isEmpty && type == 'AI') {
      final String keyword = imageKeyword ?? 'healthy_food';
      final String uniqueString = Uri.encodeComponent(title);

      finalImageUrl =
          'https://images.unsplash.com/photo-1498837167922-ddd27525d352?q=80&w=600&auto=format&fit=crop';

      if (keyword != 'healthy_food' && keyword.isNotEmpty) {
        finalImageUrl =
            'https://images.unsplash.com/featured/600x400/?$keyword&random=$uniqueString';
      }
    }

    // 🟢 LOGIKA EVALUASI VISUAL: Memformat nama kreator resep menjadi @username secara otomatis
    String formatAuthor = author;
    if (type != 'AI' && !author.startsWith('@')) {
      formatAuthor = '@$author';
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTapCard,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (finalImageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                // 🟢 FIX UTAMA: Bungkus dengan Hero menggunakan Tag Dinamis berdasarkan Title agar tidak duplikat di subtree
                child: Hero(
                  tag: 'recipe_image_${type}_$title',
                  child: Image.network(
                    finalImageUrl,
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 160,
                        width: double.infinity,
                        color: theme.primaryColor.withOpacity(0.05),
                        child: const Center(
                          child: Icon(
                            Icons.broken_image_outlined,
                            color: Colors.grey,
                            size: 40,
                          ),
                        ),
                      );
                    },
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
                          type == 'AI' ? '✨ AI Recipe' : '👥 User Recipe',
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
                              isSaved ? Icons.bookmark : Icons.bookmark_border,
                              color: isSaved ? theme.primaryColor : Colors.grey,
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

                  // 🟢 3. UPDATE: BUNGKUS TEKS AUTHOR AGAR DAPAT DIKETUK OLEH USER LAIN
                  InkWell(
                    onTap: type == 'AI'
                        ? null
                        : onTapAuthor, // Nonaktifkan jika resep AI murni
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 2.0,
                        horizontal: 4.0,
                      ),
                      child: Text(
                        'Oleh: $formatAuthor', // 🟢 Menggunakan teks terformat username handle @
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: type == 'AI'
                              ? FontWeight.normal
                              : FontWeight.w600,
                          color: type == 'AI'
                              ? (isDarkMode ? Colors.white60 : Colors.black54)
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
  }
}
