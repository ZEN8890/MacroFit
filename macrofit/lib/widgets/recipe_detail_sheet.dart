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

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

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

      Map<String, dynamic> reviewData = {
        'recipeId': widget.docId,
        'userId': widget.currentUserId,
        'username': userData['username'] ?? 'User',
        'username_handle': userData['username_handle'] ?? 'user',
        'userProfilePic': userData['profile_picture'] ?? '',
        'commentText': text, // Biarkan kosong jika user tidak mengetik
        'rating': _selectedRating,
        'timestamp': FieldValue.serverTimestamp(),
      };

      if (_isEditMode && _myExistingReviewId != null) {
        await _firestore
            .collection('recipe_comments')
            .doc(_myExistingReviewId)
            .update(reviewData);
      } else {
        await _firestore.collection('recipe_comments').add(reviewData);
      }

      _commentController.clear();
      setState(() {
        _selectedRating = 0;
        _isSubmitting = false;
        _isEditMode = false;
      });
    } catch (e) {
      setState(() => _isSubmitting = false);
      Notify.error(
        context,
        isEnglish ? "Failed to process review." : "Gagal memproses ulasan.",
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isEnglishNotifier,
      builder: (context, englishActive, child) {
        return StreamBuilder<DocumentSnapshot>(
          stream: _firestore
              .collection('recipes')
              .doc(widget.docId)
              .snapshots(),
          builder: (context, snapshot) {
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
                      Text(
                        widget.recipeData['title'] ?? 'Recipe',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // AREA ULASAN
                      Text(
                        englishActive
                            ? 'Community Reviews:'
                            : 'Ulasan Komunitas:',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      StreamBuilder<QuerySnapshot>(
                        stream: _firestore
                            .collection('recipe_comments')
                            .where('recipeId', isEqualTo: widget.docId)
                            .orderBy('timestamp', descending: true)
                            .snapshots(),
                        builder: (context, commentSnapshot) {
                          if (!commentSnapshot.hasData)
                            return const CircularProgressIndicator();
                          final docs = commentSnapshot.data!.docs;
                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: docs.length,
                            itemBuilder: (context, i) {
                              final d = docs[i].data() as Map<String, dynamic>;
                              final String text = d['commentText'] ?? '';
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundImage: d['userProfilePic'] != null
                                      ? NetworkImage(d['userProfilePic'])
                                      : null,
                                ),
                                title: Text(
                                  '@${d['username_handle'] ?? 'user'}',
                                ),
                                // 🟢 HANYA TAMPILKAN SUBTITLE JIKA TEKS TIDAK KOSONG
                                subtitle: text.isNotEmpty ? Text(text) : null,
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: List.generate(
                                    d['rating'] ?? 0,
                                    (index) => const Icon(
                                      Icons.star,
                                      size: 14,
                                      color: Colors.amber,
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),

                      const Divider(height: 32),
                      TextField(
                        controller: _commentController,
                        decoration: InputDecoration(
                          hintText: englishActive
                              ? 'Comment (Optional)'
                              : 'Komentar (Opsional)',
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _submitComment,
                        child: Text(
                          _isEditMode
                              ? (englishActive ? 'Save' : 'Simpan')
                              : (englishActive ? 'Submit' : 'Kirim'),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
