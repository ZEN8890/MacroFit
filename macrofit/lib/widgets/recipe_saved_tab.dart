import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'recipe_stream_view.dart';
import '../utils/global_state.dart';

class RecipeSavedTab extends StatelessWidget {
  final String selectedSavedDietFilter;
  final List<String> dietOptions;
  final String currentUserId;
  final String refreshTriggerKey;
  final FirebaseFirestore firestore;
  final ValueChanged<String> onFilterChanged;
  final Function(Map<String, dynamic>, String) onTapCard;

  final Future<void> Function(String, List<dynamic>) onToggleFavorite;

  const RecipeSavedTab({
    super.key,
    required this.selectedSavedDietFilter,
    required this.dietOptions,
    required this.currentUserId,
    required this.refreshTriggerKey,
    required this.firestore,
    required this.onFilterChanged,
    required this.onTapCard,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isEnglishNotifier,
      builder: (context, englishActive, child) {
        return Column(
          children: [
            Expanded(
              child: RecipeStreamView(
                key: ValueKey(
                  'stream_favorites_${selectedSavedDietFilter}_$refreshTriggerKey',
                ),
                filterType: 'Favorites',
                currentUserId: currentUserId,
                firestore: firestore,
                savedDietFilter: selectedSavedDietFilter,
                onDietFilterChanged: onFilterChanged,
                onTapCard: onTapCard,
                onToggleFavorite: onToggleFavorite,
              ),
            ),
          ],
        );
      },
    );
  }
}
