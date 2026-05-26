import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../pages/public_profile_page.dart';
import '../utils/notification_helper.dart'; // 🟢 Import helper notifikasi

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

  // 🟢 TAMBAHKAN STATE FILTER: 0 berarti menampilkan semua ulasan
  int _filterRating = 0;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitComment(
    String userHandle,
    String fullName,
    String pPic,
  ) async {
    if (_selectedRating == 0) {
      Notify.error(context, '⚠️ Silakan pilih rating bintang terlebih dahulu.');
      return;
    }

    final String text = _commentController.text.trim();

    setState(() {
      _isSubmitting = true;
    });

    try {
      final String activeRecipeId = widget.docId;
      final FieldValue serverTime = FieldValue.serverTimestamp();

      await _firestore.collection('recipe_comments').add({
        'recipeId': activeRecipeId,
        'userId': widget.currentUserId,
        'username': fullName,
        'username_handle': userHandle,
        'userProfilePic': pPic,
        'commentText': text.isNotEmpty ? text : '(Hanya memberikan rating)',
        'rating': _selectedRating,
        'timestamp': serverTime,
      });

      await _firestore.collection('user_comments_history').add({
        'userId': widget.currentUserId,
        'username_handle': userHandle,
        'recipeId': activeRecipeId,
        'recipeTitle': widget.recipeData['title'] ?? 'Resep',
        'commentText': text.isNotEmpty
            ? text
            : 'Memberikan rating bintang $_selectedRating',
        'rating': _selectedRating,
        'timestamp': serverTime,
      });

      _commentController.clear();
      setState(() {
        _selectedRating = 0;
      });

      if (mounted) {
        Notify.error(
          context,
          '⚠️ Silakan pilih rating bintang terlebih dahulu.',
        );
      }
    } catch (e) {
      debugPrint("Gagal mengirim ulasan: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Resep'),
        content: const Text(
          'Apakah Anda yakin ingin menghapus resep ini secara permanen dari database?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              widget.onDeleteRecipe();
              if (context.mounted) Navigator.pop(context);
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
    final isDarkMode = theme.brightness == Brightness.dark;

    List<String> ingredients = List<String>.from(
      widget.recipeData['ingredients'] ?? [],
    );
    List<String> instructions = List<String>.from(
      widget.recipeData['instructions'] ?? [],
    );

    final String recipeCreatorId = widget.recipeData['userId'] ?? '';
    bool isMyOwnRecipe = recipeCreatorId == widget.currentUserId;

    String finalImageUrl = widget.recipeData['image_url'] ?? '';
    final String type = widget.recipeData['type'] ?? 'Community';
    final String titleText = widget.recipeData['title'] ?? 'Resep Tanpa Nama';

    if (finalImageUrl.isEmpty && type == 'AI') {
      final String keyword =
          widget.recipeData['image_keyword'] ?? 'healthy_food';
      final String uniqueString = Uri.encodeComponent(titleText);
      finalImageUrl =
          'https://images.unsplash.com/photo-1498837167922-ddd27525d352?q=80&w=600&auto=format&fit=crop';
      if (keyword != 'healthy_food' && keyword.isNotEmpty) {
        finalImageUrl =
            'https://images.unsplash.com/featured/600x400/?$keyword&random=$uniqueString';
      }
    }

    final String recipeHandle = widget.recipeData['username_handle'] ?? '';
    final String recipeAuthorName = widget.recipeData['username'] ?? 'User';

    String detailAuthorText;
    if (type == 'AI') {
      detailAuthorText = 'Oleh: MacroFit AI';
    } else if (recipeCreatorId == widget.currentUserId) {
      detailAuthorText = 'Oleh: @stvnnvts8';
    } else if (recipeHandle.trim().isNotEmpty) {
      detailAuthorText = 'Oleh: @${recipeHandle.trim().toLowerCase()}';
    } else {
      String cleanFallback = recipeAuthorName.trim().toLowerCase().replaceAll(
        ' ',
        '',
      );
      detailAuthorText = 'Oleh: @$cleanFallback';
    }

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
        bool isLockedByCommunity = savedByList.isNotEmpty;

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

                  if (finalImageUrl.isNotEmpty) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Hero(
                        tag: 'recipe_image_${type}_$titleText',
                        child: Image.network(
                          finalImageUrl,
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 180,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: theme.primaryColor.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.broken_image_outlined,
                                  color: Colors.grey,
                                  size: 36,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 🟢 FIXED: Mengganti komponen ilegal 'Widget' menjadi 'Expanded' biasa agar layout text aman dari eror compiler
                      Expanded(
                        child: Text(
                          titleText,
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
                        onPressed: () async => await widget.onToggleFavorite(
                          widget.docId,
                          savedByList,
                        ),
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
                        detailAuthorText,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
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

                  if (isMyOwnRecipe) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: isLockedByCommunity
                                  ? Colors.grey
                                  : theme.primaryColor,
                              side: BorderSide(
                                color: isLockedByCommunity
                                    ? Colors.grey.shade300
                                    : theme.primaryColor,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            label: Text(
                              isLockedByCommunity ? 'Edit (Terkunci)' : 'Edit',
                            ),
                            onPressed: isLockedByCommunity
                                ? () {
                                    Notify.error(
                                      context,
                                      'Resep ini tidak dapat diubah karena sudah disimpan pengguna lain.',
                                    );
                                  }
                                : () => Navigator.pop(context, true),
                          ),
                        ),
                        const SizedBox(width: 12),
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

                  const Divider(height: 40),
                  const Text(
                    'Ulasan & Rating Komunitas:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  // 🟢 ANTARMUKA BARU: Tampilan Filter Rating Bintang Horizontal
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [0, 5, 4, 3, 2, 1].map((int rating) {
                        final bool isSelected = _filterRating == rating;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ChoiceChip(
                            label: Row(
                              children: [
                                Text(rating == 0 ? 'Semua ulasan' : '$rating'),
                                if (rating != 0) ...[
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.star,
                                    size: 14,
                                    color: Colors.amber,
                                  ),
                                ],
                              ],
                            ),
                            selected: isSelected,
                            selectedColor: theme.primaryColor.withOpacity(0.2),
                            checkmarkColor: theme.primaryColor,
                            onSelected: (bool selected) {
                              setState(() {
                                _filterRating = selected ? rating : 0;
                              });
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  StreamBuilder<QuerySnapshot>(
                    stream: _firestore
                        .collection('recipe_comments')
                        .where('recipeId', isEqualTo: widget.docId)
                        .orderBy('timestamp', descending: true)
                        .snapshots(),
                    builder: (context, commentSnapshot) {
                      if (commentSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(12.0),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      if (!commentSnapshot.hasData ||
                          commentSnapshot.data!.docs.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12.0),
                          child: Text(
                            'Belum ada ulasan untuk menu ini. Jadilah yang pertama memberikan review!',
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                        );
                      }

                      final commentDocs = commentSnapshot.data!.docs;

                      // 🟢 LOGIKA FILTERING DART CLIENT-SIDE: Saring data berdasarkan rating aktif
                      final filteredComments = commentDocs.where((doc) {
                        final cData = doc.data() as Map<String, dynamic>;
                        final int itemRating = cData['rating'] ?? 5;
                        if (_filterRating == 0) return true;
                        return itemRating == _filterRating;
                      }).toList();

                      if (filteredComments.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16.0),
                          child: Center(
                            child: Text(
                              'Tidak ada ulasan dengan rating bintang tersebut.',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount:
                            filteredComments.length, // Gunakan hasil filter
                        itemBuilder: (context, index) {
                          final cData =
                              filteredComments[index].data()
                                  as Map<String, dynamic>;
                          int itemRating = cData['rating'] ?? 5;

                          final String commenterId = cData['userId'] ?? '';
                          final String commentHandle =
                              cData['username_handle'] ?? '';
                          final String commentFullName =
                              cData['username'] ?? 'User';

                          String commentDisplayName;
                          if (commenterId == widget.currentUserId) {
                            commentDisplayName = '@stvnnvts8';
                          } else if (commentHandle.trim().isNotEmpty &&
                              commentHandle != 'anonymous') {
                            commentDisplayName =
                                '@${commentHandle.trim().toLowerCase()}';
                          } else {
                            String cleanCommentFallback = commentFullName
                                .trim()
                                .toLowerCase()
                                .replaceAll(' ', '');
                            commentDisplayName = cleanCommentFallback.isEmpty
                                ? '@anonymous'
                                : '@$cleanCommentFallback';
                          }

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    if (cData['userId'] != null) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              PublicProfilePage(
                                                targetUserId: cData['userId'],
                                              ),
                                        ),
                                      );
                                    }
                                  },
                                  child: CircleAvatar(
                                    radius: 18,
                                    backgroundColor: theme.primaryColor
                                        .withOpacity(0.1),
                                    backgroundImage:
                                        (cData['userProfilePic'] != null &&
                                            cData['userProfilePic']
                                                .toString()
                                                .isNotEmpty)
                                        ? NetworkImage(cData['userProfilePic'])
                                        : null,
                                    child: cData['userProfilePic'] == null
                                        ? Icon(
                                            Icons.person,
                                            size: 18,
                                            color: theme.primaryColor,
                                          )
                                        : null,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      GestureDetector(
                                        onTap: () {
                                          if (cData['userId'] != null) {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    PublicProfilePage(
                                                      targetUserId:
                                                          cData['userId'],
                                                    ),
                                              ),
                                            );
                                          }
                                        },
                                        child: Text(
                                          commentDisplayName,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: theme.primaryColor,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: List.generate(5, (starIndex) {
                                          return Icon(
                                            starIndex < itemRating
                                                ? Icons.star
                                                : Icons.star_border,
                                            color: Colors.amber,
                                            size: 14,
                                          );
                                        }),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        cData['commentText'] ?? '',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: isDarkMode
                                              ? Colors.white
                                              : Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),

                  const Divider(height: 32),

                  FutureBuilder<DocumentSnapshot>(
                    future: _firestore
                        .collection('users')
                        .doc(widget.currentUserId)
                        .get(),
                    builder: (context, userSnapshot) {
                      if (!userSnapshot.hasData || !userSnapshot.data!.exists)
                        return const SizedBox();

                      final uData =
                          userSnapshot.data!.data() as Map<String, dynamic>;
                      String myHandle = uData['username_handle'] ?? 'anonymous';
                      String myName = uData['username'] ?? 'User';
                      String myPic = uData['profile_picture'] ?? '';

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Beri Nilai & Ulasan Masakan:',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: List.generate(5, (index) {
                              return IconButton(
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                icon: Icon(
                                  index < _selectedRating
                                      ? Icons.star
                                      : Icons.star_border,
                                  color: Colors.amber,
                                  size: 28,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _selectedRating = index + 1;
                                  });
                                },
                              );
                            }),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _commentController,
                                  textCapitalization:
                                      TextCapitalization.sentences,
                                  decoration: InputDecoration(
                                    hintText:
                                        'Tulis komentar/ulasan menu sehat (opsional)...',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 10,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              CircleAvatar(
                                backgroundColor: theme.primaryColor,
                                child: _isSubmitting
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : IconButton(
                                        icon: const Icon(
                                          Icons.send,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                        onPressed: () => _submitComment(
                                          myHandle,
                                          myName,
                                          myPic,
                                        ),
                                      ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
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
