import 'package:flutter/material.dart';

class ExerciseRecommendationCard extends StatelessWidget {
  final String dietCode;

  const ExerciseRecommendationCard({super.key, required this.dietCode});

  // 🔥 FUNGSI MODULAR: Menampilkan Popup Detail Panduan Olahraga Mingguan
  void _showDetailedExercisePlan(
    BuildContext context,
    Map<String, dynamic> plan,
  ) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Batang Kecil Top Handle BottomSheet
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              // Header Pop Up
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: plan['color'].withOpacity(0.15),
                      child: Icon(plan['icon'], color: plan['color']),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Panduan Latihan Khusus",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            plan['type'],
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Divider(),

              // Konten Detail Jadwal (Scrollable)
              Flexible(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  shrinkWrap: true,
                  children: [
                    // Informasi Ringkas Ringkasan Gizi-Olahraga
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildPopupMetaItem(
                          "Intensitas",
                          plan['intensity'],
                          Icons.bolt,
                          plan['color'],
                        ),
                        _buildPopupMetaItem(
                          "Frekuensi",
                          plan['freq'],
                          Icons.calendar_month,
                          plan['color'],
                        ),
                        _buildPopupMetaItem(
                          "Durasi Sesi",
                          plan['duration'],
                          Icons.timer_outlined,
                          plan['color'],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    const Text(
                      "Kalender Jadwal Mingguan",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Generator List Rencana Hari Seni - Minggu
                    ...(plan['schedule'] as List<Map<String, String>>).map((
                      dayPlan,
                    ) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDarkMode
                              ? Colors.white.withOpacity(0.02)
                              : Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDarkMode
                                ? Colors.white10
                                : Colors.black.withOpacity(0.03),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 80,
                              padding: const EdgeInsets.symmetric(
                                vertical: 4,
                                horizontal: 8,
                              ),
                              decoration: BoxDecoration(
                                color: dayPlan['activity'] == 'Rest Day'
                                    ? Colors.grey.withOpacity(0.15)
                                    : plan['color'].withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                dayPlan['day']!,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: dayPlan['activity'] == 'Rest Day'
                                      ? Colors.grey
                                      : plan['color'],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    dayPlan['activity']!,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (dayPlan['details']!.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2.0),
                                      child: Text(
                                        dayPlan['details']!,
                                        style: const TextStyle(
                                          fontSize: 11.5,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPopupMetaItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    // Kumpulan Data Konfigurasi Rencana Olahraga Bersasarkan Goal Onboarding
    Map<String, dynamic> plan;

    switch (dietCode) {
      case 'Menurunkan Berat Badan':
        plan = {
          'type': "Kombinasi HIIT & Latihan Beban",
          'freq': "4-5x / minggu",
          'duration': "45-60 mnt",
          'intensity': "Tinggi",
          'icon': Icons.local_fire_department_rounded,
          'color': Colors.orangeAccent,
          'tip':
              "HIIT mempercepat pembakaran lemak bahkan setelah olahraga selesai (Afterburn effect).",
          'schedule': [
            {
              'day': 'Senin',
              'activity': 'Full Body HIIT',
              'details':
                  '3 Set Berbasis sirkuit: Jumping Jacks, Burpees, Mountain Climbers.',
            },
            {
              'day': 'Selasa',
              'activity': 'Latihan Beban Mandiri',
              'details': 'Fokus Upper Body: Push Up, Dumbbell Row, Bicep Curl.',
            },
            {
              'day': 'Rabu',
              'activity': 'Rest Day',
              'details': 'Istirahat total, fokus pemulihan sendi dan otot.',
            },
            {
              'day': 'Kamis',
              'activity': 'Lower Body HIIT',
              'details': 'Squats, Lunges, Calf Raises, diakhiri Planks 3 set.',
            },
            {
              'day': 'Jumat',
              'activity': 'Kardio Lari Ringan',
              'details':
                  'Jogging stabil sejauh 3-5 km untuk ketahanan jantung.',
            },
            {
              'day': 'Sabtu',
              'activity': 'Rest & Stretch',
              'details': 'Yoga ringan atau jalan kaki santai di taman.',
            },
            {
              'day': 'Minggu',
              'activity': 'Rest Day',
              'details': 'Persiapan energi fisik untuk siklus minggu depan.',
            },
          ],
        };
        break;
      case 'gain_muscle':
        plan = {
          'type': "Latihan Beban Hypertrophy",
          'freq': "4-6x / minggu",
          'duration': "60-75 mnt",
          'intensity': "Beban Berat",
          'icon': Icons.fitness_center_rounded,
          'color': Colors.redAccent,
          'tip':
              "Fokus pada progres beban berkala (Progressive Overload) dan istirahat otot 48 jam.",
          'schedule': [
            {
              'day': 'Senin',
              'activity': 'Push Day (Dada, Bahu, Tricep)',
              'details':
                  'Bench Press, Shoulder Press, Tricep Pushdown (3-4 Set x 8-12 Reps).',
            },
            {
              'day': 'Selasa',
              'activity': 'Pull Day (Punggung & Bicep)',
              'details':
                  'Lat Pulldown, Bent-over Row, Barbell Curl (3-4 Set x 8-12 Reps).',
            },
            {
              'day': 'Rabu',
              'activity': 'Leg Day (Kaki & Core)',
              'details': 'Barbell Squat, Romanian Deadlift, Leg Press, Planks.',
            },
            {
              'day': 'Kamis',
              'activity': 'Rest & Recovery',
              'details':
                  'Wajib istirahat. Otot bertumbuh saat tidur, bukan saat latihan.',
            },
            {
              'day': 'Jumat',
              'activity': 'Upper Body Focus',
              'details': 'Incline Dumbbell Press, Pull Up, Lateral Raises.',
            },
            {
              'day': 'Sabtu',
              'activity': 'Lower Body Focus',
              'details': 'Bulgarian Split Squat, Hamstring Curls, Calf Raises.',
            },
            {
              'day': 'Minggu',
              'activity': 'Rest Day',
              'details': 'Istirahat penuh, optimalkan asupan protein harian.',
            },
          ],
        };
        break;
      case 'keto_diet':
        plan = {
          'type': "Kardio Rendah Zona 2",
          'freq': "3-4x / minggu",
          'duration': "40-60 mnt",
          'intensity': "Rendah-Sedang",
          'icon': Icons.directions_bike_rounded,
          'color': Colors.blueAccent,
          'tip':
              "Dalam kondisi ketosis, olahraga durasi lama berintensitas rendah sangat efektif membakar lemak.",
          'schedule': [
            {
              'day': 'Senin',
              'activity': 'Jalan Cepat / Treadmill Incline',
              'details':
                  'Jaga detak jantung konstan di zona pembakaran lemak (Zona 2).',
            },
            {
              'day': 'Selasa',
              'activity': 'Latihan Beban Ringan',
              'details':
                  'Gerakan dasar (Compound movements) dengan beban sedang tanpa kegagalan otot.',
            },
            {
              'day': 'Rabu',
              'activity': 'Rest Day',
              'details': 'Pemulihan energi glikogen otot.',
            },
            {
              'day': 'Kamis',
              'activity': 'Bersepeda Santai',
              'details':
                  'Gowes outdoor atau sepeda statis dalam durasi 45-60 menit.',
            },
            {
              'day': 'Jumat',
              'activity': 'Berenang Bebas',
              'details':
                  'Olahraga seluruh tubuh minim benturan sendi selama 30-45 menit.',
            },
            {
              'day': 'Sabtu',
              'activity': 'Rest & Recovery',
              'details': 'Fokus pemenuhan asupan elektrolit tubuh.',
            },
            {
              'day': 'Minggu',
              'activity': 'Rest Day',
              'details': 'Relaksasi tubuh total.',
            },
          ],
        };
        break;
      case 'vegetarian':
        plan = {
          'type': "Yoga, Pilates & Kalistenik",
          'freq': "3-5x / minggu",
          'duration': "30-50 mnt",
          'intensity': "Sedang",
          'icon': Icons.eco_rounded,
          'color': Colors.green,
          'tip':
              "Sangat baik untuk menjaga fleksibilitas dan kekuatan massa otot tanpa kelelahan berlebih.",
          'schedule': [
            {
              'day': 'Senin',
              'activity': 'Vinyasa Yoga Flow',
              'details':
                  'Meningkatkan sirkulasi oksigen dan kelenturan otot tubuh.',
            },
            {
              'day': 'Selasa',
              'activity': 'Kalistenik Dasar',
              'details':
                  'Latihan beban tubuh: Pull Up, Dips, Push Up, Bodyweight Squat.',
            },
            {
              'day': 'Rabu',
              'activity': 'Rest Day',
              'details': 'Fokus hidrasi harian.',
            },
            {
              'day': 'Kamis',
              'activity': 'Mat Pilates Session',
              'details':
                  'Penguatan otot inti (Core muscles) dan stabilitas tulang belakang.',
            },
            {
              'day': 'Jumat',
              'activity': 'Jogging Santai',
              'details':
                  'Kardio ringan outdoor selama 30 menit menikmati udara pagi.',
            },
            {
              'day': 'Sabtu',
              'activity': 'Yoga & Meditasi',
              'details':
                  'Pelepasan stres pikiran dan peregangan myofascial tubuh.',
            },
            {
              'day': 'Minggu',
              'activity': 'Rest Day',
              'details': 'Istirahat total bersama keluarga.',
            },
          ],
        };
        break;
      case 'healthy_lifestyle':
      default:
        plan = {
          'type': "Kardio Ringan & Fungsional",
          'freq': "3x / minggu",
          'duration': "30-45 mnt",
          'intensity': "Sedang",
          'icon': Icons.favorite_rounded,
          'color': Colors.pinkAccent,
          'tip':
              "Konsistensi adalah kunci. Cukup bergerak aktif untuk menjaga kebugaran jantung.",
          'schedule': [
            {
              'day': 'Senin',
              'activity': 'Jogging atau Jalan Cepat',
              'details':
                  'Durasi 30 menit untuk merangsang kebugaran kardiovaskular.',
            },
            {
              'day': 'Selasa',
              'activity': 'Rest Day',
              'details':
                  'Gunakan hari ini untuk tetap aktif berjalan kaki minimal 5000 langkah.',
            },
            {
              'day': 'Rabu',
              'activity': 'Latihan Sirkuit Rumahan',
              'details':
                  '3 Set ringan: Jamping jacks, Light Squats, Knee Pushups, Wall Sits.',
            },
            {
              'day': 'Kamis',
              'activity': 'Rest Day',
              'details': 'Istirahat optimal.',
            },
            {
              'day': 'Jumat',
              'activity': 'Berenang atau Bersepeda',
              'details':
                  'Aktivitas rekreasi aerobik yang menyenangkan selama 45 menit.',
            },
            {
              'day': 'Sabtu',
              'activity': 'Jalan Santai Akhir Pekan',
              'details':
                  'Berjalan kaki santai bersama keluarga di area terbuka hijau.',
            },
            {
              'day': 'Minggu',
              'activity': 'Rest Day',
              'details': 'Istirahat penuh untuk menyegarkan stamina fisik.',
            },
          ],
        };
        break;
    }

    // 🔥 WIDGET SEKARANG DIBALUT INKWELL AGAR BISA DIKETUK OLEH USER
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isDarkMode ? Colors.white10 : Colors.black.withOpacity(0.04),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        // 🔥 TRIGGER ACTION POP UP KETIKA KARTU DIKLIK
        onTap: () => _showDetailedExercisePlan(context, plan),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: plan['color'].withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(plan['icon'], color: plan['color'], size: 22),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Rekomendasi Aktivitas Fisik (Ketuk Detail)",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white70 : Colors.black54,
                          ),
                        ),
                        Text(
                          plan['type'],
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: Colors.grey,
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10.0),
                child: Divider(height: 1, thickness: 0.5),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildInfoDetail(
                    "FREKUENSI",
                    plan['freq'],
                    Icons.calendar_month,
                    theme,
                    isDarkMode,
                  ),
                  _buildInfoDetail(
                    "DURASI SESI",
                    plan['duration'],
                    Icons.timer_outlined,
                    theme,
                    isDarkMode,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? Colors.white.withOpacity(0.02)
                      : Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.lightbulb_outline_rounded,
                      color: Colors.amber,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        plan['tip'],
                        style: TextStyle(
                          fontSize: 11.5,
                          fontStyle: FontStyle.italic,
                          color: isDarkMode ? Colors.white60 : Colors.black54,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoDetail(
    String label,
    String value,
    IconData icon,
    ThemeData theme,
    bool isDarkMode,
  ) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, size: 16, color: theme.primaryColor.withOpacity(0.7)),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
