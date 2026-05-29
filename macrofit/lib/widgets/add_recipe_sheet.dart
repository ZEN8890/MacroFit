import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:macrofit/utils/notification_helper.dart';
import '../utils/global_state.dart'; // 🟢 IMPORT SAKLAR GLOBAL STATE

class AddRecipeSheet extends StatefulWidget {
  final List<String> dietOptions;
  final Function(
    String title,
    int calories,
    List<String> ingredients,
    List<String> instructions,
    String suitable,
    String unsuitable,
    List<XFile> images,
  )
  onPublish;

  final String? initialTitle;
  final String? initialCalories;
  final List<String>? initialIngredients;
  final List<String>? initialInstructions;
  final String? initialSuitable;
  final String? initialUnsuitable;
  final bool isEditing;

  const AddRecipeSheet({
    super.key,
    required this.dietOptions,
    required this.onPublish,
    this.initialTitle,
    this.initialCalories,
    this.initialIngredients,
    this.initialInstructions,
    this.initialSuitable,
    this.initialUnsuitable,
    this.isEditing = false,
  });

  @override
  State<AddRecipeSheet> createState() => _AddRecipeSheetState();
}

class _AddRecipeSheetState extends State<AddRecipeSheet> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController titleController;
  late final TextEditingController calorieController;
  late final TextEditingController ingredientsController;
  late final TextEditingController instructionsController;

  String selectedSuitableDiet = 'healthy_lifestyle';

  List<XFile> _selectedImages = [];
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();

    titleController = TextEditingController(
      text: widget.isEditing ? widget.initialTitle : '',
    );
    calorieController = TextEditingController(
      text: widget.isEditing ? widget.initialCalories : '',
    );

    String ingredientsText = '';
    if (widget.isEditing && widget.initialIngredients != null) {
      ingredientsText = widget.initialIngredients!.join(', ');
    }
    ingredientsController = TextEditingController(text: ingredientsText);

    String instructionsText = '';
    if (widget.isEditing && widget.initialInstructions != null) {
      instructionsText = widget.initialInstructions!.join(', ');
    }
    instructionsController = TextEditingController(text: instructionsText);

    if (widget.isEditing && widget.initialSuitable != null) {
      if (widget.dietOptions.contains(widget.initialSuitable)) {
        selectedSuitableDiet = widget.initialSuitable!;
      }
    } else if (widget.dietOptions.isNotEmpty) {
      selectedSuitableDiet = widget.dietOptions.first;
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    calorieController.dispose();
    ingredientsController.dispose();
    instructionsController.dispose();
    super.dispose();
  }

  Future<void> _pickImagesFromGallery() async {
    final bool isEnglish = isEnglishNotifier.value;
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          _selectedImages = [..._selectedImages, ...images].take(5).toList();
        });
      }
    } catch (e) {
      if (mounted) {
        Notify.error(
          context,
          isEnglish
              ? 'Failed to pick images: $e'
              : 'Gagal mengambil gambar: $e',
        );
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  // 🟢 FUNGSI HELPER INTERNAL: Mengubah value database menjadi label bersih sesuai bahasa aktif
  String _getCleanDietLabel(String value, bool isEnglish) {
    if (value == 'gain_muscle')
      return isEnglish ? 'Gain Muscle' : 'Menambah Otot';
    if (value == 'healthy_lifestyle' ||
        value == 'lose_weight' ||
        value == 'Menurunkan Berat Badan') {
      return isEnglish ? 'Weight Loss' : 'Menurunkan Berat Badan';
    }
    if (value == 'keto_diet') return isEnglish ? 'Keto Diet' : 'Diet Keto';
    if (value == 'vegetarian') return 'Vegetarian';
    if (value == 'low_carb')
      return isEnglish ? 'Low Carb' : 'Rendah Karbohidrat';
    if (value == 'balanced')
      return isEnglish ? 'Balanced Nutrition' : 'Gizi Seimbang';
    if (value == 'Normal') return 'Normal';

    return value.replaceAll('_', ' ');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    // 🟢 REAKTIF MULTI-BAHASA: Membungkus seluruh kembalian widget dengan ValueListenableBuilder
    return ValueListenableBuilder<bool>(
      valueListenable: isEnglishNotifier,
      builder: (context, englishActive, child) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 16,
            left: 24,
            right: 24,
          ),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SizedBox(
                        width: 38,
                        height: 38,
                        child: IconButton(
                          style: IconButton.styleFrom(
                            backgroundColor: isDarkMode
                                ? Colors.white.withOpacity(0.1)
                                : Colors.black.withOpacity(0.08),
                            padding: EdgeInsets.zero,
                          ),
                          icon: const Icon(Icons.close, size: 18),
                          tooltip: englishActive ? 'Back' : 'Kembali',
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDarkMode
                              ? Colors.white.withOpacity(0.15)
                              : Colors.black.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      const SizedBox(width: 38),
                    ],
                  ),
                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Icon(
                        widget.isEditing
                            ? Icons.edit_note_rounded
                            : Icons.restaurant_menu,
                        color: theme.primaryColor,
                        size: 24,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        widget.isEditing
                            ? (englishActive
                                  ? "Edit Your Recipe"
                                  : "Edit Resep Anda")
                            : (englishActive
                                  ? "Publish New Recipe"
                                  : "Publish Resep Baru"),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.isEditing
                        ? (englishActive
                              ? "Update your healthy meal detail to keep it accurate"
                              : "Perbarui detail menu masakan sehat Anda agar tetap akurat")
                        : (englishActive
                              ? "Share your healthy culinary creation with MacroFit community"
                              : "Bagikan kreasi kuliner sehatmu ke komunitas MacroFit"),
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const Divider(height: 24),

                  if (!widget.isEditing) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          englishActive
                              ? "Culinary Food Photos (Max 5)"
                              : "Foto Masakan Kuliner (Maksimal 5)",
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          "${_selectedImages.length}/5",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _selectedImages.length == 5
                                ? Colors.redAccent
                                : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    SizedBox(
                      height: 90,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _selectedImages.length < 5
                            ? _selectedImages.length + 1
                            : 5,
                        itemBuilder: (context, index) {
                          if (index == _selectedImages.length &&
                              _selectedImages.length < 5) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 10.0),
                              child: InkWell(
                                onTap: _pickImagesFromGallery,
                                borderRadius: BorderRadius.circular(14),
                                child: Container(
                                  width: 90,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: isDarkMode
                                          ? Colors.white24
                                          : Colors.black12,
                                      style: BorderStyle.solid,
                                      width: 1.5,
                                    ),
                                    color: theme.primaryColor.withOpacity(0.02),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.add_a_photo_outlined,
                                        color: theme.primaryColor,
                                        size: 24,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        englishActive ? "Add" : "Tambah",
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }

                          return Padding(
                            padding: const EdgeInsets.only(right: 10.0),
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: Image.file(
                                    File(_selectedImages[index].path),
                                    width: 90,
                                    height: 90,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: GestureDetector(
                                    onTap: () => _removeImage(index),
                                    child: Container(
                                      padding: const EdgeInsets.all(24.0),
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: const BoxDecoration(
                                          color: Colors.black54,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.close,
                                          size: 14,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  TextFormField(
                    controller: titleController,
                    textCapitalization: TextCapitalization.words,
                    enabled: !widget.isEditing,
                    decoration: InputDecoration(
                      labelText: englishActive
                          ? 'Food / Menu Name'
                          : 'Nama Makanan / Menu',
                      fillColor: widget.isEditing
                          ? (isDarkMode
                                ? Colors.white.withOpacity(0.04)
                                : Colors.black.withOpacity(0.03))
                          : null,
                      filled: widget.isEditing,
                      prefixIcon: const Icon(Icons.fastfood_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? (englishActive
                              ? 'Food name cannot be empty'
                              : 'Nama makanan tidak boleh kosong')
                        : null,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: calorieController,
                    keyboardType: TextInputType.number,
                    enabled: !widget.isEditing,
                    decoration: InputDecoration(
                      labelText: englishActive
                          ? 'Estimated Calories'
                          : 'Estimasi Kalori',
                      suffixText: 'kkal',
                      fillColor: widget.isEditing
                          ? (isDarkMode
                                ? Colors.white.withOpacity(0.04)
                                : Colors.black.withOpacity(0.03))
                          : null,
                      filled: widget.isEditing,
                      prefixIcon: const Icon(
                        Icons.local_fire_department_outlined,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? (englishActive
                              ? 'Estimated calories is required'
                              : 'Estimasi kalori wajib diisi')
                        : null,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: ingredientsController,
                    minLines: 3,
                    maxLines: 5,
                    keyboardType: TextInputType.multiline,
                    decoration: InputDecoration(
                      labelText: englishActive ? 'Ingredients' : 'Bahan-bahan',
                      hintText: englishActive
                          ? 'Example: 100g chicken breast, 1 tbsp honey'
                          : 'Contoh: 100g dada ayam, 1 sdm madu',
                      alignLabelWithHint: true,
                      prefixIcon: const Padding(
                        padding: EdgeInsets.only(bottom: 40),
                        child: Icon(Icons.shopping_basket_outlined),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? (englishActive
                              ? 'Ingredients are required'
                              : 'Bahan-bahan wajib diisi')
                        : null,
                  ),
                  Text(
                    englishActive
                        ? "  *Separate each ingredient with a comma (,)"
                        : "  *Pisahkan tiap bahan menggunakan tanda koma (,)",
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: instructionsController,
                    minLines: 4,
                    maxLines: 10,
                    keyboardType: TextInputType.multiline,
                    decoration: InputDecoration(
                      labelText: englishActive
                          ? 'Cooking Instructions / Steps'
                          : 'Cara Memasak / Langkah',
                      hintText: englishActive
                          ? 'Example: Dice the chicken, Sauté the spices'
                          : 'Contoh: Potong ayam dadu, Tumis bumbu',
                      alignLabelWithHint: true,
                      prefixIcon: const Padding(
                        padding: EdgeInsets.only(bottom: 70),
                        child: Icon(Icons.format_list_numbered_outlined),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? (englishActive
                              ? 'Cooking steps are required'
                              : 'Langkah memasak wajib diisi')
                        : null,
                  ),
                  Text(
                    englishActive
                        ? "  *Separate each step with a comma (,)"
                        : "  *Pisahkan tiap langkah menggunakan tanda koma (,)",
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  const SizedBox(height: 20),

                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(
                        color: isDarkMode ? Colors.white24 : Colors.black12,
                      ),
                    ),
                    color: theme.primaryColor.withOpacity(0.03),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      child: DropdownButtonFormField<String>(
                        initialValue: selectedSuitableDiet,
                        disabledHint: Text(
                          _getCleanDietLabel(
                            selectedSuitableDiet,
                            englishActive,
                          ),
                          style: TextStyle(
                            color: isDarkMode ? Colors.white60 : Colors.black54,
                          ),
                        ),
                        decoration: InputDecoration(
                          labelText: englishActive
                              ? 'Suitable For Diet Program'
                              : 'Cocok Untuk Program Diet',
                          border: InputBorder.none,
                          icon: const Icon(
                            Icons.check_circle_outline,
                            color: Colors.green,
                            size: 22,
                          ),
                        ),
                        items: widget.isEditing
                            ? null
                            : widget.dietOptions.map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(
                                    _getCleanDietLabel(value, englishActive),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                );
                              }).toList(),
                        onChanged: widget.isEditing
                            ? null
                            : (newValue) {
                                setState(() {
                                  selectedSuitableDiet = newValue!;
                                });
                              },
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          List<String> ingList = ingredientsController.text
                              .split(',')
                              .map((e) => e.trim())
                              .where((e) => e.isNotEmpty)
                              .toList();
                          List<String> insList = instructionsController.text
                              .split(',')
                              .map((e) => e.trim())
                              .where((e) => e.isNotEmpty)
                              .toList();

                          widget.onPublish(
                            titleController.text.trim(),
                            int.tryParse(calorieController.text) ?? 0,
                            ingList,
                            insList,
                            selectedSuitableDiet,
                            widget.initialUnsuitable ?? 'None',
                            _selectedImages,
                          );
                          Navigator.pop(context);
                        }
                      },
                      child: Text(
                        widget.isEditing
                            ? (englishActive
                                  ? 'Save Changes'
                                  : 'Simpan Perubahan')
                            : (englishActive
                                  ? 'Publish Recipe Now'
                                  : 'Publish Resep Sekarang'),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
