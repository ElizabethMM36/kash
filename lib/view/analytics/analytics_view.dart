import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:kash/common/color_extension.dart';

class AnalyticsView extends StatefulWidget {
  const AnalyticsView({super.key});

  @override
  State<AnalyticsView> createState() => _AnalyticsViewState();
}

class _AnalyticsViewState extends State<AnalyticsView> {
  int touchedIndex = -1;
  String selectedTimeFilter = "This Month";
  
  // Category data - sorted by spending (descending)
  final List<Map<String, dynamic>> categoryData = [
    {"name": "Grocery", "amount": 5526.0, "percent": 30, "color": const Color(0xFF4CAF50)},
    {"name": "Bill", "amount": 4605.0, "percent": 25, "color": const Color(0xFF9C27B0)},
    {"name": "Transport", "amount": 3684.0, "percent": 20, "color": const Color(0xFF2196F3)},
    {"name": "Entertainment", "amount": 2763.0, "percent": 15, "color": const Color(0xFFF44336)},
    {"name": "Medical", "amount": 1842.0, "percent": 10, "color": const Color(0xFFFF9800)},
  ];
  
  double get totalSpent => categoryData.fold(0, (sum, item) => sum + (item["amount"] as double));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TColor.primaryBg,
      appBar: AppBar(
        backgroundColor: TColor.primaryBg,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "Analytics",
          style: TextStyle(
            color: TColor.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 1️⃣ TIME FILTER DROPDOWN
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
              decoration: BoxDecoration(
                color: TColor.gray80,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: TColor.border.withOpacity(0.3)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedTimeFilter,
                  icon: Icon(Icons.keyboard_arrow_down, color: TColor.secondary),
                  dropdownColor: TColor.gray70,
                  style: TextStyle(color: TColor.white, fontSize: 14, fontWeight: FontWeight.w600),
                  isExpanded: true,
                  items: ["This Week", "This Month", "Last Month", "Custom Range"]
                      .map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedTimeFilter = newValue!;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // 2️⃣ DONUT CHART WITH CENTER TOTAL
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: TColor.gray80,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Text(
                    "Spending by Category",
                    style: TextStyle(
                      color: TColor.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 220,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        PieChart(
                          PieChartData(
                            pieTouchData: PieTouchData(
                              touchCallback: (FlTouchEvent event, pieTouchResponse) {
                                setState(() {
                                  if (!event.isInterestedForInteractions ||
                                      pieTouchResponse == null ||
                                      pieTouchResponse.touchedSection == null) {
                                    touchedIndex = -1;
                                    return;
                                  }
                                  touchedIndex =
                                      pieTouchResponse.touchedSection!.touchedSectionIndex;
                                });
                              },
                            ),
                            borderData: FlBorderData(show: false),
                            sectionsSpace: 2,
                            centerSpaceRadius: 55,
                            sections: showingSections(),
                          ),
                        ),
                        // CENTER TOTAL
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "₹${totalSpent.toStringAsFixed(0)}",
                              style: TextStyle(
                                color: TColor.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "Total spent",
                              style: TextStyle(
                                color: TColor.gray30,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            // 6️⃣ INSIGHT CARD
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [TColor.secondary.withOpacity(0.2), TColor.secondary.withOpacity(0.05)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: TColor.secondary.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: TColor.secondary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text("🍔", style: const TextStyle(fontSize: 20)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${categoryData[0]["name"]} is your highest spending",
                          style: TextStyle(
                            color: TColor.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          "₹${categoryData[0]["amount"].toStringAsFixed(0)} this month (${categoryData[0]["percent"]}%)",
                          style: TextStyle(
                            color: TColor.gray30,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            // 3️⃣ 4️⃣ 5️⃣ CLICKABLE CATEGORY LIST (Sorted, with Amount + %)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: TColor.gray80,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Categories",
                    style: TextStyle(
                      color: TColor.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 15),
                  ...categoryData.asMap().entries.map((entry) {
                    int index = entry.key;
                    var cat = entry.value;
                    bool isSelected = touchedIndex == index;
                    return _buildCategoryItem(
                      color: cat["color"],
                      title: cat["name"],
                      amount: cat["amount"],
                      percent: cat["percent"],
                      isSelected: isSelected,
                      onTap: () {
                        setState(() {
                          touchedIndex = touchedIndex == index ? -1 : index;
                        });
                      },
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> showingSections() {
    return categoryData.asMap().entries.map((entry) {
      int index = entry.key;
      var cat = entry.value;
      final isTouched = index == touchedIndex;
      final fontSize = isTouched ? 16.0 : 12.0;
      final radius = isTouched ? 55.0 : 45.0;
      const shadows = [Shadow(color: Colors.black, blurRadius: 2)];
      
      return PieChartSectionData(
        color: cat["color"],
        value: cat["percent"].toDouble(),
        title: isTouched ? '${cat["percent"]}%' : '',
        radius: radius,
        titleStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: TColor.white,
          shadows: shadows,
        ),
      );
    }).toList();
  }

  Widget _buildCategoryItem({
    required Color color, 
    required String title, 
    required double amount,
    required int percent,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        margin: const EdgeInsets.only(bottom: 5),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: isSelected ? Border.all(color: color.withOpacity(0.5)) : null,
        ),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: TColor.white,
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            Text(
              "₹${amount.toStringAsFixed(0)}",
              style: TextStyle(
                color: TColor.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                "$percent%",
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
