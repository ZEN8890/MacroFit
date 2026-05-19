import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/recipe_card.dart';

class RecipePage extends StatefulWidget {
  const RecipePage({super.key});

  @override
  State<RecipePage> createState() => _RecipePageState();
}

class _RecipePageState extends State<RecipePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream Builder Helper untuk memfilter tipe resep secara instan
  Widget _buildRecipeStream(String typeFilter) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('recipes')
          .where('type', isEqualTo: typeFilter)
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              typeFilter == 'AI'
                  ? 'Belum ada resep dari AI rekomendasi.'
                  : 'Belum ada resep buatan user komunitas.',
              style: const TextStyle(color: Colors.grey),
            ),
          );
        }

        final recipes = snapshot.data!.docs;

        return ListView.builder(
          itemCount: recipes.length,
          itemBuilder: (context, index) {
            final recipeData = recipes[index].data() as Map<String, dynamic>;

            return RecipeCard(
              title: recipeData['title'] ?? 'Resep Tanpa Nama',
              calories: (recipeData['calories'] ?? 0).toString(),
              imageUrl: recipeData['image_url'],
              author: recipeData['username'] ?? 'System',
              type: recipeData['type'] ?? 'User',
              ingredients: recipeData['ingredients'] ?? [],
              instructions: recipeData['instructions'] ?? [],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            "MacroFit Recipes",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: theme.appBarTheme.backgroundColor,
          foregroundColor: theme.appBarTheme.foregroundColor,
          elevation: 0,
          bottom: TabBar(
            labelColor: isDarkMode ? Colors.white : theme.primaryColor,
            unselectedLabelColor: isDarkMode ? Colors.white38 : Colors.black38,
            indicatorColor: theme.primaryColor,
            indicatorSize: TabBarIndicatorSize.tab,
            tabs: const [
              Tab(
                text: 'Rekomendasi AI',
                icon: Icon(Icons.psychology_outlined),
              ),
              Tab(
                text: 'Resep Komunitas',
                icon: Icon(Icons.restaurant_menu_outlined),
              ),
            ],
          ),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        body: TabBarView(
          children: [
            // Tab 1: Khusus memfilter resep hasil kreasi AI cerdas Anda
            _buildRecipeStream('AI'),

            // Tab 2: Khusus memfilter resep buatan kontribusi para user
            _buildRecipeStream('User'),
          ],
        ),

        // Tombol Mengambang (FAB) untuk memudahkan user mengunggah resep kreasi mereka sendiri nanti
        floatingActionButton: FloatingActionButton(
          backgroundColor: theme.primaryColor,
          foregroundColor: Colors.white,
          onPressed: () {
            // TODO: Buka form tambah resep baru kustom
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
