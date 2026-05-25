import 'package:flutter/material.dart';

class ReplyTextHighlighter extends StatelessWidget {
  final String text;
  const ReplyTextHighlighter({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    // Mengambil warna dari DefaultTextStyle agar otomatis putih/hitam
    final defaultStyle = DefaultTextStyle.of(context).style;

    return RichText(
      text: TextSpan(
        children: text.split(' ').map((word) {
          if (word.startsWith('@')) {
            return TextSpan(
              text: "$word ",
              style: const TextStyle(
                color: Colors.blue,
                fontWeight: FontWeight.bold,
              ),
            );
          }
          // Menggunakan warna yang sama dengan teks sekitarnya
          return TextSpan(
            text: "$word ",
            style: TextStyle(color: defaultStyle.color),
          );
        }).toList(),
      ),
    );
  }
}
