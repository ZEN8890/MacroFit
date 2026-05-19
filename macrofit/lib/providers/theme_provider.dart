import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // 🔥 Wajib diimpor

class ThemeProvider extends ChangeNotifier {
  // Secara bawaan, kita set awal sebelum membaca memori HP
  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  // Constructor: Otomatis memanggil fungsi pembaca memori saat provider pertama kali lahir
  ThemeProvider() {
    _loadThemeFromPrefs();
  }

  // 🔥 FUNGSI UTAMA: Diperbarui agar otomatis mengunci pilihan ke memori fisik gawai
  Future<void> toggleTheme(bool isOn) async {
    _themeMode = isOn ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();

    // Simpan permanen ke storage HP
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', isOn);
  }

  // Fungsi internal untuk mengambil data tema saat aplikasi baru dinyalakan murni
  Future<void> _loadThemeFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    // Jika belum pernah disetting, default-nya bernilai false (Mode Terang)
    final bool savedIsDarkMode = prefs.getBool('isDarkMode') ?? false;

    _themeMode = savedIsDarkMode ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }
}
