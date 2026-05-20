import 'package:flutter/material.dart';

class RecipeCard extends StatelessWidget {
  final String title;
  final String calories;
  final String? imageUrl;
  final String author;
  final String type;
  final List<dynamic> ingredients;
  final List<dynamic> instructions;
  final bool isSaved;
  final VoidCallback onFavPressed;
  final VoidCallback onTapCard; // 🔥 Callback tambahan untuk deteksi klik kartu

  const RecipeCard({
    super.key,
    required this.title,
    required this.calories,
    required this.imageUrl,
    required this.author,
    required this.type,
    required this.ingredients,
    required this.instructions,
    required this.isSaved,
    required this.onFavPressed,
    required this.onTapCard, // Wajib disertakan
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap:
            onTapCard, // 🔥 Menghubungkan klik ke fungsi BottomSheet Detail Resep
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageUrl != null && imageUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                child: Image.network(
                  imageUrl!,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
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
                              : theme.primaryColor.withOpacity(
                                  0.1,
                                ), // 🔥 Menggunakan warna utama aplikasi (Biru)
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          type == 'AI' ? '✨ AI Recipe' : '👥 User Recipe',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: type == 'AI'
                                ? Colors.purple
                                : theme
                                      .primaryColor, // 🔥 Menyesuaikan warna Biru tema
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
                              color: isSaved
                                  ? theme.primaryColor
                                  : Colors
                                        .grey, // 🔥 Warna bookmark diubah ke Biru tema saat aktif
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
                  const SizedBox(height: 4),
                  Text(
                    'Oleh: $author',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDarkMode ? Colors.white60 : Colors.black54,
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
