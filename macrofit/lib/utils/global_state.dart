// lib/utils/global_state.dart
import 'package:flutter/material.dart';

// Mengubah variabel biasa menjadi ValueNotifier agar bisa memancarkan sinyal perubahan ke halaman lain
final ValueNotifier<bool> isEnglishNotifier = ValueNotifier<bool>(false);

// Getter pembantu agar kode 'isEnglish' lama Anda di halaman Profile tidak error
bool get isEnglish => isEnglishNotifier.value;
set isEnglish(bool value) => isEnglishNotifier.value = value;
