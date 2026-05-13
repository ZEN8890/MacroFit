import 'package:flutter/material.dart';
import 'dart:async';

class DailyInsightCarousel extends StatefulWidget {
  const DailyInsightCarousel({super.key});

  @override
  State<DailyInsightCarousel> createState() => _DailyInsightCarouselState();
}

class _DailyInsightCarouselState extends State<DailyInsightCarousel> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;

  // List 8 Informasi untuk Carousel
  final List<Map<String, String>> _insights = [
    {
      "title": "Tips Diet: High Protein",
      "desc":
          "Protein membantu memperbaiki jaringan otot. Cobalah dada ayam atau tempe.",
      "icon": "🍗",
    },
    {
      "title": "Saran Olahraga",
      "desc":
          "Jalan santai 30 menit setelah makan membantu kontrol gula darah.",
      "icon": "👟",
    },
    {
      "title": "Stay Hydrated",
      "desc":
          "Minum 500ml air setelah bangun tidur untuk mengaktifkan metabolisme.",
      "icon": "💧",
    },
    {
      "title": "Motivasi Hari Ini",
      "desc":
          "Disiplin adalah jembatan antara target dan pencapaian. Semangat Steven!",
      "icon": "🚀",
    },
    {
      "title": "Kualitas Tidur",
      "desc":
          "Tidur 7-8 jam sangat krusial untuk pemulihan hormon pembakar lemak.",
      "icon": "😴",
    },
    {
      "title": "Tips Sayuran",
      "desc":
          "Sayuran hijau mengandung serat tinggi yang membuat kenyang lebih lama.",
      "icon": "🥦",
    },
    {
      "title": "Hindari Gula",
      "desc": "Gula berlebih adalah penyebab utama penumpukan lemak visceral.",
      "icon": "🚫",
    },
    {
      "title": "Konsistensi",
      "desc":
          "Hasil besar datang dari kebiasaan kecil yang dilakukan setiap hari.",
      "icon": "🔥",
    },
  ];

  @override
  void initState() {
    super.initState();
    // Setup Auto-play setiap 5 detik
    _timer = Timer.periodic(const Duration(seconds: 5), (Timer timer) {
      if (_currentPage < _insights.length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }

      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeIn,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _showFullInsight(BuildContext context, Map<String, String> item) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: theme.colorScheme.surface,
        title: Row(
          children: [
            Text(item['icon']!, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                item['title']!,
                style: TextStyle(color: theme.primaryColor, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Text(
          item['desc']!,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontSize: 16,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Tutup", style: TextStyle(color: theme.primaryColor)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        SizedBox(
          height: 110, // Ketinggian card sedikit diperkecil agar compact
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (page) => setState(() => _currentPage = page),
            itemCount: _insights.length,
            itemBuilder: (context, index) {
              final item = _insights[index];
              return GestureDetector(
                onTap: () => _showFullInsight(context, item),
                child: _buildBannerItem(item, theme, isDark),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        // Indicator Titik-titik
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _insights.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              height: 6,
              width: _currentPage == index ? 16 : 6,
              decoration: BoxDecoration(
                color: _currentPage == index
                    ? theme.primaryColor
                    : theme.primaryColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBannerItem(
    Map<String, String> item,
    ThemeData theme,
    bool isDark,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Text(item['icon']!, style: const TextStyle(fontSize: 26)),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  item['title']!,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.primaryColor,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item['desc']!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
