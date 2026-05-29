import 'package:flutter/material.dart';
import 'dart:async';
import '../utils/global_state.dart'; // 🟢 IMPORT SAKLAR GLOBAL STATE

class DailyInsightCarousel extends StatefulWidget {
  const DailyInsightCarousel({super.key});

  @override
  State<DailyInsightCarousel> createState() => _DailyInsightCarouselState();
}

class _DailyInsightCarouselState extends State<DailyInsightCarousel> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;

  // 🟢 DATA DWI-BAHASA: Menyediakan versi EN langsung di dalam struktur Map lokal
  final List<Map<String, String>> _insights = [
    {
      "title": "Tips Diet: High Protein",
      "titleEn": "Diet Tips: High Protein",
      "desc":
          "Protein membantu memperbaiki jaringan otot. Cobalah dada ayam atau tempe.",
      "descEn":
          "Protein helps repair muscle tissue. Try chicken breast or tempeh.",
      "icon": "🍗",
    },
    {
      "title": "Saran Olahraga",
      "titleEn": "Workout Advice",
      "desc":
          "Jalan santai 30 menit setelah makan membantu kontrol gula darah.",
      "descEn":
          "A light 30-minute walk after meals helps control blood sugar levels.",
      "icon": "👟",
    },
    {
      "title": "Stay Hydrated",
      "titleEn": "Stay Hydrated",
      "desc":
          "Minum 500ml air setelah bangun tidur untuk mengaktifkan metabolisme.",
      "descEn":
          "Drink 500ml of water right after waking up to kickstart your metabolism.",
      "icon": "💧",
    },
    {
      "title": "Motivasi Hari Ini",
      "titleEn": "Today's Motivation",
      "desc":
          "Disiplin adalah jembatan antara target dan pencapaian. Semangat Steven!",
      "descEn":
          "Discipline is the bridge between goals and accomplishment. Keep it up, Steven!",
      "icon": "🚀",
    },
    {
      "title": "Kualitas Tidur",
      "titleEn": "Sleep Quality",
      "desc":
          "Tidur 7-8 jam sangat krusial untuk pemulihan hormon pembakar lemak.",
      "descEn":
          "Getting 7-8 hours of sleep is crucial for fat-burning hormone recovery.",
      "icon": "😴",
    },
    {
      "title": "Tips Sayuran",
      "titleEn": "Vegetable Tips",
      "desc":
          "Sayuran hijau mengandung serat tinggi yang membuat kenyang lebih lama.",
      "descEn":
          "Green vegetables are high in fiber, keeping you full for longer.",
      "icon": "🥦",
    },
    {
      "title": "Hindari Gula",
      "titleEn": "Avoid Sugar",
      "desc": "Gula berlebih adalah penyebab utama penumpukan lemak visceral.",
      "descEn":
          "Excess sugar is the leading cause of visceral fat accumulation.",
      "icon": "🚫",
    },
    {
      "title": "Konsistensi",
      "titleEn": "Consistency",
      "desc":
          "Hasil besar datang dari kebiasaan kecil yang dilakukan setiap hari.",
      "descEn":
          "Great results come from small habits built consistently every single day.",
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

  void _showFullInsight(
    BuildContext context,
    Map<String, String> item,
    bool isEnglish,
  ) {
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
                isEnglish ? item['titleEn']! : item['title']!,
                style: TextStyle(color: theme.primaryColor, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Text(
          isEnglish ? item['descEn']! : item['desc']!,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontSize: 16,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              isEnglish ? "Close" : "Tutup",
              style: TextStyle(color: theme.primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // 🟢 REAKTIF MULTI-BAHASA: Membungkus komparasi visual halaman dengan ValueListenableBuilder
    return ValueListenableBuilder<bool>(
      valueListenable: isEnglishNotifier,
      builder: (context, englishActive, child) {
        return Column(
          children: [
            SizedBox(
              height: 110,
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (page) => setState(() => _currentPage = page),
                itemCount: _insights.length,
                itemBuilder: (context, index) {
                  final item = _insights[index];
                  return GestureDetector(
                    onTap: () => _showFullInsight(context, item, englishActive),
                    child: _buildBannerItem(item, theme, isDark, englishActive),
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
      },
    );
  }

  Widget _buildBannerItem(
    Map<String, String> item,
    ThemeData theme,
    bool isDark,
    bool isEnglish,
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
                  isEnglish ? item['titleEn']! : item['title']!,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.primaryColor,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isEnglish ? item['descEn']! : item['desc']!,
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
