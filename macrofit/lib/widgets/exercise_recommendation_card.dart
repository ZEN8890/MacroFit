import 'package:flutter/material.dart';
import '../utils/global_state.dart'; // 🟢 IMPORT SAKLAR GLOBAL STATE

class ExerciseRecommendationCard extends StatelessWidget {
  final String dietCode;

  const ExerciseRecommendationCard({super.key, required this.dietCode});

  // 🔥 FUNGSI MODULAR: Menampilkan Popup Detail Panduan Olahraga Mingguan
  void _showDetailedExercisePlan(
    BuildContext context,
    Map<String, dynamic> plan,
    bool isEnglish,
  ) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    final List<Map<String, String>> activeSchedule = isEnglish
        ? List<Map<String, String>>.from(plan['scheduleEn'])
        : List<Map<String, String>>.from(plan['schedule']);

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
            key: const Key('detailed_exercise_bottom_sheet'),
            mainAxisSize: MainAxisSize.min,
            children: [
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
                          Text(
                            isEnglish
                                ? "Specialized Workout Guide"
                                : "Panduan Latihan Khusus",
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            isEnglish ? plan['typeEn'] : plan['type'],
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
              const Divider(),

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
                          isEnglish ? "Intensity" : "Intensitas",
                          isEnglish ? plan['intensityEn'] : plan['intensity'],
                          Icons.bolt,
                          plan['color'],
                        ),
                        _buildPopupMetaItem(
                          isEnglish ? "Frequency" : "Frekuensi",
                          isEnglish ? plan['freqEn'] : plan['freq'],
                          Icons.calendar_month,
                          plan['color'],
                        ),
                        _buildPopupMetaItem(
                          isEnglish ? "Duration" : "Durasi Sesi",
                          isEnglish ? plan['durationEn'] : plan['duration'],
                          Icons.timer_outlined,
                          plan['color'],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    Text(
                      isEnglish
                          ? "Weekly Schedule Calendar"
                          : "Kalender Jadwal Mingguan",
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Generator List Rencana Hari Senin - Minggu
                    ...activeSchedule.map((dayPlan) {
                      final bool isRest =
                          dayPlan['activity'] == 'Rest Day' ||
                          dayPlan['activity'] == 'Hari Istirahat';
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
                              width: 85,
                              padding: const EdgeInsets.symmetric(
                                vertical: 4,
                                horizontal: 4,
                              ),
                              decoration: BoxDecoration(
                                color: isRest
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
                                  color: isRest ? Colors.grey : plan['color'],
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
                                      padding: const EdgeInsets.only(top: 4.0),
                                      child: Text(
                                        dayPlan['details']!,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                          height: 1.4,
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
                  style: const TextStyle(
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    Map<String, dynamic> plan;

    switch (dietCode) {
      case 'Menurunkan Berat Badan':
      case 'weight_loss':
        plan = {
          'type': "Kombinasi HIIT & Latihan Beban",
          'typeEn': "HIIT & Weight Training Combo",
          'freq': "4-5x / minggu",
          'freqEn': "4-5x / week",
          'duration': "45-60 mnt",
          'durationEn': "45-60 mins",
          'intensity': "Tinggi",
          'intensityEn': "High",
          'icon': Icons.local_fire_department_rounded,
          'color': Colors.orangeAccent,
          'tip':
              "HIIT mempercepat pembakaran lemak bahkan setelah olahraga selesai (Afterburn effect).",
          'tipEn':
              "HIIT accelerates fat burn even after your workout is over (Afterburn effect).",
          'schedule': [
            {
              'day': 'Senin',
              'activity': 'Full Body HIIT',
              'details':
                  '3 Set Sirkuit (Burpees x 15, Jumping Jacks x 30, Mountain Climbers x 20, Rest 60s).',
            },
            {
              'day': 'Selasa',
              'activity': 'Latihan Beban Upper Body',
              'details':
                  'Push Up (4 Set x 12 Reps), Dumbbell Rows (4 Set x 12 Reps), Incline Press (3 Set x 15 Reps).',
            },
            {
              'day': 'Rabu',
              'activity': 'Hari Istirahat',
              'details':
                  'Istirahat total untuk pemulihan jaringan otot harian.',
            },
            {
              'day': 'Kamis',
              'activity': 'Lower Body HIIT & Core',
              'details':
                  'Bodyweight Squats (4 Set x 20 Reps), Lunges (3 Set x 15 Reps), Plank (3 Set x 60 Detik).',
            },
            {
              'day': 'Jumat',
              'activity': 'Kardio Lari LISS',
              'details':
                  'Jogging santai dengan kecepatan konstan sejauh 4-5 km (Menjaga detak jantung).',
            },
            {
              'day': 'Sabtu',
              'activity': 'Pemulihan Aktif',
              'details':
                  'Jalan kaki santai selama 30 menit atau yoga peregangan tubuh.',
            },
            {
              'day': 'Minggu',
              'activity': 'Hari Istirahat',
              'details':
                  'Istirahat penuh untuk mempersiapkan siklus kebugaran minggu depan.',
            },
          ],
          'scheduleEn': [
            {
              'day': 'Monday',
              'activity': 'Full Body HIIT',
              'details':
                  '3 Circuit Sets (Burpees x 15, Jumping Jacks x 30, Mountain Climbers x 20, Rest 60s).',
            },
            {
              'day': 'Tuesday',
              'activity': 'Upper Body Weights',
              'details':
                  'Push Ups (4 Sets x 12 Reps), Dumbbell Rows (4 Sets x 12 Reps), Incline Press (3 Sets x 15 Reps).',
            },
            {
              'day': 'Wednesday',
              'activity': 'Rest Day',
              'details': 'Total recovery to repair muscle tissue.',
            },
            {
              'day': 'Thursday',
              'activity': 'Lower Body & Core',
              'details':
                  'Bodyweight Squats (4 Sets x 20 Reps), Lunges (3 Sets x 15 Reps), Plank (3 Sets x 60 Seconds).',
            },
            {
              'day': 'Friday',
              'activity': 'LISS Cardio Run',
              'details':
                  'Steady-state jogging for 4-5 km (Maintaining optimal fat-burn heart rate).',
            },
            {
              'day': 'Saturday',
              'activity': 'Active Recovery',
              'details':
                  '30-minute light walking or full body stretching yoga.',
            },
            {
              'day': 'Sunday',
              'activity': 'Rest Day',
              'details':
                  'Full rest to prepare for next week\'s physical cycle.',
            },
          ],
        };
        break;
      case 'gain_muscle':
        plan = {
          'type': "Latihan Beban Hypertrophy",
          'typeEn': "Hypertrophy Resistance Training",
          'freq': "5x / minggu",
          'freqEn': "5x / week",
          'duration': "60-75 mnt",
          'durationEn': "60-75 mins",
          'intensity': "Beban Berat",
          'intensityEn': "Heavy Load",
          'icon': Icons.fitness_center_rounded,
          'color': Colors.redAccent,
          'tip':
              "Fokus pada progres beban berkala (Progressive Overload) dan istirahat otot 48 jam.",
          'tipEn':
              "Focus on Progressive Overload and ensure 48 hours of rest between same muscle groups.",
          'schedule': [
            {
              'day': 'Senin',
              'activity': 'Push Day (Dada, Bahu, Tricep)',
              'details':
                  'Dumbbell Bench Press (4 Set x 10 Reps), Overhead Barbell Press (4 Set x 8 Reps), Tricep Pushdown (3 Set x 12 Reps).',
            },
            {
              'day': 'Selasa',
              'activity': 'Pull Day (Punggung & Bicep)',
              'details':
                  'Lat Pulldown (4 Set x 10 Reps), Bent-Over Barbell Row (4 Set x 8 Reps), Barbell Bicep Curl (3 Set x 12 Reps).',
            },
            {
              'day': 'Rabu',
              'activity': 'Leg Day (Paha & Betis)',
              'details':
                  'Barbell Squat (4 Set x 8 Reps), Romanian Deadlift (4 Set x 10 Reps), Leg Press (3 Set x 12 Reps).',
            },
            {
              'day': 'Kamis',
              'activity': 'Hari Istirahat',
              'details': 'Fokus pemulihan. Otot bertumbuh saat diistirahatkan.',
            },
            {
              'day': 'Jumat',
              'activity': 'Upper Body (Hypertrophy Focus)',
              'details':
                  'Incline Dumbbell Fly (3 Set x 12 Reps), Pull Up (4 Set x Max Reps), Lateral Raise (4 Set x 15 Reps).',
            },
            {
              'day': 'Sabtu',
              'activity': 'Lower Body & Core Focus',
              'details':
                  'Bulgarian Split Squat (3 Set x 12 Reps), Hanging Leg Raise (4 Set x 15 Reps).',
            },
            {
              'day': 'Minggu',
              'activity': 'Hari Istirahat',
              'details':
                  'Istirahat total, optimalkan asupan protein makro harian.',
            },
          ],
          'scheduleEn': [
            {
              'day': 'Monday',
              'activity': 'Push Day (Chest, Shoulders, Triceps)',
              'details':
                  'Dumbbell Bench Press (4 Sets x 10 Reps), Overhead Barbell Press (4 Sets x 8 Reps), Triceps Pushdown (3 Sets x 12 Reps).',
            },
            {
              'day': 'Tuesday',
              'activity': 'Pull Day (Back & Biceps)',
              'details':
                  'Lat Pulldown (4 Sets x 10 Reps), Bent-Over Barbell Row (4 Sets x 8 Reps), Barbell Bicep Curl (3 Sets x 12 Reps).',
            },
            {
              'day': 'Wednesday',
              'activity': 'Leg Day (Quads, Hamstrings, Calves)',
              'details':
                  'Barbell Squat (4 Sets x 8 Reps), Romanian Deadlift (4 Sets x 10 Reps), Leg Press (3 Sets x 12 Reps).',
            },
            {
              'day': 'Thursday',
              'activity': 'Rest Day',
              'details':
                  'Muscles grow during recovery and sleep, not during workouts.',
            },
            {
              'day': 'Friday',
              'activity': 'Upper Body Hypertrophy',
              'details':
                  'Incline Dumbbell Fly (3 Sets x 12 Reps), Pull Ups (4 Sets x Max Reps), Lateral Raises (4 Sets x 15 Reps).',
            },
            {
              'day': 'Saturday',
              'activity': 'Lower Body & Core',
              'details':
                  'Bulgarian Split Squat (3 Sets x 12 Reps), Hanging Leg Raise (4 Sets x 15 Reps).',
            },
            {
              'day': 'Sunday',
              'activity': 'Rest Day',
              'details':
                  'Full recovery, maximize daily protein and macronutrient synthesis.',
            },
          ],
        };
        break;
      case 'keto_diet':
        plan = {
          'type': "Kardio Rendah Zona 2",
          'typeEn': "Zone 2 Low-Intensity Cardio",
          'freq': "3-4x / minggu",
          'freqEn': "3-4x / week",
          'duration': "40-60 mnt",
          'durationEn': "40-60 mins",
          'intensity': "Rendah-Sedang",
          'intensityEn': "Low-Moderate",
          'icon': Icons.directions_bike_rounded,
          'color': Colors.blueAccent,
          'tip':
              "Dalam kondisi ketosis, olahraga durasi lama berintensitas rendah sangat efektif membakar lemak.",
          'tipEn':
              "In a state of ketosis, prolonged low-intensity exercise maximizes fat oxidation efficiency.",
          'schedule': [
            {
              'day': 'Senin',
              'activity': 'Treadmill Incline Walk',
              'details':
                  'Jalan cepat dengan sudut kemiringan tinggi selama 45 menit (Jaga detak jantung Zona 2).',
            },
            {
              'day': 'Selasa',
              'activity': 'Latihan Beban Ringan Full Body',
              'details':
                  'Goblet Squat (3 Set x 12 Reps), Dumbbell Shoulder Press (3 Set x 12 Reps), Plank (3 Set x 45 Detik).',
            },
            {
              'day': 'Rabu',
              'activity': 'Hari Istirahat',
              'details':
                  'Istirahat penuh, jaga hidrasi tubuh dan asupan elektrolit.',
            },
            {
              'day': 'Kamis',
              'activity': 'Bersepeda Statis',
              'details':
                  'Gowes dengan resistansi sedang selama 50 menit secara konstan.',
            },
            {
              'day': 'Jumat',
              'activity': 'Berenang Aerobik',
              'details':
                  'Berenang gaya bebas dengan santai selama 40 menit tanpa jeda berat.',
            },
            {
              'day': 'Sabtu',
              'activity': 'Hari Istirahat',
              'details':
                  'Pemulihan tubuh total dari penyesuaian metabolisme lemak.',
            },
            {
              'day': 'Minggu',
              'activity': 'Hari Istirahat',
              'details': 'Istirahat santai.',
            },
          ],
          'scheduleEn': [
            {
              'day': 'Monday',
              'activity': 'Treadmill Incline Walk',
              'details':
                  'Brisk walking on high incline for 45 minutes (Targeting fat-burn Zone 2).',
            },
            {
              'day': 'Tuesday',
              'activity': 'Light Full Body Weights',
              'details':
                  'Goblet Squat (3 Sets x 12 Reps), Dumbbell Shoulder Press (3 Sets x 12 Reps), Plank (3 Sets x 45 Secs).',
            },
            {
              'day': 'Wednesday',
              'activity': 'Rest Day',
              'details':
                  'Ensure proper electrolyte intake and cellular hydration.',
            },
            {
              'day': 'Thursday',
              'activity': 'Stationary Cycling',
              'details': 'Maintain a steady moderate pace for 50 minutes.',
            },
            {
              'day': 'Friday',
              'activity': 'Aerobic Swimming',
              'details':
                  'Laps at a relaxed pace for 40 minutes without high-intensity stress.',
            },
            {
              'day': 'Saturday',
              'activity': 'Rest Day',
              'details':
                  'Total physical recovery to support fat-metabolism adaptation.',
            },
            {
              'day': 'Sunday',
              'activity': 'Rest Day',
              'details': 'Relaxation and metabolic reset.',
            },
          ],
        };
        break;
      case 'vegetarian':
        plan = {
          'type': "Yoga, Pilates & Kalistenik",
          'typeEn': "Yoga, Pilates & Calisthenics",
          'freq': "3-5x / minggu",
          'freqEn': "3-5x / week",
          'duration': "30-50 mnt",
          'durationEn': "30-50 mins",
          'intensity': "Sedang",
          'intensityEn': "Moderate",
          'icon': Icons.eco_rounded,
          'color': Colors.green,
          'tip':
              "Sangat baik untuk menjaga fleksibilitas dan kekuatan massa otot tanpa kelelahan berlebih.",
          'tipEn':
              "Excellent for maintaining functional flexibility and core muscular power without excessive fatigue.",
          'schedule': [
            {
              'day': 'Senin',
              'activity': 'Vinyasa Yoga Flow',
              'details':
                  'Sesi gerakan dinamis selama 40 menit untuk kelenturan dan sirkulasi darah.',
            },
            {
              'day': 'Selasa',
              'activity': 'Kalistenik Beban Tubuh',
              'details':
                  'Pull Up (3 Set x Maks), Push Up (4 Set x 15 Reps), Bodyweight Squat (4 Set x 20 Reps).',
            },
            {
              'day': 'Rabu',
              'activity': 'Hari Istirahat',
              'details': 'Istirahat, fokus pemulihan sendi.',
            },
            {
              'day': 'Kamis',
              'activity': 'Mat Pilates Core Focus',
              'details':
                  'Penguatan otot perut dan punggung bawah (Crisses, Hundred, Bird-Dog 3 Set).',
            },
            {
              'day': 'Jumat',
              'activity': 'Jogging Santai Outdoor',
              'details': 'Kardio lari santai selama 35 menit di ruang terbuka.',
            },
            {
              'day': 'Sabtu',
              'activity': 'Peregangan Mandiri & Meditasi',
              'details':
                  'Yoga restoratif untuk pelepasan ketegangan otot fascia.',
            },
            {
              'day': 'Minggu',
              'activity': 'Hari Istirahat',
              'details': 'Istirahat total.',
            },
          ],
          'scheduleEn': [
            {
              'day': 'Monday',
              'activity': 'Vinyasa Yoga Flow',
              'details':
                  '40-minute dynamic flow for flexibility, mental clarity, and blood flow.',
            },
            {
              'day': 'Tuesday',
              'activity': 'Bodyweight Calisthenics',
              'details':
                  'Pull Ups (3 Sets x Max), Push Ups (4 Sets x 15 Reps), Bodyweight Squats (4 Sets x 20 Reps).',
            },
            {
              'day': 'Wednesday',
              'activity': 'Rest Day',
              'details': 'Joint decompression and basic mobility work.',
            },
            {
              'day': 'Thursday',
              'activity': 'Mat Pilates Core Focus',
              'details':
                  'Deep core activation (Bicycle Crunches, The Hundred, Bird-Dog 3 Sets).',
            },
            {
              'day': 'Friday',
              'activity': 'Outdoor Relaxed Jog',
              'details': '35-minute low-stress cardio workout in a green park.',
            },
            {
              'day': 'Saturday',
              'activity': 'Restorative Stretch & Meditation',
              'details':
                  'Myofascial release stretching and stress-reduction block.',
            },
            {
              'day': 'Sunday',
              'activity': 'Rest Day',
              'details': 'Full weekly physical shutdown.',
            },
          ],
        };
        break;
      case 'healthy_lifestyle':
      default:
        plan = {
          'type': "Kardio Ringan & Fungsional",
          'typeEn': "Light Cardio & Functional Drill",
          'freq': "3x / minggu",
          'freqEn': "3x / week",
          'duration': "30-45 mnt",
          'durationEn': "30-45 mins",
          'intensity': "Sedang",
          'intensityEn': "Moderate",
          'icon': Icons.favorite_rounded,
          'color': Colors.pinkAccent,
          'tip':
              "Konsistensi adalah kunci. Cukup bergerak aktif untuk menjaga kebugaran jantung.",
          'tipEn':
              "Consistency is everything. Stay regularly active to maintain peak cardiovascular fitness.",
          'schedule': [
            {
              'day': 'Senin',
              'activity': 'Jogging / Jalan Cepat',
              'details':
                  'Kardio ringan selama 30 menit untuk melancarkan sirkulasi jantung.',
            },
            {
              'day': 'Selasa',
              'activity': 'Hari Istirahat',
              'details':
                  'Tetap aktif dengan target langkah minimal 5.000-7.000 langkah.',
            },
            {
              'day': 'Rabu',
              'activity': 'Latihan Sirkuit Ringan Rumahan',
              'details':
                  'Jumping Jacks (3 Set x 30s), Bodyweight Squats (3 Set x 12 Reps), Knee Pushups (3 Set x 10 Reps).',
            },
            {
              'day': 'Kamis',
              'activity': 'Hari Istirahat',
              'details': 'Istirahat santai.',
            },
            {
              'day': 'Jumat',
              'activity': 'Bersepeda atau Berenang Rekreasi',
              'details': 'Olahraga kardio santai selama 45 menit pilihan Anda.',
            },
            {
              'day': 'Sabtu',
              'activity': 'Hari Istirahat',
              'details':
                  'Jalan santai akhir pekan tanpa target beban fisik berat.',
            },
            {
              'day': 'Minggu',
              'activity': 'Hari Istirahat',
              'details': 'Istirahat penuh.',
            },
          ],
          'scheduleEn': [
            {
              'day': 'Monday',
              'activity': 'Brisk Walk / Jog',
              'details':
                  '30-minute light aerobic drill to stimulate cardiovascular health.',
            },
            {
              'day': 'Tuesday',
              'activity': 'Rest Day',
              'details':
                  'Keep active by reaching a baseline of 5,000-7,000 daily steps.',
            },
            {
              'day': 'Wednesday',
              'activity': 'Light Home Circuit',
              'details':
                  'Jumping Jacks (3 Sets x 30s), Bodyweight Squats (3 Sets x 12 Reps), Knee Pushups (3 Sets x 10 Reps).',
            },
            {
              'day': 'Thursday',
              'activity': 'Rest Day',
              'details': 'General physical recovery.',
            },
            {
              'day': 'Friday',
              'activity': 'Recreational Swim or Bike',
              'details': '45 minutes of any steady-state aerobic fun block.',
            },
            {
              'day': 'Saturday',
              'activity': 'Rest Day',
              'details':
                  'Weekend light walking without intense physical strain.',
            },
            {
              'day': 'Sunday',
              'activity': 'Rest Day',
              'details': 'Full cellular reset.',
            },
          ],
        };
        break;
    }

    return ValueListenableBuilder<bool>(
      valueListenable: isEnglishNotifier,
      builder: (context, englishActive, child) {
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: isDarkMode
                  ? Colors.white10
                  : Colors.black.withOpacity(0.04),
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () =>
                _showDetailedExercisePlan(context, plan, englishActive),
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
                        child: Icon(
                          plan['icon'],
                          color: plan['color'],
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              englishActive
                                  ? "Physical Activity Recommendation (Tap for Details)"
                                  : "Rekomendasi Aktivitas Fisik (Ketuk Detail)",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isDarkMode
                                    ? Colors.white70
                                    : Colors.black54,
                              ),
                            ),
                            Text(
                              englishActive ? plan['typeEn'] : plan['type'],
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
                        englishActive ? "FREQUENCY" : "FREKUENSI",
                        englishActive ? plan['freqEn'] : plan['freq'],
                        Icons.calendar_month,
                        theme,
                        isDarkMode,
                      ),
                      _buildInfoDetail(
                        englishActive ? "SESSION DURATION" : "DURASI SESI",
                        englishActive ? plan['durationEn'] : plan['duration'],
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
                            englishActive ? plan['tipEn'] : plan['tip'],
                            style: TextStyle(
                              fontSize: 11.5,
                              fontStyle: FontStyle.italic,
                              color: isDarkMode
                                  ? Colors.white60
                                  : Colors.black54,
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
      },
    );
  }
}
