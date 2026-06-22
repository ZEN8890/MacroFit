import 'package:flutter/material.dart';

//mengubah variable biasa jadi valuenotifiter
final ValueNotifier<bool> isEnglishNotifier = ValueNotifier<bool>(false);

// Getter isEnglish
bool get isEnglish => isEnglishNotifier.value;
set isEnglish(bool value) => isEnglishNotifier.value = value;
