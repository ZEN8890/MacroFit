import 'package:flutter/material.dart';

class CustomInputField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String suffix;
  final IconData icon;

  const CustomInputField({
    super.key,
    required this.label,
    required this.controller,
    required this.suffix,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        suffixText: suffix,
        border: const OutlineInputBorder(),
      ),
    );
  }
}
