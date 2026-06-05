import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // 🟢 FIX EROR 1: Mengimpor Firestore agar dikenal oleh compiler
import 'recipe_stream_view.dart';
import '../utils/global_state.dart';

class RecipeAITab extends StatelessWidget {
  final int remainingCounter;
  final bool isGeneratingAI;
  final String currentUserId;
  final String refreshTriggerKey;
  final VoidCallback onGeneratePressed;
  final Function(Map<String, dynamic>, String) onTapCard;

  // 🟢 FIX EROR 2: Mengubah dari tipe 'Function' menjadi tipe data Future asinkron yang presisi
  final Future<void> Function(String, List<dynamic>) onToggleFavorite;

  const RecipeAITab({
    super.key,
    required this.remainingCounter,
    required this.isGeneratingAI,
    required this.currentUserId,
    required this.refreshTriggerKey,
    required this.onGeneratePressed,
    required this.onTapCard,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEnglish = isEnglishNotifier.value;

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
                          ? "Ask AI to craft instant recipes! (Left Today: $remainingCounter/2)"
                          : "Minta AI buatkan resep instan! (Sisa Hari Ini: $remainingCounter/2)",
                      style: TextStyle(
                        fontSize: 12,
                        color: remainingCounter == 0
                            ? Colors.red.shade400
                            : Colors.grey,
                        fontWeight: remainingCounter == 0
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
              isGeneratingAI
                  ? const CircularProgressIndicator(strokeWidth: 3)
                  : SizedBox(
                      width: 130,
                      height: 38,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: remainingCounter <= 0
                              ? Colors.grey.shade400
                              : theme.primaryColor,
                          foregroundColor: remainingCounter <= 0
                              ? Colors.grey.shade600
                              : Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          elevation: remainingCounter <= 0 ? 0 : 2,
                        ),
                        icon: Icon(
                          Icons.bolt,
                          color: remainingCounter <= 0
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
                        onPressed: onGeneratePressed,
                      ),
                    ),
            ],
          ),
        ),
        Expanded(
          child: RecipeStreamView(
            key: ValueKey('stream_ai_tab_$refreshTriggerKey'),
            filterType: 'AI',
            currentUserId: currentUserId,
            firestore: FirebaseFirestore.instance,
            onTapCard: onTapCard,
            onToggleFavorite: onToggleFavorite,
          ),
        ),
      ],
    );
  }
}
