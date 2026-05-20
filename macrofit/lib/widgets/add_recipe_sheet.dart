import 'package:flutter/material.dart';

// 🔥 TARGET REVISI CONSTRUCTOR DI ADD_RECIPE_SHEET.DART
class AddRecipeSheet extends StatefulWidget {
  final List<String> dietOptions;
  final Function(
    String title,
    int calories,
    List<String> ingredients,
    List<String> instructions,
    String suitable,
    String unsuitable,
  )
  onPublish;

  // 🌟 SUNTIKKAN 7 PARAMETER OPSIONAL INI SEBAGAI PENAMPUNG DATA EDIT
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
    this.isEditing = false, // Default false jika hanya posting baru
  });

  @override
  State<AddRecipeSheet> createState() => _AddRecipeSheetState();
}

class _AddRecipeSheetState extends State<AddRecipeSheet> {
  final _formKey = GlobalKey<FormState>();

  // Menggunakan late agar inisialisasi controller bisa dikondisikan di initState
  late final TextEditingController titleController;
  late final TextEditingController calorieController;
  late final TextEditingController ingredientsController;
  late final TextEditingController instructionsController;

  String selectedSuitableDiet = 'healthy_lifestyle';

  @override
  void initState() {
    super.initState();

    // 1. Inisialisasi teks biasa (Judul & Kalori)
    titleController = TextEditingController(
      text: widget.isEditing ? widget.initialTitle : '',
    );
    calorieController = TextEditingController(
      text: widget.isEditing ? widget.initialCalories : '',
    );

    // 2. 🔥 PARSING STRATEGY: Ubah List<String> dari database kembali menjadi String koma (, ) agar tampil di form
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

    // 3. Inisialisasi nilai awal Dropdown gizi diet
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

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
          physics: const NeverScrollableScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Bar: Tombol Close (X) & Garis Tengah Dekorasi
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
                      tooltip: 'Kembali',
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
                  // 🔥 UX DINAMIS: Judul Header berubah otomatis mengikuti mode
                  Text(
                    widget.isEditing ? "Edit Resep Anda" : "Publish Resep Baru",
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
                    ? "Perbarui detail menu masakan sehat Anda agar tetap akurat"
                    : "Bagikan kreasi kuliner sehatmu ke komunitas MacroFit",
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const Divider(height: 24),

              // 1. Input Nama Makanan
              TextFormField(
                controller: titleController,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: 'Nama Makanan / Menu',
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
                    ? 'Nama makanan tidak boleh kosong'
                    : null,
              ),
              const SizedBox(height: 16),

              // 2. Input Estimasi Kalori
              TextFormField(
                controller: calorieController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Estimasi Kalori',
                  suffixText: 'kkal',
                  prefixIcon: const Icon(Icons.local_fire_department_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Estimasi kalori wajib diisi'
                    : null,
              ),
              const SizedBox(height: 16),

              // 3. Input Bahan-Bahan
              TextFormField(
                controller: ingredientsController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Bahan-bahan',
                  hintText: 'Contoh: 100g dada ayam, 1 sdm madu',
                  alignLabelWithHint: true,
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(bottom: 20),
                    child: Icon(Icons.shopping_basket_outlined),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  contentPadding: const EdgeInsets.all(14),
                ),
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Bahan-bahan wajib diisi'
                    : null,
              ),
              const Text(
                "  *Pisahkan tiap bahan menggunakan tanda koma (,)",
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
              const SizedBox(height: 16),

              // 4. Input Langkah Memasak
              TextFormField(
                controller: instructionsController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Cara Memasak / Langkah',
                  hintText: 'Contoh: Potong ayam dadu, Tumis bumbu',
                  alignLabelWithHint: true,
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(bottom: 20),
                    child: Icon(Icons.format_list_numbered_outlined),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  contentPadding: const EdgeInsets.all(14),
                ),
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Langkah memasak wajib diisi'
                    : null,
              ),
              const Text(
                "  *Pisahkan tiap langkah menggunakan tanda koma (,)",
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
              const SizedBox(height: 20),

              // Dropdown Pilihan Diet tunggal
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
                    value: selectedSuitableDiet,
                    decoration: const InputDecoration(
                      labelText: 'Cocok Untuk Program Diet',
                      border: InputBorder.none,
                      icon: Icon(
                        Icons.check_circle_outline,
                        color: Colors.green,
                        size: 22,
                      ),
                    ),
                    items: widget.dietOptions.map((String value) {
                      // Kosmetik lokalisasi bahasa label dropdown di layar HP
                      String displayLabel = value;
                      if (value == 'gain_muscle')
                        displayLabel = 'Menaikkan Massa Otot';
                      if (value == 'healthy_lifestyle')
                        displayLabel = 'Gaya Hidup Sehat';
                      if (value == 'keto_diet') displayLabel = 'Diet Keto';
                      if (value == 'vegetarian') displayLabel = 'Vegetarian';

                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(
                          displayLabel,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        selectedSuitableDiet = newValue!;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Tombol Submit
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
                      );
                      Navigator.pop(context);
                    }
                  },
                  // 🔥 UX DINAMIS: Label tombol berubah otomatis saat mode edit aktif
                  child: Text(
                    widget.isEditing
                        ? 'Simpan Perubahan'
                        : 'Publish Resep Sekarang',
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
  }
}
