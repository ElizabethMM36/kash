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
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: TColor.gray80,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                   Text(
                    "Total Spending",
                    style: TextStyle(
                      color: TColor.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 200,
                    child: PieChart(
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
                        sectionsSpace: 0,
                        centerSpaceRadius: 40,
                        sections: showingSections(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Legend
             Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: TColor.gray80,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  _buildLegendItem(color: Colors.green, title: "Grocery", percent: "30%"),
                  _buildLegendItem(color: Colors.blue, title: "Transport", percent: "20%"),
                   _buildLegendItem(color: Colors.red, title: "Entertainment", percent: "15%"),
                    _buildLegendItem(color: Colors.orange, title: "Medical", percent: "10%"),
                     _buildLegendItem(color: Colors.purple, title: "Bill", percent: "25%"),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> showingSections() {
    return List.generate(5, (i) {
      final isTouched = i == touchedIndex;
      final fontSize = isTouched ? 20.0 : 14.0;
      final radius = isTouched ? 60.0 : 50.0;
      const shadows = [Shadow(color: Colors.black, blurRadius: 2)];
      switch (i) {
        case 0:
          return PieChartSectionData(
            color: Colors.green,
            value: 30,
            title: '30%',
            radius: radius,
            titleStyle: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: TColor.white,
              shadows: shadows,
            ),
          );
        case 1:
          return PieChartSectionData(
            color: Colors.blue,
            value: 20,
            title: '20%',
            radius: radius,
             titleStyle: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: TColor.white,
              shadows: shadows,
            ),
          );
        case 2:
          return PieChartSectionData(
            color: Colors.red,
            value: 15,
            title: '15%',
            radius: radius,
             titleStyle: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: TColor.white,
              shadows: shadows,
            ),
          );
        case 3:
          return PieChartSectionData(
            color: Colors.orange,
            value: 10,
            title: '10%',
            radius: radius,
             titleStyle: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: TColor.white,
              shadows: shadows,
            ),
          );
         case 4:
          return PieChartSectionData(
            color: Colors.purple,
            value: 25,
            title: '25%',
            radius: radius,
             titleStyle: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: TColor.white,
               shadows: shadows,
            ),
          );
        default:
          throw Error();
      }
    });
  }

  Widget _buildLegendItem ({required Color color, required String title, required String percent}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(width: 15, height: 15, color: color),
              const SizedBox(width: 10),
              Text(title, style: TextStyle(color: TColor.white, fontSize: 14)),
            ],
          ),
          Text(percent, style: TextStyle(color: TColor.gray30, fontSize: 14)),
        ],
      ),
    );
  }
}
