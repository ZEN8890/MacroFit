class NutritionModel {
  final int targetCalMin;
  final int targetCalMax;
  final int proteinGram;
  final int carbsGram;
  final int fatsGram;
  final int sugarGram;
  final int waterMl;
  final String dietCode;

  NutritionModel({
    required this.targetCalMin,
    required this.targetCalMax,
    required this.proteinGram,
    required this.carbsGram,
    required this.fatsGram,
    required this.sugarGram,
    required this.waterMl,
    required this.dietCode,
  });

  int get averageCalories => ((targetCalMin + targetCalMax) / 2).round();
}
