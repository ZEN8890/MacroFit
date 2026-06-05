import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/notification_helper.dart';
import '../utils/global_state.dart';

class InlineHealthMetricsCard extends StatefulWidget {
  final String userId;
  final double initialWeight;
  final double initialHeight;
  final int calculatedAge;
  final ThemeData theme;
  final bool isDarkMode;

  const InlineHealthMetricsCard({
    super.key,
    required this.userId,
    required this.initialWeight,
    required this.initialHeight,
    required this.calculatedAge,
    required this.theme,
    required this.isDarkMode,
  });

  @override
  State<InlineHealthMetricsCard> createState() =>
      _InlineHealthMetricsCardState();
}

class _InlineHealthMetricsCardState extends State<InlineHealthMetricsCard> {
  late TextEditingController _weightController;
  late TextEditingController _heightController;
  bool _isChanged = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _weightController = TextEditingController(
      text: _formatNum(widget.initialWeight),
    );
    _heightController = TextEditingController(
      text: _formatNum(widget.initialHeight),
    );
  }

  @override
  void didUpdateWidget(covariant InlineHealthMetricsCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((widget.initialWeight != oldWidget.initialWeight ||
            widget.initialHeight != oldWidget.initialHeight) &&
        !_isChanged) {
      _weightController.text = _formatNum(widget.initialWeight);
      _heightController.text = _formatNum(widget.initialHeight);
    }
  }

  String _formatNum(double num) {
    return num == num.roundToDouble() ? num.round().toString() : num.toString();
  }

  @override
  void dispose() {
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  void _checkIfChanged() {
    final double? w = double.tryParse(_weightController.text.trim());
    final double? h = double.tryParse(_heightController.text.trim());
    setState(() {
      _isChanged =
          (w != null && w != widget.initialWeight) ||
          (h != null && h != widget.initialHeight);
    });
  }

  Future<void> _calculateAndSaveMetrics() async {
    final double? newWeight = double.tryParse(_weightController.text.trim());
    final double? newHeight = double.tryParse(_heightController.text.trim());
    final bool isEn = isEnglishNotifier.value;

    if (newWeight == null ||
        newWeight <= 0 ||
        newWeight > 300 ||
        newHeight == null ||
        newHeight <= 0 ||
        newHeight > 250) {
      Notify.error(
        context,
        isEn
            ? "Please enter valid health metrics"
            : "Silakan masukkan angka metrik fisik yang valid",
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final userRef = FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId);
      final userDoc = await userRef.get();
      if (!userDoc.exists || userDoc.data() == null) return;

      final data = userDoc.data() as Map<String, dynamic>;
      String gender = data['gender'] ?? 'Laki-laki';
      String dietCode = data['diet_code'] ?? 'healthy_lifestyle';
      double activityMultiplier = (data['activity_multiplier'] ?? 1.2)
          .toDouble();
      int currentAge = widget.calculatedAge;

      double bmr = (gender == 'Laki-laki' || gender == 'Male')
          ? 66.5 +
                (13.75 * newWeight) +
                (5.003 * newHeight) -
                (6.75 * currentAge)
          : 655.1 +
                (9.563 * newWeight) +
                (1.85 * newHeight) -
                (4.676 * currentAge);

      double baseTdee = bmr * activityMultiplier;
      int targetCalories;
      switch (dietCode) {
        case 'Menurunkan Berat Badan':
        case 'txt_weight_loss':
          targetCalories = (baseTdee - 500).round();
          break;
        case 'gain_muscle':
          targetCalories = (baseTdee + 400).round();
          break;
        case 'keto_diet':
          targetCalories = (baseTdee - 200).round();
          break;
        case 'healthy_lifestyle':
        case 'vegetarian':
        default:
          targetCalories = baseTdee.round();
          break;
      }

      if (targetCalories < 1200) targetCalories = 1200;

      int targetCarbs;
      int targetProteins;
      int targetFats;

      switch (dietCode) {
        case 'Menurunkan Berat Badan':
        case 'txt_weight_loss':
          targetCarbs = ((targetCalories * 0.40) / 4).round();
          targetProteins = ((targetCalories * 0.40) / 4).round();
          targetFats = ((targetCalories * 0.20) / 9).round();
          break;
        case 'gain_muscle':
          targetCarbs = ((targetCalories * 0.50) / 4).round();
          targetProteins = ((targetCalories * 0.30) / 4).round();
          targetFats = ((targetCalories * 0.20) / 9).round();
          break;
        case 'keto_diet':
          targetCarbs = ((targetCalories * 0.05) / 4).round();
          targetProteins = ((targetCalories * 0.25) / 4).round();
          targetFats = ((targetCalories * 0.70) / 9).round();
          break;
        case 'healthy_lifestyle':
        case 'vegetarian':
        default:
          targetCarbs = ((targetCalories * 0.55) / 4).round();
          targetProteins = ((targetCalories * 0.20) / 4).round();
          targetFats = ((targetCalories * 0.25) / 9).round();
          break;
      }

      await userRef.update({
        'weight': newWeight,
        'height': newHeight,
        'target_calories': targetCalories,
        'target_carbs': targetCarbs,
        'target_proteins': targetProteins,
        'target_fats': targetFats,
      });

      setState(() => _isChanged = false);

      if (mounted) {
        Notify.success(
          context,
          isEn
              ? "⚡ Body stats saved! Targets recalculated to $targetCalories kcal."
              : "⚡ Statistik fisik disimpan! Kalori dihitung ulang menjadi $targetCalories kkal.",
        );
      }
    } catch (e) {
      if (mounted) Notify.error(context, "Error: $e");
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEn = isEnglishNotifier.value;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.analytics_outlined,
                      color: Colors.deepOrange,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isEn
                          ? 'Body Statistics Metrics'
                          : 'Metrik Statistik Fisik',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (_isChanged)
                  _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : TextButton.icon(
                          style: TextButton.styleFrom(
                            foregroundColor: widget.theme.primaryColor,
                          ),
                          icon: const Icon(Icons.check, size: 16),
                          label: Text(
                            isEn ? 'Save' : 'Simpan',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          onPressed: _calculateAndSaveMetrics,
                        ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isEn ? "Weight" : "Berat",
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _weightController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: widget.isDarkMode
                                    ? Colors.white
                                    : Colors.black87,
                              ),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                isDense: true,
                                counterText: "",
                              ),
                              maxLength: 5,
                              onChanged: (_) => _checkIfChanged(),
                            ),
                          ),
                          Text(
                            "kg",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: widget.theme.primaryColor,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 30,
                  width: 1,
                  color: Colors.black12,
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isEn ? "Height" : "Tinggi",
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _heightController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: widget.isDarkMode
                                    ? Colors.white
                                    : Colors.black87,
                              ),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                isDense: true,
                                counterText: "",
                              ),
                              maxLength: 5,
                              onChanged: (_) => _checkIfChanged(),
                            ),
                          ),
                          Text(
                            "cm",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: widget.theme.primaryColor,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 30,
                  width: 1,
                  color: Colors.black12,
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isEn ? "Age (Auto)" : "Umur (Otomatis)",
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.cake_outlined,
                            size: 14,
                            color: widget.theme.primaryColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "${widget.calculatedAge} ${isEn ? 'yo' : 'thn'}",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: widget.isDarkMode
                                  ? Colors.white70
                                  : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
