import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../services/database_services.dart';
import '../utils/global_state.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  String selectedFilter = 'Harian';
  DateTime? customDate;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2025),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        customDate = picked;
        selectedFilter = 'Custom';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final user = FirebaseAuth.instance.currentUser;

    return ValueListenableBuilder<bool>(
      valueListenable: isEnglishNotifier,
      builder: (context, englishActive, child) {
        if (selectedFilter == 'Harian' && englishActive) {
          selectedFilter = 'Daily';
        }
        if (selectedFilter == 'Daily' && !englishActive) {
          selectedFilter = 'Harian';
        }
        if (selectedFilter == 'Mingguan' && englishActive) {
          selectedFilter = 'Weekly';
        }
        if (selectedFilter == 'Weekly' && !englishActive) {
          selectedFilter = 'Mingguan';
        }
        if (selectedFilter == 'Tahunan' && englishActive) {
          selectedFilter = 'Yearly';
        }
        if (selectedFilter == 'Yearly' && !englishActive) {
          selectedFilter = 'Tahunan';
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(
              englishActive ? "Statistics & History" : "Statistik & Riwayat",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          body: user == null
              ? Center(
                  child: Text(
                    englishActive ? "Please login first" : "Silakan login",
                  ),
                )
              : StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .snapshots(),
                  builder: (context, userSnapshot) {
                    if (userSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                      return Center(
                        child: Text(
                          englishActive
                              ? "User profile not found"
                              : "Profil user tidak ditemukan",
                        ),
                      );
                    }

                    var userData =
                        userSnapshot.data!.data() as Map<String, dynamic>;
                    final String internalDbFilter = selectedFilter == 'Daily'
                        ? 'Harian'
                        : selectedFilter == 'Weekly'
                        ? 'Mingguan'
                        : selectedFilter == 'Yearly'
                        ? 'Tahunan'
                        : selectedFilter;

                    return StreamBuilder<QuerySnapshot>(
                      stream: DatabaseService().getFilteredFoodLogs(
                        user.uid,
                        internalDbFilter,
                        customDate,
                      ),
                      builder: (context, foodSnapshot) {
                        if (foodSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        List<QueryDocumentSnapshot> docs =
                            foodSnapshot.data?.docs ?? [];

                        return ListView(
                          padding: const EdgeInsets.all(20),
                          children: [
                            // Filter
                            _buildFilterSegment(colorScheme, englishActive),
                            const SizedBox(height: 25),

                            //Statistic Chart
                            _buildDynamicChart(
                              docs,
                              userData,
                              colorScheme,
                              englishActive,
                            ),
                            const SizedBox(height: 30),

                            //History list
                            Text(
                              englishActive
                                  ? "Consumption List (${docs.length})"
                                  : "Daftar Konsumsi (${docs.length})",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 15),

                            if (docs.isEmpty)
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 40),
                                  child: Text(
                                    englishActive
                                        ? "No food history found for this period."
                                        : "Tidak ada riwayat makanan pada periode ini.",
                                  ),
                                ),
                              )
                            else
                              _buildFoodList(docs, colorScheme, englishActive),
                          ],
                        );
                      },
                    );
                  },
                ),
        );
      },
    );
  }

  Widget _buildFilterSegment(ColorScheme colorScheme, bool englishActive) {
    List<String> filters = englishActive
        ? ['Daily', 'Weekly', 'Yearly']
        : ['Harian', 'Mingguan', 'Tahunan'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          ...filters.map((filter) {
            bool isSelected = selectedFilter == filter;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() {
                  selectedFilter = filter;
                  customDate = null;
                }),
                child: Container(
                  height: 35,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? colorScheme.primary
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      filter,
                      style: TextStyle(
                        color: isSelected
                            ? colorScheme.onPrimary
                            : colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
          IconButton(
            icon: Icon(
              Icons.calendar_month,
              color: selectedFilter == 'Custom'
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
            ),
            onPressed: () => _selectDate(context),
          ),
        ],
      ),
    );
  }

  Widget _buildDynamicChart(
    List<QueryDocumentSnapshot> docs,
    Map<String, dynamic> userData,
    ColorScheme colorScheme,
    bool englishActive,
  ) {
    String labelX = selectedFilter == 'Custom' && customDate != null
        ? DateFormat('dd MMM').format(customDate!)
        : selectedFilter;

    double targetCalorieBaseline = (userData['target_calories'] ?? 2000)
        .toDouble();

    List<FlSpot> spots = [];
    List<String> xLabels = [];

    List<QueryDocumentSnapshot> sortedDocs = List.from(docs.reversed);

    if (selectedFilter == 'Harian' ||
        selectedFilter == 'Daily' ||
        (selectedFilter == 'Custom' && sortedDocs.isNotEmpty)) {
      double runningTotal = 0;
      for (int i = 0; i < sortedDocs.length; i++) {
        var data = sortedDocs[i].data() as Map<String, dynamic>;
        double calories = (data['calories'] ?? 0).toDouble();

        runningTotal += calories;
        spots.add(FlSpot(i.toDouble(), runningTotal));

        Timestamp? ts = data['timestamp'] as Timestamp?;
        String timeLabel = ts != null
            ? DateFormat('HH:mm').format(ts.toDate())
            : '';
        xLabels.add(timeLabel);
      }
    } else {
      Map<String, double> dailyCaloriesGroup = {};
      for (var doc in sortedDocs) {
        var data = doc.data() as Map<String, dynamic>;
        Timestamp? timestamp = data['timestamp'] as Timestamp?;
        if (timestamp != null) {
          String dateKey = DateFormat('yyyy-MM-dd').format(timestamp.toDate());
          double calories = (data['calories'] ?? 0).toDouble();
          dailyCaloriesGroup[dateKey] =
              (dailyCaloriesGroup[dateKey] ?? 0) + calories;
        }
      }

      List<String> datesLabel = dailyCaloriesGroup.keys.toList();
      for (int i = 0; i < datesLabel.length; i++) {
        double totalCaloriesToday = dailyCaloriesGroup[datesLabel[i]]!;
        spots.add(FlSpot(i.toDouble(), totalCaloriesToday));

        DateTime parsedDate = DateTime.parse(datesLabel[i]);
        xLabels.add(DateFormat('dd MMM').format(parsedDate));
      }
    }

    if (spots.isEmpty) {
      spots = [const FlSpot(0, 0)];
      xLabels = [''];
    }

    double highestSpotValue = spots
        .map((e) => e.y)
        .reduce((a, b) => a > b ? a : b);
    double maxYValue =
        (highestSpotValue > targetCalorieBaseline
            ? highestSpotValue
            : targetCalorieBaseline) +
        500;

    return Container(
      height: 290,
      padding: const EdgeInsets.fromLTRB(10, 20, 20, 10),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 10),
            child: Text(
              englishActive
                  ? "Calorie Intake ($labelX)"
                  : "Intake Kalori ($labelX)",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: maxYValue,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: colorScheme.outlineVariant,
                    strokeWidth: 0.5,
                  ),
                ),
                extraLinesData: ExtraLinesData(
                  horizontalLines: [
                    HorizontalLine(
                      y: targetCalorieBaseline,
                      color: Colors.red.withValues(alpha: 0.8),
                      strokeWidth: 2,
                      dashArray: [5, 5],
                      label: HorizontalLineLabel(
                        show: true,
                        alignment: Alignment.topRight,
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                        labelResolver: (line) => englishActive
                            ? "Target: ${line.y.toInt()} kcal"
                            : "Target: ${line.y.toInt()} kkal",
                      ),
                    ),
                  ],
                ),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 45,
                      getTitlesWidget: (value, meta) {
                        if (value % 1000 == 0 && value != 0) {
                          return Text(
                            "${value.toInt()}",
                            style: const TextStyle(
                              fontSize: 9,
                              color: Colors.grey,
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        int index = value.toInt();
                        if (index >= 0 && index < xLabels.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 5),
                            child: Text(
                              xLabels[index],
                              style: const TextStyle(
                                fontSize: 8,
                                color: Colors.grey,
                              ),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: spots.length > 1,
                    color: colorScheme.primary,
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: colorScheme.primary.withValues(alpha: 0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFoodList(
    List<QueryDocumentSnapshot> docs,
    ColorScheme colorScheme,
    bool englishActive,
  ) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: docs.length,
      itemBuilder: (context, index) {
        var meal = docs[index].data() as Map<String, dynamic>;
        DateTime date = (meal['timestamp'] as Timestamp? ?? Timestamp.now())
            .toDate();
        String formattedDate = DateFormat('dd MMM, HH:mm').format(date);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: BorderSide(color: colorScheme.outlineVariant),
          ),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.fastfood, color: colorScheme.primary, size: 20),
            ),
            title: Text(
              meal['food_name'] ?? (englishActive ? "Food" : "Makanan"),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              englishActive
                  ? "$formattedDate\nP: ${meal['protein']}g | C: ${meal['carbs']}g | F: ${meal['fats']}g"
                  : "$formattedDate\nP: ${meal['protein']}g | K: ${meal['carbs']}g | L: ${meal['fats']}g",
            ),
            isThreeLine: true,
            trailing: Text(
              "${meal['calories']} kcal",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
                fontSize: 15,
              ),
            ),
          ),
        );
      },
    );
  }
}
