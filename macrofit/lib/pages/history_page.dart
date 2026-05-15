import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart'; // Tambahkan package intl di pubspec.yaml jika belum ada
import '../services/database_services.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  String selectedFilter = 'Harian';
  DateTime? customDate;

  // Fungsi untuk memanggil DatePicker
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2023),
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

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Statistik & Riwayat",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: user == null
          ? const Center(child: Text("Silakan login"))
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildFilterSegment(colorScheme),
                const SizedBox(height: 25),
                _buildStatisticSection(colorScheme),
                const SizedBox(height: 30),
                Text(
                  "Daftar Konsumsi",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 15),
                _buildFoodList(user.uid, colorScheme),
              ],
            ),
    );
  }

  Widget _buildFilterSegment(ColorScheme colorScheme) {
    List<String> filters = ['Harian', 'Mingguan', 'Tahunan'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.3),
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
          }).toList(),
          // Custom Date Filter di paling kanan
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

  Widget _buildStatisticSection(ColorScheme colorScheme) {
    String labelX = selectedFilter == 'Custom' && customDate != null
        ? DateFormat('dd MMM').format(customDate!)
        : selectedFilter;

    return Container(
      height: 280, // Tambah tinggi sedikit untuk label sumbu
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
              "Intake Kalori ($labelX)",
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
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) =>
                      FlLine(color: colorScheme.outlineVariant, strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  // Sumbu Y (Kalori)
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) => Text(
                        "${value.toInt()}",
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                  // Sumbu X (Waktu)
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const days = [
                          'Sen',
                          'Sel',
                          'Rab',
                          'Kam',
                          'Jum',
                          'Sab',
                          'Min',
                        ];
                        if (value >= 0 && value < days.length) {
                          return Text(
                            days[value.toInt()],
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
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
                    spots: const [
                      FlSpot(0, 1200),
                      FlSpot(1, 1900),
                      FlSpot(2, 1500),
                      FlSpot(3, 2200),
                      FlSpot(4, 1800),
                      FlSpot(5, 2500),
                      FlSpot(6, 2100),
                    ],
                    isCurved: true,
                    color: colorScheme.primary,
                    barWidth: 4,
                    belowBarData: BarAreaData(
                      show: true,
                      color: colorScheme.primary.withOpacity(0.1),
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

  Widget _buildFoodList(String uid, ColorScheme colorScheme) {
    // Logika stream bisa dikembangkan untuk filter custom nanti setelah staycation
    return StreamBuilder<QuerySnapshot>(
      stream: DatabaseService().getTodayFoodLogs(uid),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
          return const Center(child: Text("Belum ada riwayat"));
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var meal =
                snapshot.data!.docs[index].data() as Map<String, dynamic>;
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
                side: BorderSide(color: colorScheme.outlineVariant),
              ),
              child: ListTile(
                leading: const Icon(Icons.fastfood, color: Colors.orange),
                title: Text(
                  meal['food_name'] ?? "Food",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text("${meal['calories']} kcal"),
                trailing: const Icon(Icons.chevron_right),
              ),
            );
          },
        );
      },
    );
  }
}
