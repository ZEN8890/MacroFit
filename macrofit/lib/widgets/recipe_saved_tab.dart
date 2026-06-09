import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'recipe_stream_view.dart';

class RecipeSavedTab extends StatelessWidget {
  final String selectedSavedDietFilter;
  final List<String> dietOptions;
  final String currentUserId;
  final String refreshTriggerKey;
  final FirebaseFirestore firestore;
  final ValueChanged<String> onFilterChanged;
  final Function(Map<String, dynamic>, String) onTapCard;

  // 🟢 FIX UTAMA: Mengubah penulisan tipe agar sinkron dengan struktur asinkron di file induk
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
                    selectedSavedDietFilter == 'All'
                        ? "Saring Kategori:"
                        : "Filter Category:",
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              DropdownButton<String>(
                value: selectedSavedDietFilter,
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
                items: ['All', ...dietOptions].map((String value) {
                  String displayLabel = value;
                  if (value == 'All') displayLabel = 'All Categories / Semua';
                  if (value == 'Menurunkan Berat Badan') {
                    displayLabel = 'Menurunkan Berat Badan / Weight Loss';
                  }
                  if (value == 'gain_muscle') {
                    displayLabel = 'Menaikkan Massa Otot / Gain Muscle';
                  }
                  if (value == 'healthy_lifestyle') {
                    displayLabel = 'Gaya Hidup Sehat / Healthy Lifestyle';
                  }
                  if (value == 'keto_diet') {
                    displayLabel = 'Diet Keto / Keto Diet';
                  }
                  if (value == 'vegetarian') displayLabel = 'Vegetarian';

                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(
                      displayLabel,
                      style: const TextStyle(fontSize: 12),
                    ),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    onFilterChanged(newValue);
                  }
                },
              ),
            ],
          ),
        ),
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
  }
}
