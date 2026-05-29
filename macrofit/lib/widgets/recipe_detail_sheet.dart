import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/notification_helper.dart';
import '../utils/global_state.dart';

class RecipeDetailSheet extends StatefulWidget {
  final Map<String, dynamic> recipeData;
  final String docId;
  final String currentUserId;
  final Future<void> Function(String, List<dynamic>) onToggleFavorite;
  final VoidCallback onDeleteRecipe;

  const RecipeDetailSheet({
    super.key,
    required this.recipeData,
    required this.docId,
    required this.currentUserId,
    required this.onToggleFavorite,
    required this.onDeleteRecipe,
  });

  @override
  State<RecipeDetailSheet> createState() => _RecipeDetailSheetState();
}

class _RecipeDetailSheetState extends State<RecipeDetailSheet> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  int _selectedRating = 0;
  bool _isSubmitting = false;
  final TextEditingController _commentController = TextEditingController();
  int _filterRating = 0;
  bool _isEditMode = false;
  String? _myExistingReviewId;

  // Inisialisasi awal menggunakan Map kosong untuk mencegah LateInitializationError
  Map<String, dynamic> _currentRecipeMap = {};

  @override
  void initState() {
    super.initState();
    _currentRecipeMap = widget.recipeData;
    _listenToRecipeChanges();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  // Background stream listener untuk memantau perubahan data resep
  void _listenToRecipeChanges() {
    _firestore.collection('recipes').doc(widget.docId).snapshots().listen((
      snapshot,
    ) {
      if (snapshot.exists && mounted) {
        setState(() {
          _currentRecipeMap = snapshot.data() as Map<String, dynamic>;
        });
      }
    });
  }

  // Helper format timestamp ke teks manusia
  String _formatTimestamp(dynamic timestamp, bool isEnglish) {
    if (timestamp == null) return isEnglish ? 'Just now' : 'Baru saja';
    if (timestamp is Timestamp) {
      DateTime dt = timestamp.toDate();
      List<String> monthsID = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'Mei',
        'Jun',
        'Jul',
        'Agu',
        'Sep',
        'Okt',
        'Nov',
        'Des',
      ];
      List<String> monthsEN = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];

      String month = isEnglish
          ? monthsEN[dt.month - 1]
          : monthsID[dt.month - 1];
      return "${dt.day} $month ${dt.year}";
    }
    return '';
  }

  // Fungsi Kirim Ulasan Baru
  Future<void> _submitComment() async {
    final bool isEnglish = isEnglishNotifier.value;
    if (_selectedRating == 0) {
      Notify.error(
        context,
        isEnglish
            ? 'Please select a star rating first.'
            : '⚠️ Silakan pilih rating bintang terlebih dahulu.',
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final userDoc = await _firestore
          .collection('users')
          .doc(widget.currentUserId)
          .get();
      final userData = userDoc.data() as Map<String, dynamic>;
      final String text = _commentController.text.trim();

      await _firestore.collection('recipe_comments').add({
        'recipeId': widget.docId,
        'userId': widget.currentUserId,
        'username': userData['username'] ?? 'User',
        'username_handle': userData['username_handle'] ?? 'user',
        'userProfilePic': userData['profile_picture'] ?? '',
        'commentText': text,
        'rating': _selectedRating,
        'is_edited': false,
        'timestamp': FieldValue.serverTimestamp(),
      });

      _commentController.clear();
      setState(() {
        _selectedRating = 0;
        _isSubmitting = false;
      });
      Notify.success(
        context,
        isEnglish ? "Review posted!" : "Ulasan berhasil dikirim!",
      );
    } catch (e) {
      setState(() => _isSubmitting = false);
      Notify.error(
        context,
        isEnglish ? "Failed to process review." : "Gagal memproses ulasan.",
      );
    }
  }

  void _showEditReviewDialog(
    BuildContext context,
    Map<String, dynamic> currentReviewData,
    String reviewId,
    bool isEnglish,
  ) {
    int localEditRating = currentReviewData['rating'] ?? 5;
    final TextEditingController localEditController = TextEditingController(
      text: currentReviewData['commentText'] ?? '',
    );

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final theme = Theme.of(context);
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(
                isEnglish ? 'Edit Your Review' : 'Edit Ulasan Anda',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: List.generate(5, (index) {
                        return IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () {
                            setDialogState(() {
                              localEditRating = index + 1;
                            });
                          },
                          icon: Icon(
                            index < localEditRating
                                ? Icons.star
                                : Icons.star_border,
                            color: Colors.amber,
                            size: 32,
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: localEditController,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        hintText: isEnglish
                            ? 'Edit comment...'
                            : 'Ubah komentar...',
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    isEnglish ? 'Cancel' : 'Batal',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    Navigator.pop(context);
                    try {
                      await _firestore
                          .collection('recipe_comments')
                          .doc(reviewId)
                          .update({
                            'rating': localEditRating,
                            'commentText': localEditController.text.trim(),
                            'is_edited': true,
                            'timestamp': FieldValue.serverTimestamp(),
                          });
                      Notify.success(
                        context,
                        isEnglish ? "Review updated!" : "Ulasan diperbarui!",
                      );
                    } catch (e) {
                      Notify.error(
                        context,
                        isEnglish
                            ? "Failed to update."
                            : "Gagal memperbarui ulasan.",
                      );
                    }
                  },
                  child: Text(isEnglish ? 'Save' : 'Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isEnglishNotifier,
      builder: (context, englishActive, child) {
        final List<dynamic> ingredients =
            _currentRecipeMap['ingredients'] ?? [];
        final List<dynamic> steps =
            _currentRecipeMap['instructions'] ??
            _currentRecipeMap['steps'] ??
            [];
        final List<dynamic> savedByList = _currentRecipeMap['savedBy'] ?? [];

        final bool isAuthor =
            _currentRecipeMap['userId'] == widget.currentUserId;
        final bool isEditLocked = savedByList.length >= 1;

        // 🟢 ATURAN BARU: Cek apakah resep ini tipe AI Generated
        final bool isAiRecipe = _currentRecipeMap['type'] == 'AI';

        String recipeUsername =
            _currentRecipeMap['username_handle'] != null &&
                _currentRecipeMap['username_handle'].toString().isNotEmpty
            ? _currentRecipeMap['username_handle']
            : (_currentRecipeMap['username'] ?? 'anonim');

        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            final theme = Theme.of(context);

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: SingleChildScrollView(
                controller: scrollController,
                // 🟢 FIX KEYBOARD: Tambahkan padding bottom otomatis mengikuti tinggi keyboard yang aktif
                padding: EdgeInsets.only(
                  left: 24,
                  right: 24,
                  top: 24,
                  bottom: 24 + MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // JUDUL RESEP
                    Text(
                      _currentRecipeMap['title'] ?? 'Recipe',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      englishActive
                          ? 'By: @$recipeUsername'
                          : 'Oleh: @$recipeUsername',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: theme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _currentRecipeMap['description'] ?? '',
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 12),

                    // BUTTONS ACTION AUTHOR VALIDATION (Hanya untuk resep non-AI)
                    if (isAuthor && !isAiRecipe) ...[
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isEditLocked
                                    ? Colors.grey.shade300
                                    : theme.primaryColor,
                                foregroundColor: isEditLocked
                                    ? Colors.grey.shade600
                                    : Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              icon: const Icon(Icons.edit, size: 16),
                              label: Text(
                                isEditLocked
                                    ? (englishActive
                                          ? 'Edit Locked'
                                          : 'Edit Terkunci')
                                    : (englishActive
                                          ? 'Edit Recipe'
                                          : 'Edit Resep'),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              onPressed: isEditLocked
                                  ? () {
                                      Notify.error(
                                        context,
                                        englishActive
                                            ? 'Cannot edit re-saved recipes by others.'
                                            : 'Resep tidak bisa diedit karena telah disimpan oleh pengguna lain.',
                                      );
                                    }
                                  : () => Navigator.pop(context, true),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.redAccent.withOpacity(
                                  0.1,
                                ),
                                foregroundColor: Colors.redAccent,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              icon: const Icon(Icons.delete_forever, size: 16),
                              label: Text(
                                englishActive ? 'Delete' : 'Hapus Resep',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: Text(
                                      englishActive
                                          ? 'Delete Recipe?'
                                          : 'Hapus Resep?',
                                    ),
                                    content: Text(
                                      englishActive
                                          ? 'This action cannot be undone.'
                                          : 'Apakah Anda yakin ingin menghapus resep ini secara permanen?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx),
                                        child: Text(
                                          englishActive ? 'Cancel' : 'Batal',
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(ctx);
                                          Navigator.pop(context);
                                          widget.onDeleteRecipe();
                                        },
                                        child: const Text(
                                          'Hapus',
                                          style: TextStyle(
                                            color: Colors.redAccent,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      if (isEditLocked) ...[
                        const SizedBox(height: 4),
                        Text(
                          englishActive
                              ? " *Locked because this recipe has been saved by other community members."
                              : " *Tombol edit dikunci karena resep ini sudah disimpan oleh anggota komunitas lain.",
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                    ],
                    const Divider(height: 32),

                    // BAHAN-BAHAN
                    Text(
                      englishActive ? 'Ingredients:' : 'Bahan-bahan:',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ingredients.isEmpty
                        ? const Text(
                            'Tidak ada bahan terdaftar.',
                            style: TextStyle(color: Colors.grey),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: ingredients.length,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4.0,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "• ",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        ingredients[index].toString(),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                    const Divider(height: 32),

                    // LANGKAH MEMASAK
                    Text(
                      englishActive ? 'Instructions:' : 'Langkah Memasak:',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    steps.isEmpty
                        ? const Text(
                            'Tidak ada langkah terdaftar.',
                            style: TextStyle(color: Colors.grey),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: steps.length,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 6.0,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "${index + 1}. ",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(steps[index].toString()),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),

                    // 🟢 KONDISI JITU: Jika Resep bertipe AI, hentikan render seksi review ke bawah
                    if (!isAiRecipe) ...[
                      const Divider(height: 32),

                      // SEKSI ULASAN KOMUNITAS ALA GOOGLE MAPS
                      StreamBuilder<QuerySnapshot>(
                        stream: _firestore
                            .collection('recipe_comments')
                            .where('recipeId', isEqualTo: widget.docId)
                            .orderBy('timestamp', descending: true)
                            .snapshots(),
                        builder: (context, commentSnapshot) {
                          if (!commentSnapshot.hasData) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          final rawDocs = commentSnapshot.data!.docs;

                          DocumentSnapshot? myReviewDoc;
                          for (var doc in rawDocs) {
                            final d = doc.data() as Map<String, dynamic>;
                            if (d['userId'] == widget.currentUserId) {
                              myReviewDoc = doc;
                              break;
                            }
                          }

                          _myExistingReviewId = myReviewDoc?.id;
                          _isEditMode = myReviewDoc != null;

                          return StatefulBuilder(
                            builder: (context, setReviewState) {
                              final docs = rawDocs.where((doc) {
                                final d = doc.data() as Map<String, dynamic>;
                                if (_filterRating == 0) return true;
                                return (d['rating'] ?? 0) == _filterRating;
                              }).toList();

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    englishActive
                                        ? 'Community Reviews'
                                        : 'Ulasan Komunitas',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 12),

                                  // Filter Chips Google Maps Style
                                  SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    physics: const BouncingScrollPhysics(),
                                    child: Row(
                                      children: [0, 5, 4, 3, 2, 1].map((
                                        ratingValue,
                                      ) {
                                        final bool isSelected =
                                            _filterRating == ratingValue;
                                        return Padding(
                                          padding: const EdgeInsets.only(
                                            right: 8.0,
                                          ),
                                          child: ChoiceChip(
                                            label: Text(
                                              ratingValue == 0
                                                  ? (englishActive
                                                        ? "All Reviews"
                                                        : "Semua Ulasan")
                                                  : "$ratingValue ⭐",
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: isSelected
                                                    ? Colors.white
                                                    : theme.primaryColor,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            selected: isSelected,
                                            selectedColor: theme.primaryColor,
                                            backgroundColor: theme.primaryColor
                                                .withOpacity(0.06),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            showCheckmark: false,
                                            onSelected: (bool selected) {
                                              setReviewState(() {
                                                _filterRating = ratingValue;
                                              });
                                            },
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                  const SizedBox(height: 12),

                                  // List Review Box (Scrollable Mandiri)
                                  Container(
                                    constraints: const BoxConstraints(
                                      maxHeight: 220,
                                    ),
                                    decoration: BoxDecoration(
                                      color: theme.disabledColor.withOpacity(
                                        0.03,
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: docs.isEmpty
                                        ? Padding(
                                            padding: const EdgeInsets.all(16.0),
                                            child: Text(
                                              englishActive
                                                  ? 'No reviews found.'
                                                  : 'Belum ada ulasan untuk rating ini.',
                                              style: const TextStyle(
                                                color: Colors.grey,
                                                fontSize: 13,
                                              ),
                                            ),
                                          )
                                        : ListView.separated(
                                            shrinkWrap: true,
                                            physics:
                                                const BouncingScrollPhysics(),
                                            padding: const EdgeInsets.all(12),
                                            itemCount: docs.length,
                                            separatorBuilder:
                                                (context, index) =>
                                                    const Divider(
                                                      height: 16,
                                                      color: Colors.black12,
                                                    ),
                                            itemBuilder: (context, i) {
                                              final d =
                                                  docs[i].data()
                                                      as Map<String, dynamic>;
                                              final String text =
                                                  (d['commentText'] ?? '')
                                                      .toString()
                                                      .trim();
                                              final bool isMyOwn =
                                                  d['userId'] ==
                                                  widget.currentUserId;
                                              final bool isEdited =
                                                  d['is_edited'] ?? false;

                                              return Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      CircleAvatar(
                                                        radius: 16,
                                                        backgroundImage:
                                                            d['userProfilePic'] !=
                                                                    null &&
                                                                d['userProfilePic']
                                                                    .toString()
                                                                    .isNotEmpty
                                                            ? NetworkImage(
                                                                d['userProfilePic'],
                                                              )
                                                            : null,
                                                        child:
                                                            d['userProfilePic'] ==
                                                                    null ||
                                                                d['userProfilePic']
                                                                    .toString()
                                                                    .isEmpty
                                                            ? const Icon(
                                                                Icons.person,
                                                                size: 16,
                                                              )
                                                            : null,
                                                      ),
                                                      const SizedBox(width: 10),
                                                      Expanded(
                                                        child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Row(
                                                              children: [
                                                                Text(
                                                                  '@${d['username_handle'] ?? 'user'}',
                                                                  style: const TextStyle(
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                    fontSize:
                                                                        13,
                                                                  ),
                                                                ),
                                                                if (isMyOwn) ...[
                                                                  const SizedBox(
                                                                    width: 6,
                                                                  ),
                                                                  Container(
                                                                    padding: const EdgeInsets.symmetric(
                                                                      horizontal:
                                                                          6,
                                                                      vertical:
                                                                          2,
                                                                    ),
                                                                    decoration: BoxDecoration(
                                                                      color: theme
                                                                          .primaryColor
                                                                          .withOpacity(
                                                                            0.15,
                                                                          ),
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                            8,
                                                                          ),
                                                                    ),
                                                                    child: Text(
                                                                      englishActive
                                                                          ? "You"
                                                                          : "Anda",
                                                                      style: TextStyle(
                                                                        fontSize:
                                                                            10,
                                                                        color: theme
                                                                            .primaryColor,
                                                                        fontWeight:
                                                                            FontWeight.bold,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ],
                                                                const SizedBox(
                                                                  width: 8,
                                                                ),
                                                                Text(
                                                                  _formatTimestamp(
                                                                    d['timestamp'],
                                                                    englishActive,
                                                                  ),
                                                                  style: const TextStyle(
                                                                    fontSize:
                                                                        11,
                                                                    color: Colors
                                                                        .grey,
                                                                  ),
                                                                ),
                                                                if (isEdited) ...[
                                                                  const SizedBox(
                                                                    width: 6,
                                                                  ),
                                                                  Text(
                                                                    englishActive
                                                                        ? '(Edited)'
                                                                        : '(Diedit)',
                                                                    style: TextStyle(
                                                                      fontSize:
                                                                          11,
                                                                      color: Colors
                                                                          .grey
                                                                          .shade500,
                                                                      fontStyle:
                                                                          FontStyle
                                                                              .italic,
                                                                    ),
                                                                  ),
                                                                ],
                                                              ],
                                                            ),
                                                            Row(
                                                              children: List.generate(
                                                                5,
                                                                (index) => Icon(
                                                                  Icons.star,
                                                                  size: 11,
                                                                  color:
                                                                      index <
                                                                          (d['rating'] ??
                                                                              0)
                                                                      ? Colors
                                                                            .amber
                                                                      : Colors
                                                                            .grey
                                                                            .shade300,
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  if (text.isNotEmpty) ...[
                                                    const SizedBox(height: 6),
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                            left: 42.0,
                                                          ),
                                                      child: Text(
                                                        text,
                                                        style: const TextStyle(
                                                          fontSize: 13,
                                                          height: 1.3,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              );
                                            },
                                          ),
                                  ),

                                  const Divider(height: 40),

                                  // Form Input Ulasan Dinamis
                                  StatefulBuilder(
                                    builder: (context, setFormState) {
                                      return _isEditMode && myReviewDoc != null
                                          ? Container(
                                              width: double.infinity,
                                              padding: const EdgeInsets.all(16),
                                              decoration: BoxDecoration(
                                                color: Colors.green.withOpacity(
                                                  0.06,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: Colors.green
                                                      .withOpacity(0.3),
                                                ),
                                              ),
                                              child: Column(
                                                children: [
                                                  Row(
                                                    children: [
                                                      const Icon(
                                                        Icons.check_circle,
                                                        color: Colors.green,
                                                        size: 20,
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Expanded(
                                                        child: Text(
                                                          englishActive
                                                              ? "You have reviewed this recipe."
                                                              : "Anda telah memberikan ulasan pada resep ini.",
                                                          style:
                                                              const TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                fontSize: 13,
                                                                color: Colors
                                                                    .green,
                                                              ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 12),
                                                  SizedBox(
                                                    width: double.infinity,
                                                    height: 40,
                                                    child: OutlinedButton.icon(
                                                      style: OutlinedButton.styleFrom(
                                                        side: BorderSide(
                                                          color: theme
                                                              .primaryColor,
                                                        ),
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                10,
                                                              ),
                                                        ),
                                                      ),
                                                      icon: const Icon(
                                                        Icons.edit,
                                                        size: 16,
                                                      ),
                                                      label: Text(
                                                        englishActive
                                                            ? "Edit Your Review"
                                                            : "Ubah Ulasan Anda",
                                                        style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 13,
                                                        ),
                                                      ),
                                                      onPressed: () {
                                                        _showEditReviewDialog(
                                                          context,
                                                          myReviewDoc!.data()
                                                              as Map<
                                                                String,
                                                                dynamic
                                                              >,
                                                          _myExistingReviewId!,
                                                          englishActive,
                                                        );
                                                      },
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            )
                                          : Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  englishActive
                                                      ? 'Rate this Recipe'
                                                      : 'Beri Rating Resep',
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.start,
                                                  children: List.generate(5, (
                                                    index,
                                                  ) {
                                                    return IconButton(
                                                      padding: EdgeInsets.zero,
                                                      constraints:
                                                          const BoxConstraints(),
                                                      onPressed: () {
                                                        setFormState(() {
                                                          _selectedRating =
                                                              index + 1;
                                                        });
                                                      },
                                                      icon: Icon(
                                                        index < _selectedRating
                                                            ? Icons.star
                                                            : Icons.star_border,
                                                        color: Colors.amber,
                                                        size: 36,
                                                      ),
                                                    );
                                                  }),
                                                ),
                                                const SizedBox(height: 12),
                                                TextField(
                                                  controller:
                                                      _commentController,
                                                  decoration: InputDecoration(
                                                    hintText: englishActive
                                                        ? 'Write a review (Optional)...'
                                                        : 'Tulis ulasan Anda (Opsional)...',
                                                    border: OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                    ),
                                                    contentPadding:
                                                        const EdgeInsets.all(
                                                          14,
                                                        ),
                                                  ),
                                                  maxLines: 3,
                                                ),
                                                const SizedBox(height: 16),
                                                _isSubmitting
                                                    ? const Center(
                                                        child:
                                                            CircularProgressIndicator(),
                                                      )
                                                    : SizedBox(
                                                        width: double.infinity,
                                                        height: 48,
                                                        child: ElevatedButton(
                                                          style: ElevatedButton.styleFrom(
                                                            backgroundColor: theme
                                                                .primaryColor,
                                                            foregroundColor:
                                                                Colors.white,
                                                            shape: RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    12,
                                                                  ),
                                                            ),
                                                            elevation: 0,
                                                          ),
                                                          onPressed: () async {
                                                            await _submitComment();
                                                            setFormState(() {});
                                                          },
                                                          child: Text(
                                                            englishActive
                                                                ? 'Post Review'
                                                                : 'Kirim Ulasan',
                                                            style:
                                                                const TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                ),
                                                          ),
                                                        ),
                                                      ),
                                              ],
                                            );
                                    },
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
