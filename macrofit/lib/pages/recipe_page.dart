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
import '../utils/global_state.dart'; // 🟢 IMPORT SAKLAR GLOBAL STATE

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

      // SINKRONISASI BAHASA PROMPT AI
      String targetLanguageInstruction = isEnglishNotifier.value
          ? "Strictly generate the entire recipe response (title, ingredients, instructions, and suitable_diet value description) in English language. For suitable_diet key, use raw exact value from the options list below, but ensure any descriptive textual data is English."
          : "Tolong generate seluruh respon resep ini (termasuk judul, bahan-bahan, langkah memasak) dalam Bahasa Indonesia secara konsisten.";

      // 🟢 OPTIMASI PROMPT: Menurunkan target menjadi TEPAT 3 resep agar token tidak overload & JSON tidak terputus
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
        // 🟢 PROSES SANITASI STRING: Membersihkan response teks dari white-space dan tag markdown liar
        String cleanedText = response.text!.trim();
        if (cleanedText.startsWith('```')) {
          cleanedText = cleanedText
              .replaceAll('```json', '')
              .replaceAll('```', '')
              .trim();
        }

        // 🟢 TRY-CATCH PARSING LEVEL: Mengisolasi json.decode agar kegagalan parsing tidak membuat aplikasi crash
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
              'username': 'MacroFit AI',
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
          // Menangani kesalahan struktur JSON secara aman & informatif
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
      isScrollControlled:
          true, // 🟢 WAJIB TRUE agar sheet bisa naik penuh saat keyboard muncul
      useSafeArea:
          true, // 🟢 TAMBAHKAN INI agar insets keyboard terbaca dengan baik
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
              String username = uDoc.data()?['username'] ?? 'User';
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
                  'username': username,
                  'username_handle': uDoc.data()?['username_handle'] ?? '',
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
          'username': recipeData['username'],
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

  Widget _buildAITabView(bool isEnglish) {
    final theme = Theme.of(context);

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
                    Text(
                      isEnglish
                          ? "Bored with Old Menus?"
                          : "Bosan dengan Menu Lama?",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isEnglish
                          ? "Ask AI to craft instant recipes! (Left Today: $_remainingCounter/2)"
                          : "Minta AI buatkan resep instan! (Sisa Hari Ini: $_remainingCounter/2)",
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
              // Kondisi Loading Indicator saat AI sedang bekerja
              _isGeneratingAI
                  ? const CircularProgressIndicator(strokeWidth: 3)
                  : SizedBox(
                      width: 130,
                      height: 38,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          // 🟢 WARNA DINAMIS: Berubah jadi abu-abu jika sisa counter habis
                          backgroundColor: _remainingCounter <= 0
                              ? Colors.grey.shade400
                              : theme.primaryColor,
                          foregroundColor: _remainingCounter <= 0
                              ? Colors.grey.shade600
                              : Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 0,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          elevation: _remainingCounter <= 0 ? 0 : 2,
                        ),
                        icon: Icon(
                          Icons.bolt,
                          color: _remainingCounter <= 0
                              ? Colors.grey.shade600
                              : Colors.amber,
                          size: 16,
                        ),
                        label: Text(
                          isEnglish ? "Generate AI" : "Generate AI",
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        // 🟢 FIX UTAMA: Validasi limit harian dievaluasi langsung di dalam fungsi onPressed
                        onPressed: () {
                          if (_remainingCounter <= 0) {
                            Notify.error(
                              context,
                              isEnglish
                                  ? 'Daily generation limit reached!'
                                  : 'Batas limit harian habis!',
                            );
                            return;
                          }
                          // Jika lolos validasi harian, jalankan generator resep sehat Gemini AI
                          _generateAIRecipe(isAutoRefresh: false);
                        },
                      ),
                    ),
            ],
          ),
        ),
        Expanded(
          child: RecipeStreamView(
            key: ValueKey('stream_ai_tab_$_refreshTriggerKey'),
            filterType: 'AI',
            currentUserId: currentUserId,
            firestore: _firestore,
            onTapCard: _showRecipeDetail,
            onToggleFavorite: _toggleFavoriteRecipe,
          ),
        ),
      ],
    );
  }

  Widget _buildSavedTabView(bool isEnglish) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: theme.primaryColor.withOpacity(0.03),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.filter_list, size: 18, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    isEnglish ? "Filter Category:" : "Saring Kategori:",
                    style: const TextStyle(
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
                  String displayLabel = value;
                  if (value == 'All') {
                    displayLabel = isEnglish
                        ? 'All Diet Categories'
                        : 'Semua Kategori Diet';
                  }
                  if (value == 'Menurunkan Berat Badan') {
                    displayLabel = isEnglish
                        ? 'Lose Weight'
                        : 'Menurunkan Berat Badan';
                  }
                  if (value == 'gain_muscle') {
                    displayLabel = isEnglish
                        ? 'Gain Muscle'
                        : 'Menaikkan Massa Otot';
                  }
                  if (value == 'healthy_lifestyle') {
                    displayLabel = isEnglish
                        ? 'Healthy Lifestyle'
                        : 'Gaya Hidup Sehat';
                  }
                  if (value == 'keto_diet') {
                    displayLabel = isEnglish ? 'Keto Diet' : 'Diet Keto';
                  }
                  if (value == 'vegetarian') {
                    displayLabel = isEnglish ? 'Vegetarian' : 'Vegetarian';
                  }

                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(displayLabel),
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
        Expanded(
          child: RecipeStreamView(
            key: ValueKey(
              'stream_favorites_${_selectedSavedDietFilter}_$_refreshTriggerKey',
            ),
            filterType: 'Favorites',
            currentUserId: currentUserId,
            firestore: _firestore,
            savedDietFilter: _selectedSavedDietFilter,
            onDietFilterChanged: (selectedDiet) {
              setState(() {
                _selectedSavedDietFilter = selectedDiet;
              });
            },
            onTapCard: _showRecipeDetail,
            onToggleFavorite: _toggleFavoriteRecipe,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    // 🟢 REAKTIF MULTI-BAHASA: Membungkus seluruh halaman tab bar kustom dengan ValueListenableBuilder
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
                    RefreshIndicator(
                      color: theme.primaryColor,
                      onRefresh: () async {
                        await Future.delayed(const Duration(milliseconds: 800));
                        setState(() {
                          _refreshTriggerKey = DateTime.now()
                              .millisecondsSinceEpoch
                              .toString();
                        });
                      },
                      child: _buildAITabView(englishActive),
                    ),

                    // TAB COMMUNITY
                    RefreshIndicator(
                      color: theme.primaryColor,
                      onRefresh: () async {
                        await Future.delayed(const Duration(milliseconds: 800));
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
                        onTapCard: (recipeData, docId) =>
                            _showRecipeDetail(recipeData, docId),
                        onToggleFavorite: _toggleFavoriteRecipe,
                      ),
                    ),

                    // TAB PUBLISHED
                    RefreshIndicator(
                      color: theme.primaryColor,
                      onRefresh: () async {
                        await Future.delayed(const Duration(milliseconds: 800));
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
                        onTapCard: (recipeData, docId) =>
                            _showRecipeDetail(recipeData, docId),
                        onToggleFavorite: _toggleFavoriteRecipe,
                      ),
                    ),

                    // TAB SAVED
                    RefreshIndicator(
                      color: theme.primaryColor,
                      onRefresh: () async {
                        await Future.delayed(const Duration(milliseconds: 800));
                        setState(() {
                          _refreshTriggerKey = DateTime.now()
                              .millisecondsSinceEpoch
                              .toString();
                        });
                      },
                      child: _buildSavedTabView(englishActive),
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

              if (_isUploadingRecipe)
                Container(
                  color: Colors.black.withOpacity(0.35),
                  width: double.infinity,
                  height: double.infinity,
                  child: Center(
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      color: isDarkMode ? Colors.grey.shade900 : Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 28.0,
                          vertical: 24.0,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                theme.primaryColor,
                              ),
                            ),
                            const SizedBox(height: 18),
                            Text(
                              englishActive
                                  ? "Uploading recipe creation..."
                                  : "Mengunggah kreasi resep...",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: isDarkMode
                                    ? Colors.white
                                    : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              englishActive
                                  ? "Please wait until the media is successfully posted"
                                  : "Mohon tunggu hingga media sukses diposting",
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
