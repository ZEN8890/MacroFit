import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/notification_helper.dart';
import '../utils/global_state.dart';

class InlineBioCard extends StatefulWidget {
  final String userId;
  final String initialBio;
  final ThemeData theme;
  final bool isDarkMode;

  const InlineBioCard({
    super.key,
    required this.userId,
    required this.initialBio,
    required this.theme,
    required this.isDarkMode,
  });

  @override
  State<InlineBioCard> createState() => _InlineBioCardState();
}

class _InlineBioCardState extends State<InlineBioCard> {
  late TextEditingController _controller;
  bool _isChanged = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialBio);
  }

  @override
  void didUpdateWidget(covariant InlineBioCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialBio != oldWidget.initialBio && !_isChanged) {
      _controller.text = widget.initialBio;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
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
                      Icons.badge_outlined,
                      color: Colors.teal,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isEnglishNotifier.value
                          ? 'Bio & Identity'
                          : 'Bio & Identitas Diri',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (_isChanged)
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: widget.theme.primaryColor,
                    ),
                    icon: const Icon(Icons.check, size: 16),
                    label: Text(
                      isEnglishNotifier.value ? 'Save' : 'Simpan',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onPressed: () async {
                      try {
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(widget.userId)
                            .update({'bio': _controller.text.trim()});

                        setState(() => _isChanged = false);

                        if (mounted) {
                          Notify.success(
                            context,
                            isEnglishNotifier.value
                                ? "Bio updated successfully!"
                                : "Bio berhasil diperbarui!",
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          Notify.error(
                            context,
                            isEnglishNotifier.value
                                ? "Failed to update bio: $e"
                                : "Gagal memperbarui bio: $e",
                          );
                        }
                      }
                    },
                  ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 6),
            TextField(
              controller: _controller,
              minLines: 2,
              maxLines: 4,
              keyboardType: TextInputType.multiline,
              style: TextStyle(
                fontSize: 14,
                color: widget.isDarkMode ? Colors.white : Colors.black87,
              ),
              decoration: InputDecoration(
                hintText: isEnglishNotifier.value
                    ? "Tell us a bit about your diet goals here..."
                    : "Ceritakan sedikit tentang target diet Anda di sini...",
                border: InputBorder.none,
                isDense: true,
                counterText: "",
              ),
              onChanged: (text) {
                setState(() => _isChanged = text.trim() != widget.initialBio);
              },
            ),
          ],
        ),
      ),
    );
  }
}
