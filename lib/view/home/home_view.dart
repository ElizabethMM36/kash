import 'package:flutter/material.dart';
import 'package:kash/common/color_extension.dart';
import 'package:kash/view/add_transaction/add_transaction_view.dart';
import 'package:kash/view/split_expense/split_expense_view.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kash/services/transaction_service.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  String userName = "Loading...";
  double monthlyIncome = 0;
  double totalExpenses = 0;
  final TransactionService _transactionService = TransactionService();

  void loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (doc.exists) {
      setState(() {
        userName = doc['name'] ?? 'User';
        monthlyIncome = (doc['monthlyIncome'] ?? 0).toDouble();
      });
    }

    // Calculate total expenses
    _loadTotalExpenses();
  }

  void _loadTotalExpenses() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('transactions')
        .get();

    double total = 0;
    for (var doc in snapshot.docs) {
      final data = doc.data();
      final amount = (data['amount'] ?? 0).toDouble();
      final isIncome = data['isIncome'] ?? false;
      if (!isIncome) {
        total += amount;
      }
    }

    setState(() {
      totalExpenses = total;
    });
  }

  void _showSetBalanceDialog() {
    final TextEditingController balanceController = TextEditingController(
      text: monthlyIncome > 0 ? monthlyIncome.toStringAsFixed(0) : '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: TColor.gray80,
        title: Text('Set Your Balance', style: TextStyle(color: TColor.white)),
        content: TextField(
          controller: balanceController,
          keyboardType: TextInputType.number,
          style: TextStyle(color: TColor.white),
          decoration: InputDecoration(
            hintText: 'Enter amount',
            hintStyle: TextStyle(color: TColor.gray30),
            prefixText: '₹ ',
            prefixStyle: TextStyle(color: TColor.white),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: TColor.gray30),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: TColor.secondary),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: TColor.gray30)),
          ),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(balanceController.text);
              if (amount != null && amount > 0) {
                final user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .update({'monthlyIncome': amount});
                  setState(() {
                    monthlyIncome = amount;
                  });
                }
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: TColor.secondary),
            child: Text('Save', style: TextStyle(color: TColor.primary)),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  // Helper to get category color
  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Colors.orange;
      case 'transport':
        return Colors.blue;
      case 'bills':
        return Colors.purple;
      case 'shopping':
        return Colors.pink;
      case 'entertainment':
        return Colors.red;
      case 'health':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  // Helper to get category icon
  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Icons.restaurant;
      case 'transport':
        return Icons.directions_car;
      case 'bills':
        return Icons.receipt;
      case 'shopping':
        return Icons.shopping_bag_outlined;
      case 'entertainment':
        return Icons.movie;
      case 'health':
        return Icons.medical_services;
      default:
        return Icons.attach_money;
    }
  }

  String _getMonthAbbr() {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[DateTime.now().month - 1];
  }

  String _formatAmount(double amount) {
    if (amount < 0) {
      return "-${_formatAmount(amount.abs())}";
    }
    if (amount >= 100000) {
      return "${(amount / 100000).toStringAsFixed(1)}L";
    }
    // Format with commas
    String str = amount.toStringAsFixed(0);
    final parts = <String>[];
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      parts.insert(0, str[i]);
      count++;
      if (count == 3 && i > 0) {
        parts.insert(0, ',');
        count = 0;
      }
    }
    return parts.join();
  }

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.sizeOf(context);

    return Scaffold(
      backgroundColor: TColor.primaryBg,
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.only(
                top: 50,
                bottom: 15,
                left: 20,
                right: 20,
              ),
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
                            style: TextStyle(
                              color: TColor.gray30,
                              fontSize: 12,
                            ),
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
                        child: Icon(
                          Icons.person,
                          color: TColor.white,
                          size: 20,
                        ),
                      ),
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
                            Image.asset(
                              "assets/img/nexo_logo.png",
                              height: 30,
                              fit: BoxFit.contain,
                            ),
                            Text(
                              "VISA",
                              style: TextStyle(
                                color: TColor.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                fontStyle: FontStyle.italic,
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
                            letterSpacing: 2.0,
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Monthly Expenses & Income Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Expenses
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      "${_getMonthAbbr()}·Expenses",
                                      style: TextStyle(
                                        color: TColor.primary500.withOpacity(0.7),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(
                                      Icons.arrow_drop_down,
                                      size: 16,
                                      color: Colors.redAccent,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "₹ ${_formatAmount(totalExpenses)}",
                                  style: TextStyle(
                                    color: Colors.redAccent.shade100,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            // Income
                            GestureDetector(
                              onTap: _showSetBalanceDialog,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        "${_getMonthAbbr()}·Income",
                                        style: TextStyle(
                                          color: TColor.primary500.withOpacity(0.7),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Icon(
                                        Icons.arrow_drop_up,
                                        size: 16,
                                        color: TColor.primary500,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "₹ ${_formatAmount(monthlyIncome)}",
                                    style: TextStyle(
                                      color: TColor.primary500,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Balance Row
                        Row(
                          children: [
                            Text(
                              "₹ ${_formatAmount(monthlyIncome - totalExpenses)}",
                              style: TextStyle(
                                color: TColor.primary500.withOpacity(0.6),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "≡",
                              style: TextStyle(
                                color: TColor.primary500.withOpacity(0.5),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
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
                        icon: Icons.call_split_rounded,
                        title: "Split",
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            backgroundColor: Colors.transparent,
                            isScrollControlled: true,
                            builder: (context) =>
                                const SplitExpenseView(initialData: {}),
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
                  ),
                ],
              ),
            ),

            StreamBuilder<List<Map<String, dynamic>>>(
              stream: _transactionService.getRecentTransactions(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final transactions = snapshot.data ?? [];

                if (transactions.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(20),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.receipt_long,
                            color: TColor.gray30,
                            size: 48,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "No transactions yet",
                            style: TextStyle(
                              color: TColor.gray30,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            "Tap 'Add Expense' to add your first transaction",
                            style: TextStyle(
                              color: TColor.gray30,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: transactions.length,
                  itemBuilder: (context, index) {
                    var tObj = transactions[index];
                    final category = tObj['category'] as String? ?? 'Other';
                    final amount = tObj['amount'] as num? ?? 0;
                    final note = tObj['note'] as String? ?? '';
                    final date = tObj['date'] as String? ?? '';
                    final isIncome = tObj['isIncome'] as bool? ?? false;

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
                              _getCategoryIcon(category),
                              color: _getCategoryColor(category),
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  note.isNotEmpty ? note : category,
                                  style: TextStyle(
                                    color: TColor.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  "$category • $date",
                                  style: TextStyle(
                                    color: TColor.gray30,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            isIncome
                                ? "+₹${amount.toStringAsFixed(2)}"
                                : "-₹${amount.toStringAsFixed(2)}",
                            style: TextStyle(
                              color: isIncome
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
                );
              },
            ),
            const SizedBox(height: 80), // Bottom padding for Fab
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: TColor.gray70,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: TColor.border.withOpacity(0.5)),
            ),
            child: Icon(icon, color: TColor.secondary, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              color: TColor.gray30,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
