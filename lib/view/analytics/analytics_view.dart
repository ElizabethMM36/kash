import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:kash/common/color_extension.dart';
import 'package:kash/services/analytics_service.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final AnalyticsService _service = AnalyticsService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TColor.gray,
      appBar: AppBar(
        backgroundColor: TColor.gray80,
        elevation: 0,
        title: Text("Analytics", style: TextStyle(color: TColor.white)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildExpensePieChart(),
            const SizedBox(height: 30),
            _buildMonthlyBarChart(),
            const SizedBox(height: 30),
            _buildIncomeVsExpenseChart(),
            const SizedBox(height: 30),
            _buildCategoryAnalytics(),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // 1️⃣ Expense Breakdown Pie Chart
  // ==========================================================

  Widget _buildExpensePieChart() {
    return FutureBuilder(
      future: _service.getExpenseByCategory(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const CircularProgressIndicator();
        }

        final data = snapshot.data as Map<String, double>;

        if (data.isEmpty) {
          return _emptyCard("No expense data available");
        }

        // compute total from transactions data
        final total = data.values.fold<double>(0, (sum, x) => sum + x);
        int colorIndex = 0;
        final sections = data.entries.map((e) {
          final percent = total > 0 ? e.value / total * 100 : 0;
          final section = PieChartSectionData(
            value: e.value,
            title:
                "₹${e.value.toStringAsFixed(0)}\n${percent.toStringAsFixed(1)}%",
            radius: 60,
            color: _getCategoryColor(colorIndex),
            titleStyle: TextStyle(
              fontSize: 10,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          );
          colorIndex++;
          return section;
        }).toList();

        return _cardWrapper(
          title: "Expense Breakdown",
          child: Column(
            children: [
              SizedBox(
                height: 220,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 40,
                    sections: sections,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _buildCategoryLegend(data),
            ],
          ),
        );
      },
    );
  }

  // ==========================================================
  // 2️⃣ Monthly Spending Bar Chart
  // ==========================================================

  Widget _buildMonthlyBarChart() {
    return FutureBuilder(
      future: _service.getMonthlySpending(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const CircularProgressIndicator();
        }

        final data = snapshot.data as Map<int, double>;

        if (data.isEmpty) {
          return _emptyCard("No monthly data available");
        }

        final bars = data.entries.map((e) {
          return BarChartGroupData(
            x: e.key,
            barRods: [
              BarChartRodData(
                toY: e.value,
                width: 16,
                borderRadius: BorderRadius.circular(6),
              ),
            ],
          );
        }).toList();

        // determine max value to help interval calculations
        final maxY = data.values.fold<double>(
          0,
          (prev, x) => x > prev ? x : prev,
        );
        final interval = (maxY / 5).ceilToDouble();

        return _cardWrapper(
          title: "Monthly Spending",
          child: SizedBox(
            height: 250,
            child: BarChart(
              BarChartData(
                borderData: FlBorderData(show: false),
                gridData: FlGridData(show: false),
                barGroups: bars,
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const months = [
                          '',
                          'Jan',
                          'Feb',
                          'Mar',
                          'Apr',
                          'May',
                          'Jun',
                          'Jul',
                          'Aug',
                          'Sep',
                          'Oct',
                          'Nov',
                          'Dec',
                        ];
                        final idx = value.toInt();
                        String text = '';
                        if (idx >= 1 && idx <= 12) {
                          text = months[idx];
                        }
                        return SideTitleWidget(
                          meta: meta,
                          child: Text(
                            text,
                            style: TextStyle(color: TColor.white, fontSize: 10),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: interval,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '₹${value.toInt()}',
                          style: TextStyle(color: TColor.white, fontSize: 10),
                        );
                      },
                    ),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ==========================================================
  // 3️⃣ Income vs Expense Chart
  // ==========================================================

  Widget _buildIncomeVsExpenseChart() {
    return FutureBuilder(
      future: _service.getIncomeVsExpense(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const CircularProgressIndicator();
        }

        final data = snapshot.data as Map<String, double>;

        if (data.values.every((e) => e == 0)) {
          return _emptyCard("No income/expense data available");
        }

        final total = data.values.fold<double>(0, (s, x) => s + x);
        int colorIndex = 0;
        final sections = data.entries.map((e) {
          final percent = total > 0 ? e.value / total * 100 : 0;
          final section = PieChartSectionData(
            value: e.value,
            title:
                "₹${e.value.toStringAsFixed(0)}\n${percent.toStringAsFixed(1)}%",
            radius: 60,
            color: _getCategoryColor(colorIndex),
            titleStyle: TextStyle(
              fontSize: 10,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          );
          colorIndex++;
          return section;
        }).toList();

        return _cardWrapper(
          title: "Income vs Expense",
          child: Column(
            children: [
              SizedBox(
                height: 220,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 40,
                    sections: sections,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _buildCategoryLegend(data),
            ],
          ),
        );
      },
    );
  }

  // ==========================================================
  // 4️⃣ Category Analytics List
  // ==========================================================

  Widget _buildCategoryAnalytics() {
    return FutureBuilder(
      future: _service.getCategoryAnalytics(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const CircularProgressIndicator();
        }

        final data = snapshot.data as List<Map<String, dynamic>>;

        if (data.isEmpty) {
          return _emptyCard("No category analytics available");
        }

        return _cardWrapper(
          title: "Category Analytics",
          child: ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: data.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(
                  data[index]['category'],
                  style: TextStyle(color: TColor.white),
                ),
                trailing: Text(
                  "₹ ${data[index]['amount'].toStringAsFixed(2)}",
                  style: TextStyle(color: TColor.secondary),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // ==========================================================
  // UI Helpers
  // ==========================================================

  Color _getCategoryColor(int index) {
    // original palette (very bright) – we'll mute them by mixing with our gray
    // background color so the charts aren't glaring.
    final colors = [
      const Color(0xFFFF0000), // Pure Red
      const Color(0xFF00FF00), // Pure Green
      const Color(0xFF0000FF), // Pure Blue
      const Color(0xFFFFFF00), // Yellow
      const Color(0xFFFF00FF), // Magenta
      const Color(0xFF00FFFF), // Cyan
      const Color(0xFFFFA500), // Orange
      const Color(0xFF8000FF), // Purple
      const Color(0xFF00FF7F), // Spring Green
      const Color(0xFFFF1493), // Deep Pink
      const Color(0xFF1E90FF), // Dodger Blue
      const Color(0xFFADFF2F), // Green Yellow
    ];
    Color base = colors[index % colors.length];
    // mix 30% gray and reduce opacity slightly to tone down brightness
    return Color.lerp(base, TColor.gray, 0.3)!.withOpacity(0.75);
  }

  Widget _buildCategoryLegend(Map<String, double> data) {
    final categories = data.keys.toList();
    final total = data.values.fold<double>(0, (s, x) => s + x);
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: List.generate(categories.length, (index) {
        final key = categories[index];
        final amount = data[key] ?? 0;
        final percent = total > 0 ? amount / total * 100 : 0;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: _getCategoryColor(index),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              "$key – ₹${amount.toStringAsFixed(0)} (${percent.toStringAsFixed(1)}%)",
              style: TextStyle(
                color: TColor.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _cardWrapper({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TColor.gray80,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: TColor.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 15),
          child,
        ],
      ),
    );
  }

  Widget _emptyCard(String message) {
    return _cardWrapper(
      title: "Analytics",
      child: Text(message, style: TextStyle(color: TColor.gray30)),
    );
  }
}
