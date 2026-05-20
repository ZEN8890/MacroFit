import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../widgets/recipe_detail_sheet.dart';
import '../widgets/add_recipe_sheet.dart';
import '../widgets/recipe_stream_view.dart';

class RecipePage extends StatefulWidget {
  const RecipePage({super.key});

  @override
  State<RecipePage> createState() => _RecipePageState();
}

class _RecipePageState extends State<RecipePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isGeneratingAI = false;
  int _remainingCounter = 2;
  // 🔥 TIGA STATE FILTER TERISOLASI UNTUK MASING-MASING TAB
  String _selectedCommunityDietFilter = 'All';
  String _selectedPublishedDietFilter = 'All';
  String _selectedSavedDietFilter = 'All';

  String get currentUserId => _auth.currentUser?.uid ?? '';
  final List<String> _dietOptions = [
    'Normal',
    'Bulking',
    'Cutting',
    'Low Carb',
    'Keto',
    'Vegan',
    'Vegetarian',
    'High Protein',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkDailyRefreshAndCounter();
    });
  }

  Future<void> _checkDailyRefreshAndCounter() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      final String todayDate =
          "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

      final String? lastRefreshDate = prefs.getString('last_ai_recipe_refresh');
      int? savedCounter = prefs.getInt('ai_recipe_click_counter');

      if (lastRefreshDate == null || lastRefreshDate != todayDate) {
        await _generateAIRecipe(isAutoRefresh: true);
        await prefs.setString('last_ai_recipe_refresh', todayDate);
        await prefs.setInt('ai_recipe_click_counter', 2);
        if (mounted) {
          setState(() {
            _remainingCounter = 2;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _remainingCounter = savedCounter ?? 2;
          });
        }
      }
    } catch (e) {
      debugPrint("Error Pengecekan Limit: $e");
    }
  }

  Future<void> _generateAIRecipe({bool isAutoRefresh = false}) async {
    if (!isAutoRefresh && _remainingCounter <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Batas limit harian habis!')),
        );
      }
      return;
    }
    if (!mounted) return;
    setState(() {
      _isGeneratingAI = true;
    });

    try {
      if (currentUserId.isEmpty) return;
      final userDoc = await _firestore
          .collection('users')
          .doc(currentUserId)
          .get();
      double targetCalorie = 2000.0;
      String dietCode = 'Normal';

      if (userDoc.exists && userDoc.data() != null) {
        final userData = userDoc.data() as Map<String, dynamic>;
        targetCalorie = (userData['target_calories'] ?? 2000.0).toDouble();
        dietCode = userData['diet_code'] ?? 'Normal';
      }

      final oldAIRecipesSnapshot = await _firestore
          .collection('recipes')
          .where('type', isEqualTo: 'AI')
          .get();

      final batchDelete = _firestore.batch();
      for (var doc in oldAIRecipesSnapshot.docs) {
        batchDelete.delete(doc.reference);
      }
      await batchDelete.commit();

      final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
      if (apiKey.isEmpty) return;

      final model = GenerativeModel(
        model: 'gemini-3.1-flash-lite',
        apiKey: apiKey,
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
        ),
      );

      // --- PERBAIKAN PROMPT & PEMETAAN KATEGORI AI ---
      final prompt =
          '''
      Anda adalah Chef Gizi Profesional untuk aplikasi MacroFit.
      Tugas Anda adalah merancang TEPAT 10 rekomendasi resep makanan sehat yang berbeda, unik, bervariasi, dan sangat kreatif agar pengguna tidak bosan.
      Seluruh resep harus disesuaikan secara ilmiah untuk profil diet berikut:
      - Tipe Program Diet: $dietCode
      - Target Kalori Harian Pengguna: $targetCalorie kkal

      Berikan output HARUS dalam format JSON Array murni yang berisi 10 objek resep. Jangan berikan teks penjelasan markdown di luar JSON.
      
      ⚠️ ATURAN SANGAT KETAT UNTUK KATEGORI DIET:
      1. Untuk properti "suitable_diet", Anda HARUS memilih salah satu nilai yang tepat dari daftar resmi berikut: ${_dietOptions.join(', ')}. Sesuaikan dengan program diet pengguna saat ini ($dietCode).
      2. Untuk properti "unsuitable_diet", pilih satu nilai dari daftar di atas yang paling tidak cocok sebagai pantangan makanan tersebut, atau berikan nilai "None" jika aman untuk semua diet.
      
      Pastikan semua huruf pada key (kunci) menggunakan HURUF KECIL SEMUA seperti contoh berikut:
      [
        {
          "title": "Ayam Panggang Lemon Madu",
          "calories": 350,
          "ingredients": ["100g Dada Ayam", "1 sdm Madu", "Perasan Lemon"],
          "instructions": ["Marinasi ayam dengan lemon dan madu", "Panggang hingga matang 20 menit"],
          "suitable_diet": "$dietCode",
          "unsuitable_diet": "Vegan"
        }
      ]
      ''';

      final response = await model.generateContent([Content.text(prompt)]);

      if (response.text != null && response.text!.isNotEmpty) {
        final List<dynamic> aiRecipesList = json.decode(response.text!);
        final batchInsert = _firestore.batch();

        for (var recipe in aiRecipesList) {
          final docRef = _firestore.collection('recipes').doc();

          // Validasi tambahan di sisi klien (Dart) sebagai pengaman jika AI berhalusinasi teks kustom
          String aiSuitable = recipe['suitable_diet'] ?? dietCode;
          String aiUnsuitable = recipe['unsuitable_diet'] ?? 'None';

          // Jika AI mengembalikan teks yang tidak terdaftar di _dietOptions, paksa kembali ke default/Normal
          if (!_dietOptions.contains(aiSuitable)) aiSuitable = dietCode;
          if (aiUnsuitable != 'None' && !_dietOptions.contains(aiUnsuitable))
            aiUnsuitable = 'None';

          batchInsert.set(docRef, {
            'title': recipe['title'] ?? 'Resep Kuliner Sehat AI',
            'calories': recipe['calories'] ?? 0,
            'image_url': null,
            'username': 'MacroFit AI',
            'type': 'AI',
            'ingredients': recipe['ingredients'] ?? [],
            'instructions': recipe['instructions'] ?? [],
            'timestamp': FieldValue.serverTimestamp(),
            'savedBy': [],
            'suitable_diet':
                aiSuitable, // 🔥 Menggunakan kategori tervalidasi kaku
            'unsuitable_diet':
                aiUnsuitable, // 🔥 Menggunakan pantangan tervalidasi kaku
          });
        }
        await batchInsert.commit();

        if (!isAutoRefresh) {
          final prefs = await SharedPreferences.getInstance();
          if (mounted) {
            setState(() {
              _remainingCounter--;
            });
          }
          await prefs.setInt('ai_recipe_click_counter', _remainingCounter);
        }
      }
    } catch (e) {
      debugPrint("Gagal generate: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingAI = false;
        });
      }
    }
  }

  void _showRecipeDetail(Map<String, dynamic> recipeData, String docId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => RecipeDetailSheet(
        recipeData: recipeData,
        docId: docId,
        currentUserId: currentUserId,
        onToggleFavorite: _toggleFavoriteRecipe,
        onDeleteRecipe: () async {
          await _firestore.collection('recipes').doc(docId).delete();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Resep Anda berhasil dihapus secara permanen.'),
              ),
            );
          }
        },
      ),
    );
  }

  void _showAddRecipeDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => AddRecipeSheet(
        dietOptions: _dietOptions,
        onPublish:
            (
              title,
              calories,
              ingredients,
              instructions,
              suitable, // Data dropdown terfilter 'Cocok untuk'
              unsuitable, // Data dropdown terfilter 'Pantangan untuk'
            ) async {
              final uDoc = await _firestore
                  .collection('users')
                  .doc(currentUserId)
                  .get();
              String username = uDoc.data()?['username'] ?? 'User';

              // Menyimpan resep kreasi mandiri user ke database komunitas
              await _firestore.collection('recipes').add({
                'title': title,
                'calories': calories,
                'image_url': null,
                'username': username,
                'type': 'Community',
                'userId': currentUserId,
                'ingredients': ingredients,
                'instructions': instructions,
                'timestamp': FieldValue.serverTimestamp(),
                'savedBy': [],
                'suitable_diet':
                    suitable, // 🔥 Mengunci string persis pilihan dropdown
                'unsuitable_diet':
                    unsuitable, // 🔥 Mengunci string persis pilihan dropdown
              });
            },
      ),
    );
  }

  Future<void> _toggleFavoriteRecipe(
    String docId,
    List<dynamic> currentSavedBy,
  ) async {
    try {
      final docRef = _firestore.collection('recipes').doc(docId);
      final docSnapshot = await docRef.get();

      if (!docSnapshot.exists) return;
      final recipeData = docSnapshot.data() as Map<String, dynamic>;
      String recipeType = recipeData['type'] ?? 'User';

      if (currentSavedBy.contains(currentUserId)) {
        if (recipeType == 'Favorites') {
          await docRef.delete();
        } else {
          await docRef.update({
            'savedBy': FieldValue.arrayRemove([currentUserId]),
          });
        }
        return;
      }

      final favoriteSnapshot = await _firestore
          .collection('recipes')
          .where('savedBy', arrayContains: currentUserId)
          .get();

      if (favoriteSnapshot.docs.length >= 50) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                '⚠️ Batas simpan penuh! Koleksi resep Saved maksimal adalah 50 resep.',
              ),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
        return;
      }

      // === CARI BLOK LOGIKA INI DI RECYCLE_PAGE.DART DAN UPDATE ===
      // 4. LOGIKA UTAMA: JIKA YANG DI-SAVE ADALAH RESEP DARI 'AI'
      if (recipeType == 'AI') {
        // Buat DOKUMEN SALINAN BARU yang terisolasi agar abadi di Tab Saved
        await _firestore.collection('recipes').add({
          'title': recipeData['title'],
          'calories': recipeData['calories'],
          'image_url': recipeData['image_url'],
          'username': recipeData['username'],
          'type':
              'Favorites', // Tetap Favorites agar tidak ikut terhapus Batch Delete AI
          'origin_type':
              'AI', // 🔥 SEBAGAI TRACKING: Tandai bahwa aslinya dari AI agar labelnya akurat
          'userId': currentUserId,
          'ingredients': recipeData['ingredients'],
          'instructions': recipeData['instructions'],
          'timestamp': FieldValue.serverTimestamp(),
          'savedBy': [currentUserId], // Menyimpan ID user di dokumen baru
          'suitable_diet': recipeData['suitable_diet'] ?? 'Normal',
          'unsuitable_diet': recipeData['unsuitable_diet'] ?? 'None',
        });

        // 🔥 KEMBALIKAN BARIS INI: Cukup update array savedBy dokumen AI asli
        // agar widget Stream di Tab AI mendeteksi perubahan dan mengubah bentuk ikonnya!
        await docRef.update({
          'savedBy': FieldValue.arrayUnion([currentUserId]),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Resep AI berhasil disimpan ke Library Saved!'),
            ),
          );
        }
      } else {
        // Jika resep dari tab Community, cukup gunakan cara lama (tambahkan ID ke array savedBy)
        await docRef.update({
          'savedBy': FieldValue.arrayUnion([currentUserId]),
        });
      }
    } catch (e) {
      debugPrint("Gagal menjalankan fungsi toggle favorite: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return DefaultTabController(
      length: 4,
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
            isScrollable: false,
            labelColor: theme.primaryColor,
            unselectedLabelColor: isDarkMode ? Colors.white38 : Colors.black38,
            indicatorColor: theme.primaryColor,
            indicatorSize: TabBarIndicatorSize.tab,
            labelPadding: const EdgeInsets.symmetric(horizontal: 2.0),
            labelStyle: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
            unselectedLabelStyle: const TextStyle(fontSize: 11),
            tabs: const [
              Tab(icon: Icon(Icons.psychology_outlined, size: 20), text: 'AI'),
              Tab(
                icon: Icon(Icons.people_outline, size: 20),
                text: 'Community',
              ),
              Tab(
                icon: Icon(Icons.assignment_ind_outlined, size: 20),
                text: 'Published',
              ),
              Tab(icon: Icon(Icons.bookmark_border, size: 20), text: 'Saved'),
            ],
          ),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        // === CARI BLOK TABBARVIEW INI DI RECIPE_PAGE.DART DAN TIMPA ===
        body: TabBarView(
          children: [
            _buildAITabView(), // Tab AI bersih, tidak mengirim callback filter apa pun
            // Tab Community dengan filter mandiri
            RecipeStreamView(
              key: ValueKey('stream_community_$_selectedCommunityDietFilter'),
              filterType: 'Community',
              currentUserId: currentUserId,
              firestore: _firestore,
              savedDietFilter: _selectedCommunityDietFilter,
              onDietFilterChanged: (selectedDiet) {
                setState(() {
                  _selectedCommunityDietFilter = selectedDiet;
                });
              },
              onTapCard: _showRecipeDetail,
              onToggleFavorite: _toggleFavoriteRecipe,
            ),

            // Tab Published dengan filter mandiri
            RecipeStreamView(
              key: ValueKey('stream_published_$_selectedPublishedDietFilter'),
              filterType: 'MyPublished',
              currentUserId: currentUserId,
              firestore: _firestore,
              savedDietFilter: _selectedPublishedDietFilter,
              onDietFilterChanged: (selectedDiet) {
                setState(() {
                  _selectedPublishedDietFilter = selectedDiet;
                });
              },
              onTapCard: _showRecipeDetail,
              onToggleFavorite: _toggleFavoriteRecipe,
            ),

            _buildSavedTabView(),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _showAddRecipeDialog,
          backgroundColor: theme.primaryColor,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add),
          label: const Text('Publish Recipe'),
        ),
      ),
    );
  }

  // === CARI METHOD INI DI BAGIAN BAWAH RECIPE_PAGE.DART DAN RAPIKAN ===
  Widget _buildAITabView() {
    final theme = Theme.of(context);
    final bool isButtonDisabled = _remainingCounter <= 0 || _isGeneratingAI;

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: theme.primaryColor.withOpacity(0.05),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Bosan dengan Menu Lama?",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Minta AI buatkan resep instan! (Sisa Hari Ini: $_remainingCounter/2)",
                      style: TextStyle(
                        fontSize: 12,
                        color: _remainingCounter == 0
                            ? Colors.red.shade400
                            : Colors.grey,
                        fontWeight: _remainingCounter == 0
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _isGeneratingAI
                  ? const CircularProgressIndicator(strokeWidth: 3)
                  : SizedBox(
                      width: 130,
                      height: 38,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isButtonDisabled
                              ? Colors.grey.shade400
                              : theme.primaryColor,
                          foregroundColor: isButtonDisabled
                              ? Colors.grey.shade600
                              : Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 0,
                          ),
                          minimumSize: Size.zero,
                          maximumSize: const Size(130, 38),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          elevation: isButtonDisabled ? 0 : 2,
                        ),
                        icon: Icon(
                          Icons.bolt,
                          color: isButtonDisabled
                              ? Colors.grey.shade600
                              : Colors.amber,
                          size: 16,
                        ),
                        label: const Text(
                          "Generate AI",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onPressed: isButtonDisabled
                            ? null
                            : () => _generateAIRecipe(isAutoRefresh: false),
                      ),
                    ),
            ],
          ),
        ),
        Expanded(
          child: RecipeStreamView(
            key: const ValueKey('stream_ai_tab'),
            filterType: 'AI',
            currentUserId: currentUserId,
            firestore: _firestore,
            // 🔥 SEKARANG BERSIH: Parameter onDietFilterChanged & savedDietFilter
            // sudah dihapus total dari sini karena Tab AI tidak membutuhkannya lagi!
            onTapCard: _showRecipeDetail,
            onToggleFavorite: _toggleFavoriteRecipe,
          ),
        ),
      ],
    );
  }

  // --- 🔥 METHOD LAYOUT BARU UNTUK TAB SAVED DENGAN WIDGET DROPDOWN FILTER DIET ---
  Widget _buildSavedTabView() {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Column(
      children: [
        // Spanduk Filter Diet
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: theme.primaryColor.withOpacity(0.03),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.filter_list, size: 18, color: Colors.grey),
                  SizedBox(width: 8),
                  Text(
                    "Saring Kategori:",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              DropdownButton<String>(
                value: _selectedSavedDietFilter,
                elevation: 3,
                dropdownColor: theme.colorScheme.surface,
                icon: Icon(Icons.arrow_drop_down, color: theme.primaryColor),
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black87,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
                underline: Container(
                  height: 1.5,
                  color: theme.primaryColor.withOpacity(0.5),
                ),
                items: ['All', ..._dietOptions].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value == 'All' ? 'Semua Diet' : value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedSavedDietFilter = newValue;
                    });
                  }
                },
              ),
            ],
          ),
        ),
        // Stream List dengan key unik yang diperbarui sesuai filter aktif
        Expanded(
          child: RecipeStreamView(
            key: ValueKey('stream_favorites_$_selectedSavedDietFilter'),
            filterType: 'Favorites',
            currentUserId: currentUserId,
            firestore: _firestore,
            savedDietFilter: _selectedSavedDietFilter,
            onDietFilterChanged: (selectedDiet) {
              setState(() {
                _selectedSavedDietFilter =
                    selectedDiet; // Set state halaman induk saat dropdown berubah
              });
            },
            onTapCard:
                _showRecipeDetail, // 🔥 PERBAIKAN: Diubah dari _navigateToDetail menjadi _showRecipeDetail
            onToggleFavorite: _toggleFavoriteRecipe,
          ),
        ),
      ],
    );
  }
}
