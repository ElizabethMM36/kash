import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kash/common/color_extension.dart';
import 'package:kash/view/main_tab/main_tab_view.dart';
import 'package:kash/view/add_transaction/add_transaction_view.dart';
import 'package:kash/view/split_expense/split_expense_view.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  String userName = "Baby Mumthas";

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  void loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userName = prefs.getString('user_name') ?? "Baby Mumthas";
    });
  }

  // Dummy data for recent transactions
  List<Map<String, dynamic>> recentTransactions = [
    {
      "name": "Netflix Subscription",
      "date": "Today, 10:00 AM",
      "category": "Entertainment",
      "amount": "-\$15.00",
      "isIncome": false,
      "color": Colors.red
    },
    {
      "name": "Salary",
      "date": "Yesterday, 05:00 PM",
      "category": "Income",
      "amount": "+\$3,500.00",
      "isIncome": true,
      "color": Colors.green
    },
    {
      "name": "Grocery Shopping",
      "date": "Oct 24, 02:30 PM",
      "category": "Food",
      "amount": "-\$85.50",
      "isIncome": false,
      "color": Colors.orange
    },
    {
      "name": "Electric Bill",
      "date": "Oct 20, 09:00 AM",
      "category": "Bills",
      "amount": "-\$120.00",
      "isIncome": false,
      "color": Colors.blue
    },
  ];

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.sizeOf(context);

    return Scaffold(
      backgroundColor: TColor.primaryBg,
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.only(top: 50, bottom: 15, left: 20, right: 20),
              decoration: BoxDecoration(
                color: TColor.gray80,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(25),
                  bottomRight: Radius.circular(25),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Welcome back,",
                            style: TextStyle(color: TColor.gray30, fontSize: 12),
                          ),
                          Text(
                            userName,
                            style: TextStyle(
                              color: TColor.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: TColor.gray60.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Icon(Icons.person, color: TColor.white, size: 20),
                      )
                    ],
                  ),
                  const SizedBox(height: 25),

                  // Virtual Card (Updated)
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [TColor.secondary, TColor.secondary0],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: TColor.secondary.withOpacity(0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Image.asset("assets/img/nexo_logo.png", height: 30, fit: BoxFit.contain),
                            Text(
                              "VISA",
                              style: TextStyle(
                                color: TColor.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                fontStyle: FontStyle.italic
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 25),
                        Text(
                          userName,
                          style: TextStyle(
                            color: TColor.primary500.withOpacity(0.8),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.0,
                          ),
                        ),
                         const SizedBox(height: 5),
                         Text(
                          "**** **** **** 3456",
                          style: TextStyle(
                            color: TColor.primary500,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 2.0
                          ),
                        ),
                         const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                             Column(
                               crossAxisAlignment: CrossAxisAlignment.start,
                               children: [
                                 Text(
                                    "Balance",
                                    style: TextStyle(
                                      color: TColor.primary500.withOpacity(0.7),
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    "\$ 12,480.00",
                                    style: TextStyle(
                                      color: TColor.primary500,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                               ],
                             ),
                              Column(
                               crossAxisAlignment: CrossAxisAlignment.end,
                               children: [
                                 Text(
                                    "Monthly Limit",
                                    style: TextStyle(
                                      color: TColor.primary500.withOpacity(0.7),
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    "\$ 5,000 / \$ 10,000",
                                    style: TextStyle(
                                      color: TColor.primary500,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                               ],
                             ),
                          ],
                        ),
                        const SizedBox(height: 10),
                         ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                           child: LinearProgressIndicator(
                             value: 0.5,
                             minHeight: 4,
                             backgroundColor: TColor.white.withOpacity(0.3),
                             valueColor: AlwaysStoppedAnimation(TColor.primary500),
                           ),
                         )
                      ],
                    ),
                  ),
                  const SizedBox(height: 25),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                       _buildQuickAction(
                        icon: Icons.remove_circle_outline_rounded,
                        title: "Add Expense",
                         onTap: () {
                           showModalBottomSheet(
                              context: context,
                              backgroundColor: Colors.transparent,
                              isScrollControlled: true,
                              builder: (context) => const AddTransactionView(),
                            );
                         },
                      ),
                      _buildQuickAction(
                        icon: Icons.edit_note_rounded,
                        title: "Edit Budget",
                         onTap: () {
                           // Ideally switch to Budget Tab (Index 2)
                           // For now, doing nothing or we can push the view
                         },
                      ),
                      _buildQuickAction(
                        icon: Icons.call_split_rounded,
                        title: "Split",
                         onTap: () {
                           showModalBottomSheet(
                              context: context,
                              backgroundColor: Colors.transparent,
                              isScrollControlled: true,
                              builder: (context) => const SplitExpenseView(initialData: {}),
                            );
                         },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),

            // Expense Log Preview
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Expense Log Preview",
                    style: TextStyle(
                      color: TColor.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: Text(
                      "See all",
                      style: TextStyle(color: TColor.gray30, fontSize: 14),
                    ),
                  )
                ],
              ),
            ),

            ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: recentTransactions.length,
              itemBuilder: (context, index) {
                var tObj = recentTransactions[index];
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
                          Icons.shopping_bag_outlined, 
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
                              "${tObj["category"]} • ${tObj["date"]}",
                              style: TextStyle(color: TColor.gray30, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        tObj["amount"],
                        style: TextStyle(
                          color: tObj["isIncome"] ? Colors.greenAccent : TColor.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 80), // Bottom padding for Fab
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction({required IconData icon, required String title, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: TColor.gray70,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: TColor.border.withOpacity(0.5))
            ),
            child: Icon(icon, color: TColor.secondary, size: 24),
          ),
          const SizedBox(height: 8),
          Text(title, style: TextStyle(color: TColor.gray30, fontSize: 12, fontWeight: FontWeight.w500))
        ],
      ),
    );
  }
}
