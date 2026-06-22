import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'recipe_detail_sheet.dart';

class CreatorRecipesTab extends StatelessWidget {
  final String targetUserId;
  final bool englishActive;

  const CreatorRecipesTab({
    super.key,
    required this.targetUserId,
    required this.englishActive,
  });

  void _showRecipeDetail(
    BuildContext context,
    Map<String, dynamic> recipeData,
    String docId,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => RecipeDetailSheet(
        recipeData: recipeData,
        docId: docId,
        currentUserId: targetUserId,
        onToggleFavorite: (id, savedByList) async {
          try {
            final docRef = FirebaseFirestore.instance
                .collection('recipes')
                .doc(id);
            if (savedByList.contains(targetUserId)) {
              await docRef.update({
                'savedBy': FieldValue.arrayRemove([targetUserId]),
              });
            } else {
              await docRef.update({
                'savedBy': FieldValue.arrayUnion([targetUserId]),
              });
            }
          } catch (e) {
            debugPrint("Error toggle favorite: $e");
          }
        },
        onDeleteRecipe: () async {
          await FirebaseFirestore.instance
              .collection('recipes')
              .doc(docId)
              .delete();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('recipes')
          .where('userId', isEqualTo: targetUserId)
          .snapshots(),
      builder: (context, recipeSnapshot) {
        if (recipeSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final allDocs = recipeSnapshot.data?.docs ?? [];
        final communityDocs = allDocs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['type'] == 'Community';
        }).toList();

        if (communityDocs.isEmpty) {
          return Center(
            child: Text(
              englishActive
                  ? 'This creator hasn\'t shared any recipes yet.'
                  : 'Kreator ini belum membagikan resep apa pun.',
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: communityDocs.length,
          itemBuilder: (context, index) {
            final docId = communityDocs[index].id;
            final recipeData =
                communityDocs[index].data() as Map<String, dynamic>;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _showRecipeDetail(context, recipeData, docId),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: theme.primaryColor.withOpacity(0.1),
                      child: Icon(
                        Icons.restaurant_menu,
                        color: theme.primaryColor,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      recipeData['title'] ??
                          (englishActive
                              ? 'Untitled Recipe'
                              : 'Resep Tanpa Nama'),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('${recipeData['calories'] ?? 0} Kcal'),
                    trailing: const Icon(Icons.chevron_right, size: 18),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
