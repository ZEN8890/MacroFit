import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:gal/gal.dart';
import '../utils/notification_helper.dart';
import '../utils/global_state.dart'; // 🟢 IMPORT SAKLAR GLOBAL STATE

class ImagePreviewPage extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const ImagePreviewPage({
    super.key,
    required this.imageUrls,
    this.initialIndex = 0,
  });

  @override
  State<ImagePreviewPage> createState() => _ImagePreviewPageState();
}

class _ImagePreviewPageState extends State<ImagePreviewPage> {
  late PageController _pageController;
  int _currentIndex = 0;
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  Future<void> _downloadImage(String url) async {
    setState(() => _isDownloading = true);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: CircularProgressIndicator(),
          ),
        ),
      ),
    );

    try {
      // 1. Ambil bytes gambar menggunakan Dio
      var response = await Dio().get(
        url,
        options: Options(responseType: ResponseType.bytes),
      );

      final Uint8List bytes = Uint8List.fromList(response.data);

      // 2. Simpan langsung ke galeri menggunakan Gal
      await Gal.putImageBytes(bytes);

      if (mounted) Navigator.pop(context); // Tutup loading dialog

      if (mounted) {
        // 🟢 DINAMIS MULTI-BAHASA PADA NOTIFIKASI SUKSES SIMPAN
        Notify.success(
          context,
          isEnglishNotifier.value
              ? 'Image saved to gallery successfully!'
              : 'Foto berhasil disimpan ke galeri!',
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context); // Tutup loading dialog jika gagal

      if (mounted) {
        // 🟢 DINAMIS MULTI-BAHASA PADA NOTIFIKASI GAGAL SIMPAN
        Notify.error(
          context,
          isEnglishNotifier.value
              ? 'Failed to download image: $e'
              : 'Gagal mengunduh foto: $e',
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) {
        setState(() => _isDownloading = false);
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 🟢 REAKTIF MULTI-BAHASA: Membungkus halaman pratinjau gambar dengan ValueListenableBuilder
    return ValueListenableBuilder<bool>(
      valueListenable: isEnglishNotifier,
      builder: (context, englishActive, child) {
        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.download_rounded, size: 26),
                onPressed: _isDownloading
                    ? null
                    : () => _downloadImage(widget.imageUrls[_currentIndex]),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: PageView.builder(
            controller: _pageController,
            itemCount: widget.imageUrls.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return Center(
                child: InteractiveViewer(
                  clipBehavior: Clip.none,
                  minScale: 1.0,
                  maxScale: 4.0,
                  child: Image.network(
                    widget.imageUrls[index],
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
