import 'package:flutter/material.dart';
import 'package:kash/common/color_extension.dart';
import 'package:kash/services/income_service.dart';
import 'package:kash/view/add_income/add_income_view.dart';
import 'package:kash/view/analytics/analytics_view.dart';
import 'package:kash/view/budget/budget_view.dart';
import 'package:kash/view/expense/expense_view.dart';
import 'package:kash/view/home/home_view.dart';
import 'package:kash/view/profile/profile_view.dart';

class MainTabView extends StatefulWidget {
  const MainTabView({super.key});

  @override
  State<MainTabView> createState() => _MainTabViewState();
}

class _MainTabViewState extends State<MainTabView> {
  int selectTab = 0;
  PageController controller = PageController();

  void _onItemTapped(int index) {
    setState(() {
      selectTab = index;
      controller.jumpToPage(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TColor.gray,
      body: PageView(
        controller: controller,
        physics: const NeverScrollableScrollPhysics(),
        children: const [
          HomeView(),
          ExpenseView(),
          BudgetView(),
          AnalyticsView(),
          ProfileView(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: TColor.gray80,
        selectedItemColor: TColor.secondary,
        unselectedItemColor: TColor.gray30,
        type: BottomNavigationBarType.fixed,
        currentIndex: selectTab,
        onTap: _onItemTapped,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        elevation: 1,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_rounded),
            label: 'Expenses',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet_rounded),
            label: 'Budget',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pie_chart_rounded),
            label: 'Analysis',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final incomeService = IncomeService();
          final hasProfile = await incomeService.hasExistingProfile();

          if (!mounted) return;

          if (hasProfile) {
            // Show alert: profile already exists
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                backgroundColor: TColor.gray80,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                title: Row(
                  children: [
                    Icon(Icons.info_outline, color: TColor.secondary),
                    const SizedBox(width: 10),
                    Text(
                      "Budget Plan Exists",
                      style: TextStyle(color: TColor.white, fontSize: 18),
                    ),
                  ],
                ),
                content: Text(
                  "You've already submitted your budget plan. To update it, go to the Profile section.",
                  style: TextStyle(color: TColor.gray30, fontSize: 14),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text("OK", style: TextStyle(color: TColor.secondary, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          } else {
            // Open Add Income Modal
            showModalBottomSheet(
              context: context,
              backgroundColor: Colors.transparent,
              isScrollControlled: true,
              builder: (context) {
                return const AddIncomeView();
              },
            );
          }
        },
        backgroundColor: TColor.secondary,
        child: const Icon(Icons.add, size: 30),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
