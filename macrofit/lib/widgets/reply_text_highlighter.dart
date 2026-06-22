import 'package:flutter/material.dart';

class ReplyTextHighlighter extends StatelessWidget {
  final String text;
  const ReplyTextHighlighter({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
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
          return TextSpan(
            text: "$word ",
            style: TextStyle(color: defaultStyle.color),
          );
        }).toList(),
      ),
    );
  }
}
