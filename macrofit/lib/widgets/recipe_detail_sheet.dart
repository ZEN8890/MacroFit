import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RecipeDetailSheet extends StatefulWidget {
  final Map<String, dynamic> recipeData;
  final String docId;
  final String currentUserId;
  final Future<void> Function(String, List<dynamic>) onToggleFavorite;
  final VoidCallback onDeleteRecipe; // 🔥 1. TAMBAHKAN DEFINISI PARAMETER INI

  const RecipeDetailSheet({
    super.key,
    required this.recipeData,
    required this.docId,
    required this.currentUserId,
    required this.onToggleFavorite,
    required this.onDeleteRecipe, // 🔥 2. TAMBAHKAN DI CONSTRUCTOR
  });

  @override
  State<RecipeDetailSheet> createState() => _RecipeDetailSheetState();
}

class _RecipeDetailSheetState extends State<RecipeDetailSheet> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus Resep'),
        content: const Text(
          'Apakah Anda yakin ingin menghapus resep ini secara permanen dari database?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext); // Tutup dialog konfirmasi
              widget
                  .onDeleteRecipe(); // 🔥 3. PANGGIL CALLBACK PENGHAPUSAN UTAMA
              if (context.mounted)
                Navigator.pop(context); // Tutup BottomSheet detail
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    List<String> ingredients = List<String>.from(
      widget.recipeData['ingredients'] ?? [],
    );
    List<String> instructions = List<String>.from(
      widget.recipeData['instructions'] ?? [],
    );
    bool isMyOwnRecipe = widget.recipeData['userId'] == widget.currentUserId;

    return StreamBuilder<DocumentSnapshot>(
      stream: _firestore.collection('recipes').doc(widget.docId).snapshots(),
      builder: (context, snapshot) {
        List<dynamic> savedByList = [];
        if (snapshot.hasData && snapshot.data!.exists) {
          final currentData = snapshot.data!.data() as Map<String, dynamic>;
          savedByList = currentData['savedBy'] ?? [];
        } else {
          savedByList = widget.recipeData['savedBy'] ?? [];
        }
        bool isSaved = savedByList.contains(widget.currentUserId);

        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          widget.recipeData['title'] ?? 'Resep Tanpa Nama',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          isSaved ? Icons.bookmark : Icons.bookmark_border,
                          color: isSaved ? theme.primaryColor : Colors.grey,
                          size: 28,
                        ),
                        onPressed: () async {
                          await widget.onToggleFavorite(
                            widget.docId,
                            savedByList,
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.local_fire_department,
                        color: Colors.orange.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${widget.recipeData['calories'] ?? 0} Kcal',
                        style: TextStyle(
                          color: Colors.orange.shade700,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'Oleh: ${widget.recipeData['username'] ?? 'User'}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: [
                      Chip(
                        label: Text(
                          "Cocok: ${widget.recipeData['suitable_diet'] ?? 'Normal'}",
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        backgroundColor: Colors.green.withOpacity(0.1),
                        side: BorderSide.none,
                      ),
                      if (widget.recipeData['unsuitable_diet'] != null &&
                          widget.recipeData['unsuitable_diet'] != 'None')
                        Chip(
                          label: Text(
                            "Bukan untuk: ${widget.recipeData['unsuitable_diet']}",
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          backgroundColor: Colors.red.withOpacity(0.1),
                          side: BorderSide.none,
                        ),
                    ],
                  ),

                  // Jika resep ini buatan user sendiri, munculkan tombol Edit dan Hapus secara interaktif
                  if (isMyOwnRecipe) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: theme.primaryColor,
                              side: BorderSide(color: theme.primaryColor),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            label: const Text('Edit'),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // 🔥 TOMBOL HAPUS: Memanggil dialog konfirmasi lokal
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            icon: const Icon(Icons.delete_outline, size: 18),
                            label: const Text('Hapus'),
                            onPressed: () => _showDeleteConfirmation(context),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const Divider(height: 32),
                  const Text(
                    'Bahan - Bahan:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...ingredients.map(
                    (item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '• ',
                            style: TextStyle(
                              color: theme.primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              item,
                              style: const TextStyle(fontSize: 15),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Divider(height: 32),
                  const Text(
                    'Langkah Memasak:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...instructions.asMap().entries.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 10,
                            backgroundColor: theme.primaryColor.withOpacity(
                              0.1,
                            ),
                            child: Text(
                              '${entry.key + 1}',
                              style: TextStyle(
                                fontSize: 11,
                                color: theme.primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              entry.value,
                              style: const TextStyle(fontSize: 15),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
