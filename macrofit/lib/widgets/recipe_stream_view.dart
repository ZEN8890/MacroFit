import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/recipe_card.dart';
import '../pages/public_profile_page.dart';

class RecipeStreamView extends StatefulWidget {
  final String filterType;
  final String currentUserId;
  final FirebaseFirestore firestore;
  final String savedDietFilter;
  final void Function(String selectedDiet)? onDietFilterChanged;
  final void Function(Map<String, dynamic> data, String docId) onTapCard;
  final Future<void> Function(String docId, List<dynamic> currentSavedBy)
  onToggleFavorite;

  const RecipeStreamView({
    super.key,
    required this.filterType,
    required this.currentUserId,
    required this.firestore,
    this.savedDietFilter = 'All',
    this.onDietFilterChanged,
    required this.onTapCard,
    required this.onToggleFavorite,
  });

  @override
  State<RecipeStreamView> createState() => _RecipeStreamViewState();
}

class _RecipeStreamViewState extends State<RecipeStreamView> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      if (mounted) {
        setState(() {
          _searchQuery = _searchController.text.toLowerCase();
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Stream<QuerySnapshot> recipeStream;

    if (widget.filterType == 'MyPublished') {
      recipeStream = widget.firestore
          .collection('recipes')
          .where('userId', isEqualTo: widget.currentUserId)
          .where('type', isEqualTo: 'Community')
          .snapshots();
    } else if (widget.filterType == 'Favorites') {
      recipeStream = widget.firestore
          .collection('recipes')
          .where('savedBy', arrayContains: widget.currentUserId)
          .snapshots();
    } else {
      recipeStream = widget.firestore
          .collection('recipes')
          .where('type', isEqualTo: widget.filterType)
          .snapshots();
    }

    return Column(
      children: [
        if (widget.filterType != 'AI')
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 12.0,
              vertical: 8.0,
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari resep...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () => _searchController.clear(),
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
          ),

        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: recipeStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Text(
                      widget.filterType == 'AI'
                          ? 'Belum ada rekomendasi menu hari ini. Ketuk tombol kilat di atas!'
                          : 'Belum ada data resep.',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
                );
              }

              final theme = Theme.of(context);
              final isDarkMode = theme.brightness == Brightness.dark;

              final List<QueryDocumentSnapshot> originalDocs =
                  snapshot.data!.docs;

              Map<String, int> dietCounts = {'All': 0};
              List<QueryDocumentSnapshot> baseDocs = [];

              for (var doc in originalDocs) {
                if (doc.data() == null) continue;
                final data = doc.data() as Map<String, dynamic>;
                String currentType = data['type'] ?? 'User';

                if (widget.filterType == 'Favorites' && currentType == 'AI') {
                  continue;
                }

                baseDocs.add(doc);

                if (widget.filterType != 'AI') {
                  String diet = data['suitable_diet'] ?? 'Normal';
                  dietCounts['All'] = (dietCounts['All'] ?? 0) + 1;
                  dietCounts[diet] = (dietCounts[diet] ?? 0) + 1;
                }
              }

              List<QueryDocumentSnapshot> filteredRecipes = [];
              for (var doc in baseDocs) {
                final data = doc.data() as Map<String, dynamic>;
                String title = (data['title'] ?? '').toString().toLowerCase();

                if (widget.filterType != 'AI' &&
                    _searchQuery.isNotEmpty &&
                    !title.contains(_searchQuery)) {
                  continue;
                }

                if (widget.filterType != 'AI' &&
                    widget.savedDietFilter != 'All') {
                  final suitableDiet = data['suitable_diet'] ?? 'Normal';
                  if (suitableDiet != widget.savedDietFilter) {
                    continue;
                  }
                }

                filteredRecipes.add(doc);
              }

              filteredRecipes.sort((a, b) {
                final aData = a.data() as Map<String, dynamic>?;
                final bData = b.data() as Map<String, dynamic>?;

                final Timestamp? aTime = aData != null
                    ? aData['timestamp'] as Timestamp?
                    : null;
                final Timestamp? bTime = bData != null
                    ? bData['timestamp'] as Timestamp?
                    : null;

                if (aTime == null) return 1;
                if (bTime == null) return -1;
                return bTime.compareTo(aTime);
              });

              return Column(
                children: [
                  if (widget.filterType != 'AI' && dietCounts.length > 1)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 4.0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Filter Kategori Diet:",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode
                                  ? Colors.white60
                                  : Colors.black54,
                            ),
                          ),
                          DropdownButton<String>(
                            value:
                                dietCounts.containsKey(widget.savedDietFilter)
                                ? widget.savedDietFilter
                                : 'All',
                            icon: Icon(
                              Icons.filter_alt,
                              size: 18,
                              color: theme.primaryColor,
                            ),
                            underline: Container(
                              height: 1.5,
                              color: theme.primaryColor.withOpacity(0.5),
                            ),
                            dropdownColor: theme.cardColor,
                            style: TextStyle(
                              color: isDarkMode ? Colors.white : Colors.black87,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                widget.onDietFilterChanged?.call(newValue);
                              }
                            },
                            items: dietCounts.keys
                                .map<DropdownMenuItem<String>>((String key) {
                                  String label = key == 'All'
                                      ? 'Semua Diet'
                                      : key;
                                  return DropdownMenuItem<String>(
                                    value: key,
                                    child: Text(
                                      "$label (${dietCounts[key]})",
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  );
                                })
                                .toList(),
                          ),
                        ],
                      ),
                    ),

                  if (widget.filterType == 'Favorites')
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 16,
                      ),
                      margin: const EdgeInsets.only(bottom: 8, top: 4),
                      color: Colors.amber.withOpacity(0.1),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.folder_open,
                            size: 16,
                            color: Colors.orange,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "Library Koleksi Tersimpan: ${dietCounts['All'] ?? 0} / 50 Resep",
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ),

                  Expanded(
                    child: filteredRecipes.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Text(
                                widget.filterType == 'Favorites'
                                    ? 'Tidak ada resep khusus diet "${widget.savedDietFilter}".'
                                    : 'Tidak ada hasil resep yang cocok.',
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.grey),
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.only(top: 8, bottom: 80),
                            itemCount: filteredRecipes.length,
                            itemBuilder: (context, index) {
                              final doc = filteredRecipes[index];
                              final recipeData =
                                  doc.data() as Map<String, dynamic>;
                              final List<dynamic> savedByList =
                                  recipeData['savedBy'] ?? [];

                              String displayType = recipeData['type'] ?? 'User';
                              if (recipeData['origin_type'] == 'AI') {
                                displayType = 'AI';
                              }

                              final String recipeUserId =
                                  recipeData['userId'] ?? '';
                              final String recipeHandle =
                                  recipeData['username_handle'] ?? '';
                              final String recipeAuthorName =
                                  recipeData['username'] ?? 'User MacroFit';

                              // 🟢 PERBAIKAN LOGIKA PRESISI: Deteksi Akun Owner murni via UID
                              String authorHandle;
                              if (displayType == 'AI') {
                                authorHandle = 'MacroFit AI';
                              } else if (recipeUserId == widget.currentUserId) {
                                // 🎯 Jika resep ini dikreasi oleh kamu sendiri, paksa visualisasinya memunculkan @stvnnvts8 murni
                                authorHandle = '@stvnnvts8';
                              } else if (recipeHandle
                                  .toString()
                                  .trim()
                                  .isNotEmpty) {
                                // Jika resep milik user lain yang sudah memiliki field handle murni
                                authorHandle =
                                    '@${recipeHandle.toString().trim().toLowerCase()}';
                              } else {
                                // Fallback otomatis untuk resep lama milik pengguna lain
                                String fallbackHandle = recipeAuthorName
                                    .trim()
                                    .toLowerCase()
                                    .replaceAll(' ', '');
                                authorHandle = '@$fallbackHandle';
                              }

                              return RecipeCard(
                                title:
                                    recipeData['title'] ?? 'Resep Tanpa Nama',
                                calories: recipeData['calories'] ?? 0,
                                imageUrl: recipeData['image_url'],
                                imageKeyword: recipeData['image_keyword'],
                                author: authorHandle,
                                type: displayType,
                                isSaved: savedByList.contains(
                                  widget.currentUserId,
                                ),
                                onFavPressed: () => widget.onToggleFavorite(
                                  doc.id,
                                  savedByList,
                                ),
                                onTapCard: () =>
                                    widget.onTapCard(recipeData, doc.id),
                                onTapAuthor: () {
                                  if (recipeData['userId'] != null) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => PublicProfilePage(
                                          targetUserId: recipeData['userId'],
                                        ),
                                      ),
                                    );
                                  }
                                },
                              );
                            },
                          ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
