import 'package:flutter/material.dart';
import 'package:kash/common/color_extension.dart';

class BudgetView extends StatefulWidget {
  const BudgetView({super.key});

  @override
  State<BudgetView> createState() => _BudgetViewState();
}

class _BudgetViewState extends State<BudgetView> {
  List<Map<String, dynamic>> budgetList = [
    {
      "name": "Grocery",
      "spend_amount": "\$2,500",
      "total_budget": "\$3,000",
      "left_amount": "\$500 left",
      "color": Colors.green,
      "percent": 0.83
    },
    {
      "name": "Transport",
      "spend_amount": "\$350",
      "total_budget": "\$500",
      "left_amount": "\$150 left",
      "color": Colors.blue,
      "percent": 0.7
    },
    {
      "name": "Entertainment",
      "spend_amount": "\$900",
      "total_budget": "\$1,000",
      "left_amount": "\$100 left",
      "color": Colors.red,
      "percent": 0.9
    },
    {
      "name": "Medical",
      "spend_amount": "\$100",
      "total_budget": "\$500",
      "left_amount": "\$400 left",
      "color": Colors.orange,
      "percent": 0.2
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TColor.primaryBg,
      appBar: AppBar(
        backgroundColor: TColor.primaryBg,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "Budgets",
          style: TextStyle(
            color: TColor.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              // Edit Budget UI
            },
            icon: Icon(Icons.edit, color: TColor.white),
          )
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: budgetList.length,
        itemBuilder: (context, index) {
          var bObj = budgetList[index];
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: TColor.gray80,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      bObj["name"],
                      style: TextStyle(
                        color: TColor.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      bObj["total_budget"],
                      style: TextStyle(
                        color: TColor.gray30,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                LinearProgressIndicator(
                  value: bObj["percent"],
                  backgroundColor: TColor.gray60.withOpacity(0.3),
                  valueColor: AlwaysStoppedAnimation(bObj["color"]),
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "${bObj["spend_amount"]} Spent",
                       style: TextStyle(
                        color: TColor.gray30,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      bObj["left_amount"],
                      style: TextStyle(
                        color: TColor.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
