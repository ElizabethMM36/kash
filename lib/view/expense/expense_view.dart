import 'package:flutter/material.dart';
import 'package:kash/common/color_extension.dart';

class ExpenseView extends StatefulWidget {
  const ExpenseView({super.key});

  @override
  State<ExpenseView> createState() => _ExpenseViewState();
}

class _ExpenseViewState extends State<ExpenseView> {
  // Dummy data
  List<Map<String, dynamic>> transactionList = [
    {
      "name": "Netflix Subscription",
      "date": "Today, 10:00 AM",
      "amount": "-\$15.00",
      "isIncome": false,
      "color": Colors.red,
    },
    {
      "name": "Salary",
      "date": "Yesterday, 05:00 PM",
      "amount": "+\$3,500.00",
      "isIncome": true,
      "color": Colors.green,
    },
    {
      "name": "Grocery Shopping",
      "date": "Oct 24, 02:30 PM",
      "amount": "-\$85.50",
      "isIncome": false,
      "color": Colors.orange,
    },
    {
      "name": "Electric Bill",
      "date": "Oct 20, 09:00 AM",
      "amount": "-\$120.00",
      "isIncome": false,
      "color": Colors.blue,
    },
    {
      "name": "Freelance Work",
      "date": "Oct 18, 11:00 AM",
      "amount": "+\$450.00",
      "isIncome": true,
      "color": Colors.purple,
    },
    {
      "name": "Dining Out",
      "date": "Oct 15, 08:30 PM",
      "amount": "-\$65.00",
      "isIncome": false,
      "color": Colors.pink,
    },
    {
      "name": "Gym Memebership",
      "date": "Oct 12, 10:30 AM",
      "amount": "-\$35.00",
      "isIncome": false,
      "color": Colors.teal,
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
        leading: Container(),
        title: Text(
          "Expenses",
          style: TextStyle(
            color: TColor.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.more_horiz, color: TColor.white),
          ),
        ],
      ),
      body: Column(
        children: [
          // Basic Date Segment
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: TColor.gray80,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () {},
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: TColor.secondary.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Text(
                          "This Month",
                          style: TextStyle(
                            color: TColor.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () {},
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          // color: TColor.secondary.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Text(
                          "Last Month",
                          style: TextStyle(
                            color: TColor.gray30,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: transactionList.length,
              itemBuilder: (context, index) {
                var tObj = transactionList[index];
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: TColor.gray80,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: TColor.gray60.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.shopping_bag_outlined, // Placeholder icon
                          color: tObj["color"],
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tObj["name"],
                              style: TextStyle(
                                color: TColor.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              tObj["date"],
                              style: TextStyle(
                                color: TColor.gray30,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        tObj["amount"],
                        style: TextStyle(
                          color: tObj["isIncome"]
                              ? Colors.greenAccent
                              : TColor.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
