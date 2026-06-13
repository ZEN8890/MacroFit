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
import '../services/storage_services.dart';
import '../utils/notification_helper.dart';
import '../utils/global_state.dart';

// Impor komponen modular baru kita
import '../widgets/recipe_ai_tab.dart';
import '../widgets/recipe_saved_tab.dart';
import '../widgets/recipe_upload_overlay.dart';

class RecipePage extends StatefulWidget {
  const RecipePage({super.key});

  @override
  State<RecipePage> createState() => _RecipePageState();
}

class _RecipePageState extends State<RecipePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isUploadingRecipe = false;
  bool _isGeneratingAI = false;
  int _remainingCounter = 2;

  String _selectedCommunityDietFilter = 'All';
  String _selectedPublishedDietFilter = 'All';
  String _selectedSavedDietFilter = 'All';

  String get currentUserId => _auth.currentUser?.uid ?? '';
  String _refreshTriggerKey = DateTime.now().millisecondsSinceEpoch.toString();

  final List<String> _dietOptions = [
    'Menurunkan Berat Badan',
    'gain_muscle',
    'healthy_lifestyle',
    'keto_diet',
    'vegetarian',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeRecipeData();
    });
  }

  Future<void> _initializeRecipeData() async {
    final aiRecipes = await _firestore
        .collection('recipes')
        .where('type', isEqualTo: 'AI')
        .limit(1)
        .get();

    if (aiRecipes.docs.isEmpty) {
      await _generateAIRecipe(isAutoRefresh: true);
    }
    await _checkDailyRefreshAndCounter();
  }

  Future<void> _checkDailyRefreshAndCounter() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      final String todayDate =
          "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

      final String? lastRefreshDate = prefs.getString('last_ai_recipe_refresh');
      final int? savedCounter = prefs.getInt('ai_recipe_click_counter');

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
        Notify.error(
          context,
          isEnglishNotifier.value
              ? 'Daily generation limit reached!'
              : 'Batas limit harian habis!',
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
      String dietCode = 'healthy_lifestyle';

      if (userDoc.exists && userDoc.data() != null) {
        final userData = userDoc.data() as Map<String, dynamic>;
        targetCalorie = (userData['target_calories'] ?? 2000.0).toDouble();
        dietCode = userData['diet_code'] ?? 'healthy_lifestyle';
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

      String targetLanguageInstruction = isEnglishNotifier.value
          ? "Strictly generate the entire recipe response (title, ingredients, instructions, and suitable_diet value description) in English language. For suitable_diet key, use raw exact value from the options list below, but ensure any descriptive textual data is English."
          : "Tolong generate seluruh respon resep ini (termasuk judul, bahan-bahan, langkah memasak) dalam Bahasa Indonesia secara konsisten.";

      final prompt =
          '''
      Anda adalah Chef Gizi Profesional untuk aplikasi MacroFit.
      Tugas Anda adalah merancang TEPAT 3 rekomendasi resep makanan sehat yang berbeda, unik, bervariasi, dan sangat kreatif agar pengguna tidak bosan.
      Seluruh resep harus disesuaikan secara ilmiah untuk profil diet berikut:
      - Tipe Program Diet: $dietCode
      - Target Kalori Harian Pengguna: $targetCalorie kkal

      $targetLanguageInstruction

      Berikan output HARUS dalam format JSON Array murni yang berisi TEPAT 3 objek resep. Jangan berikan teks penjelasan atau tanda markdown luar apa pun di luar JSON Array. Pastikan response selesai ditulis penuh dan tidak terputus di tengah jalan.
      
      ⚠️ ATURAN SANGAT KETAT UNTUK KATEGORI DIET:
      1. Untuk properti "suitable_diet", Anda HARUS memilih salah satu nilai yang tepat dari daftar resmi berikut: ${_dietOptions.join(', ')}. Sesuaikan dengan program diet pengguna saat ini ($dietCode).
      2. Untuk properti "unsuitable_diet", pilih satu nilai dari daftar di atas yang paling tidak cocok sebagai pantangan makanan tersebut, atau berikan nilai "None" jika aman untuk semua diet.
      3. TAMBAHKAN PROPERTI "image_keyword": Pilih 1 hingga 2 kata kunci pencarian gambar makanan dalam bahasa Inggris yang paling akurat menggambarkan hidangan ini (Contoh: "avocado_omelette", "berry_oatmeal", "chicken_breast_salad").
      
      Pastikan semua huruf pada key (kunci) menggunakan HURUF KECIL SEMUA seperti contoh berikut:
      [
        {
          "title": "${isEnglishNotifier.value ? 'Honey Lemon Grilled Chicken' : 'Ayam Panggang Lemon Madu'}",
          "calories": 350,
          "ingredients": ${isEnglishNotifier.value ? '["100g Chicken Breast", "1 tbsp Honey", "Lemon Juice"]' : '["100g Dada Ayam", "1 sdm Madu", "Perasan Lemon"]'},
          "instructions": ${isEnglishNotifier.value ? '["Marinate chicken with lemon and honey", "Grill until cooked for 20 minutes"]' : '["Marinasi ayam dengan lemon dan madu", "Panggang hingga matang 20 menit"]'},
          "suitable_diet": "$dietCode",
          "unsuitable_diet": "None",
          "image_keyword": "grilled_lemon_chicken"
        }
      ]
      ''';

      final response = await model.generateContent([Content.text(prompt)]);

      if (response.text != null && response.text!.isNotEmpty) {
        String cleanedText = response.text!.trim();
        if (cleanedText.startsWith('```')) {
          cleanedText = cleanedText
              .replaceAll('```json', '')
              .replaceAll('```', '')
              .trim();
        }

        try {
          final List<dynamic> aiRecipesList = json.decode(cleanedText);
          final batchInsert = _firestore.batch();

          for (var recipe in aiRecipesList) {
            final docRef = _firestore.collection('recipes').doc();

            String aiSuitable = recipe['suitable_diet'] ?? dietCode;
            String aiUnsuitable = recipe['unsuitable_diet'] ?? 'None';

            if (!_dietOptions.contains(aiSuitable)) aiSuitable = dietCode;
            if (aiUnsuitable != 'None' &&
                !_dietOptions.contains(aiUnsuitable)) {
              aiUnsuitable = 'None';
            }

            batchInsert.set(docRef, {
              'title':
                  recipe['title'] ??
                  (isEnglishNotifier.value
                      ? 'AI Healthy Culinary Recipe'
                      : 'Resep Kuliner Sehat AI'),
              'calories': recipe['calories'] ?? 0,
              'image_url': null,
              'image_keyword': recipe['image_keyword'] ?? 'healthy_food',
              'full_name': 'MacroFit AI',
              'type': 'AI',
              'ingredients': recipe['ingredients'] ?? [],
              'instructions': recipe['instructions'] ?? [],
              'timestamp': FieldValue.serverTimestamp(),
              'savedBy': [],
              'suitable_diet': aiSuitable,
              'unsuitable_diet': aiUnsuitable,
            });
          }
          await batchInsert.commit();

          if (!isAutoRefresh) {
            final prefs = await SharedPreferences.getInstance();
            if (mounted) {
              setState(() {
                _remainingCounter--;
                _refreshTriggerKey = DateTime.now().millisecondsSinceEpoch
                    .toString();
              });
            }
            await prefs.setInt('ai_recipe_click_counter', _remainingCounter);
          }
        } catch (jsonError) {
          debugPrint("Gagal mengurai JSON dari AI: $jsonError");
          if (mounted) {
            Notify.error(
              context,
              isEnglishNotifier.value
                  ? 'AI formatting error. Please try again.'
                  : 'Struktur resep AI tidak valid. Silakan coba lagi.',
            );
          }
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

  void _showEditRecipeDialog(Map<String, dynamic> recipeData, String docId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => AddRecipeSheet(
        dietOptions: _dietOptions,
        initialTitle: recipeData['title'],
        initialCalories: recipeData['calories']?.toString(),
        initialIngredients: List<String>.from(recipeData['ingredients'] ?? []),
        initialInstructions: List<String>.from(
          recipeData['instructions'] ?? [],
        ),
        initialSuitable: recipeData['suitable_diet'],
        initialUnsuitable: recipeData['unsuitable_diet'],
        isEditing: true,
        onPublish:
            (
              title,
              calories,
              ingredients,
              instructions,
              suitable,
              unsuitable,
              images,
            ) async {
              await _firestore.collection('recipes').doc(docId).update({
                'title': title,
                'calories': calories,
                'ingredients': ingredients,
                'instructions': instructions,
                'suitable_diet': suitable,
                'unsuitable_diet': unsuitable,
                'is_edited': true,
                'last_update': FieldValue.serverTimestamp(),
              });

              if (mounted) {
                Notify.success(
                  context,
                  isEnglishNotifier.value
                      ? 'Recipe updated successfully!'
                      : 'Resep berhasil diperbarui!',
                );
              }
            },
      ),
    );
  }

  void _showRecipeDetail(Map<String, dynamic> recipeData, String docId) {
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
        currentUserId: currentUserId,
        onToggleFavorite: _toggleFavoriteRecipe,
        onDeleteRecipe: () async {
          await _firestore.collection('recipes').doc(docId).delete();
          if (mounted) {
            Notify.success(
              context,
              isEnglishNotifier.value
                  ? 'Recipe deleted permanently.'
                  : 'Resep berhasil dihapus permanen.',
            );
          }
        },
      ),
    ).then((result) {
      if (result == true && recipeData['userId'] == currentUserId) {
        Future.delayed(const Duration(milliseconds: 150), () {
          if (mounted) {
            _showEditRecipeDialog(recipeData, docId);
          }
        });
      }
    });
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
              suitable,
              unsuitable,
              images,
            ) async {
              setState(() {
                _isUploadingRecipe = true;
              });

              final uDoc = await _firestore
                  .collection('users')
                  .doc(currentUserId)
                  .get();
              String full_name = uDoc.data()?['full_name'] ?? 'User';
              List<String> uploadedUrls = [];

              try {
                if (images.isNotEmpty) {
                  final storageService = StorageService();
                  for (var imgFile in images) {
                    try {
                      String downloadUrl = await storageService.uploadImage(
                        imgFile,
                        'recipes',
                      );
                      uploadedUrls.add(downloadUrl);
                    } catch (e) {
                      debugPrint("Gagal mengunggah gambar resep: $e");
                    }
                  }
                }

                await _firestore.collection('recipes').add({
                  'title': title,
                  'calories': calories,
                  'image_url': uploadedUrls.isNotEmpty
                      ? uploadedUrls.first
                      : null,
                  'image_urls': uploadedUrls,
                  'full_name': full_name,
                  'username': uDoc.data()?['username'] ?? '',
                  'type': 'Community',
                  'userId': currentUserId,
                  'ingredients': ingredients,
                  'instructions': instructions,
                  'timestamp': FieldValue.serverTimestamp(),
                  'savedBy': [],
                  'suitable_diet': suitable,
                  'unsuitable_diet': unsuitable,
                });

                if (mounted) {
                  Notify.success(
                    context,
                    isEnglishNotifier.value
                        ? 'Recipe published successfully!'
                        : 'Resep berhasil dipublikasikan!',
                  );
                }
              } catch (e) {
                debugPrint("Error publishing recipe: $e");
              } finally {
                if (mounted) {
                  setState(() {
                    _isUploadingRecipe = false;
                  });
                }
              }
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
          Notify.error(
            context,
            isEnglishNotifier.value
                ? 'Save limit reached (Max 50 recipes).'
                : 'Batas simpan penuh (Maks. 50 resep).',
          );
        }
        return;
      }

      if (recipeType == 'AI') {
        await _firestore.collection('recipes').add({
          'title': recipeData['title'],
          'calories': recipeData['calories'],
          'image_url': recipeData['image_url'],
          'full_name': recipeData['full_name'],
          'type': 'Favorites',
          'origin_type': 'AI',
          'userId': currentUserId,
          'ingredients': recipeData['ingredients'],
          'instructions': recipeData['instructions'],
          'timestamp': FieldValue.serverTimestamp(),
          'savedBy': [currentUserId],
          'suitable_diet': recipeData['suitable_diet'] ?? 'healthy_lifestyle',
          'unsuitable_diet': recipeData['unsuitable_diet'] ?? 'None',
        });

        await docRef.update({
          'savedBy': FieldValue.arrayUnion([currentUserId]),
        });

        if (mounted) {
          Notify.success(
            context,
            isEnglishNotifier.value
                ? 'AI Recipe saved successfully!'
                : 'Resep AI berhasil disimpan!',
          );
        }
      } else {
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

    return ValueListenableBuilder<bool>(
      valueListenable: isEnglishNotifier,
      builder: (context, englishActive, child) {
        return DefaultTabController(
          length: 4,
          child: Stack(
            children: [
              Scaffold(
                appBar: AppBar(
                  title: Text(
                    englishActive ? "MacroFit Recipes" : "Resep MacroFit",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  backgroundColor: theme.appBarTheme.backgroundColor,
                  foregroundColor: theme.appBarTheme.foregroundColor,
                  elevation: 0,
                  bottom: TabBar(
                    isScrollable: false,
                    labelColor: theme.primaryColor,
                    unselectedLabelColor: isDarkMode
                        ? Colors.white38
                        : Colors.black38,
                    indicatorColor: theme.primaryColor,
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelPadding: const EdgeInsets.symmetric(horizontal: 2.0),
                    labelStyle: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                    unselectedLabelStyle: const TextStyle(fontSize: 11),
                    tabs: [
                      const Tab(
                        icon: Icon(Icons.psychology_outlined, size: 20),
                        text: 'AI',
                      ),
                      Tab(
                        icon: const Icon(Icons.people_outline, size: 20),
                        text: englishActive ? 'Community' : 'Komunitas',
                      ),
                      Tab(
                        icon: const Icon(
                          Icons.assignment_ind_outlined,
                          size: 20,
                        ),
                        text: englishActive ? 'Published' : 'Terbitan',
                      ),
                      Tab(
                        icon: const Icon(Icons.bookmark_border, size: 20),
                        text: englishActive ? 'Saved' : 'Tersimpan',
                      ),
                    ],
                  ),
                ),
                backgroundColor: theme.scaffoldBackgroundColor,
                body: TabBarView(
                  children: [
                    // 🟢 TAB 1 (MODULARIZED): Memanggil widget RecipeAITab
                    RefreshIndicator(
                      color: theme.primaryColor,
                      onRefresh: () async {
                        setState(() {
                          _refreshTriggerKey = DateTime.now()
                              .millisecondsSinceEpoch
                              .toString();
                        });
                      },
                      child: RecipeAITab(
                        remainingCounter: _remainingCounter,
                        isGeneratingAI: _isGeneratingAI,
                        currentUserId: currentUserId,
                        refreshTriggerKey: _refreshTriggerKey,
                        onGeneratePressed: () =>
                            _generateAIRecipe(isAutoRefresh: false),
                        onTapCard: _showRecipeDetail,
                        onToggleFavorite: _toggleFavoriteRecipe,
                      ),
                    ),

                    // TAB COMMUNITY
                    RefreshIndicator(
                      color: theme.primaryColor,
                      onRefresh: () async {
                        setState(() {
                          _refreshTriggerKey = DateTime.now()
                              .millisecondsSinceEpoch
                              .toString();
                        });
                      },
                      child: RecipeStreamView(
                        key: ValueKey(
                          'stream_community_${_selectedCommunityDietFilter}_$_refreshTriggerKey',
                        ),
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
                    ),

                    // TAB PUBLISHED
                    RefreshIndicator(
                      color: theme.primaryColor,
                      onRefresh: () async {
                        setState(() {
                          _refreshTriggerKey = DateTime.now()
                              .millisecondsSinceEpoch
                              .toString();
                        });
                      },
                      child: RecipeStreamView(
                        key: ValueKey(
                          'stream_published_${_selectedPublishedDietFilter}_$_refreshTriggerKey',
                        ),
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
                    ),

                    // 🟢 TAB 4 (MODULARIZED): Memanggil widget RecipeSavedTab
                    RefreshIndicator(
                      color: theme.primaryColor,
                      onRefresh: () async {
                        setState(() {
                          _refreshTriggerKey = DateTime.now()
                              .millisecondsSinceEpoch
                              .toString();
                        });
                      },
                      child: RecipeSavedTab(
                        selectedSavedDietFilter: _selectedSavedDietFilter,
                        dietOptions: _dietOptions,
                        currentUserId: currentUserId,
                        refreshTriggerKey: _refreshTriggerKey,
                        firestore: _firestore,
                        onFilterChanged: (newValue) {
                          setState(() {
                            _selectedSavedDietFilter = newValue;
                          });
                        },
                        onTapCard: _showRecipeDetail,
                        onToggleFavorite: _toggleFavoriteRecipe,
                      ),
                    ),
                  ],
                ),
                floatingActionButton: _isUploadingRecipe
                    ? FloatingActionButton(
                        onPressed: null,
                        backgroundColor: Colors.grey.shade400,
                        child: const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      )
                    : FloatingActionButton.extended(
                        onPressed: _showAddRecipeDialog,
                        backgroundColor: theme.primaryColor,
                        foregroundColor: Colors.white,
                        icon: const Icon(Icons.add),
                        label: Text(
                          englishActive ? 'Publish Recipe' : 'Bagikan Resep',
                        ),
                      ),
              ),

              // 🟢 DIALOG OVERLAY (MODULARIZED): Memanggil widget RecipeUploadOverlay
              if (_isUploadingRecipe)
                RecipeUploadOverlay(isDarkMode: isDarkMode, theme: theme),
            ],
          ),
        );
      },
    );
  }
}
