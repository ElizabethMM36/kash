import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:kash/common/color_extension.dart';
import 'package:kash/view/add_transaction/add_transaction_view.dart';
import 'package:kash/view/split_expense/split_expense_view.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kash/services/transaction_service.dart';
import 'package:kash/services/sms_service.dart';
import 'package:kash/services/budget_service.dart';
import 'package:kash/services/notification_service.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> with WidgetsBindingObserver {
  String userName = "Loading...";
  double monthlyIncome = 0;
  double totalExpenses = 0;
  double totalIncome = 0;
  double monthlyExpenses = 0;
  double monthlyIncomeTotal = 0;
  final TransactionService _transactionService = TransactionService();
  final SmsService _smsService = SmsService();
  final BudgetService _budgetService = BudgetService();
  final NotificationService _notificationService = NotificationService();
  List<String> _availableCategories = [];

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

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('transactions')
          .get();

      final now = DateTime.now();
      final currentMonth = now.month;
      final currentYear = now.year;

      double expenseTotal = 0;
      double incomeTotal = 0;
      double monthExpense = 0;
      double monthIncome = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final amount = (data['amount'] ?? 0).toDouble();
        final isIncome = data['isIncome'] ?? false;

        // Determine transaction month/year from date or createdAt
        int txMonth = 0;
        int txYear = 0;
        final dateStr = data['date'] as String?;
        if (dateStr != null && dateStr.contains('-')) {
          try {
            final parts = dateStr.split('-');
            txYear = int.parse(parts[0]);
            txMonth = int.parse(parts[1]);
          } catch (_) {}
        }
        if (txMonth == 0 && data['createdAt'] is Timestamp) {
          final dt = (data['createdAt'] as Timestamp).toDate();
          txMonth = dt.month;
          txYear = dt.year;
        }

        if (isIncome) {
          incomeTotal += amount;
          if (txMonth == currentMonth && txYear == currentYear) {
            monthIncome += amount;
          }
        } else {
          expenseTotal += amount;
          if (txMonth == currentMonth && txYear == currentYear) {
            monthExpense += amount;
          }
        }
      }

      if (mounted) {
        setState(() {
          totalExpenses = expenseTotal;
          totalIncome = incomeTotal;
          monthlyExpenses = monthExpense;
          monthlyIncomeTotal = monthIncome;
        });
      }
    } catch (e) {
      debugPrint('Error loading totals: $e');
    }
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
    WidgetsBinding.instance.addObserver(this);
    loadUserData();
    _initSmsListener();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _categorySub?.cancel();
    super.dispose();
  }

  StreamSubscription? _categorySub;

  /// Called when app comes back to foreground — re-poll inbox
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      debugPrint('📩 App resumed — checking SMS inbox');
      _pollSmsInbox();
    }
  }

  /// Initialize SMS permission + start inbox polling + live listener
  void _initSmsListener() async {
    // Load categories in background for use in dialog
    _categorySub = _budgetService.getCategoryNames().listen((names) {
      if (mounted) {
        setState(() => _availableCategories = names);
      }
    });

    final granted = await _smsService.requestSmsPermission();
    if (!granted) {
      debugPrint('📩 SMS permission denied');
      return;
    }

    // Also try live listener (works on some devices)
    _smsService.listenToIncomingSms(
      onDetected: (SmsTransaction tx) {
        if (mounted) _showSmsConfirmDialog(tx);
      },
    );

    // Poll inbox immediately on start
    _pollSmsInbox();

    // Start notification listener for GPay/payment apps
    _initNotificationListener();
  }

  /// Initialize GPay/payment app notification listener
  void _initNotificationListener() async {
    final hasPermission = await _notificationService.hasPermission();
    if (!hasPermission) {
      // Show a one-time dialog asking user to grant notification access
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: TColor.gray80,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Icon(Icons.notifications_active, color: TColor.secondary),
                const SizedBox(width: 10),
                Text('Enable GPay Detection',
                    style: TextStyle(color: TColor.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            content: Text(
              'To auto-detect Google Pay, PhonePe & Paytm transactions, allow Kash to read notifications.\n\nThis is read-only — no payments can be made.',
              style: TextStyle(color: TColor.gray30, fontSize: 13, height: 1.5),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Later', style: TextStyle(color: TColor.gray30)),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  await _notificationService.requestPermission();
                  // Start listener after permission (user must go to Settings and come back)
                  Future.delayed(const Duration(seconds: 3), () {
                    if (mounted) _startNotificationListener();
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: TColor.secondary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('Allow', style: TextStyle(color: TColor.primary, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      }
    } else {
      _startNotificationListener();
    }
  }

  void _startNotificationListener() {
    _notificationService.startListening(
      onDetected: (NotificationTransaction tx) {
        if (mounted) _showNotificationConfirmDialog(tx);
      },
    );
    debugPrint('🔔 Notification listener started');
  }

  /// Show SMS-style confirm dialog for payment notifications
  void _showNotificationConfirmDialog(NotificationTransaction tx) {
    String selectedCategory = _availableCategories.isNotEmpty
        ? _availableCategories.first
        : 'Auto-detected';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: TColor.gray80,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: tx.isCredit
                      ? Colors.greenAccent.withOpacity(0.15)
                      : Colors.redAccent.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.notifications_active,
                  color: tx.isCredit ? Colors.greenAccent : Colors.redAccent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text('${tx.appName} Detected',
                    style: TextStyle(color: TColor.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                decoration: BoxDecoration(
                  color: tx.isCredit
                      ? Colors.greenAccent.withOpacity(0.1)
                      : Colors.redAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: tx.isCredit
                        ? Colors.greenAccent.withOpacity(0.3)
                        : Colors.redAccent.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      tx.isCredit ? '🟢  Money Received' : '🔴  Money Sent',
                      style: TextStyle(
                        color: tx.isCredit ? Colors.greenAccent : Colors.redAccent,
                        fontSize: 13, fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text('₹ ${_formatAmount(tx.amount)}',
                        style: TextStyle(color: TColor.white, fontSize: 28, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: TColor.gray60.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  tx.rawText.length > 120 ? '${tx.rawText.substring(0, 120)}...' : tx.rawText,
                  style: TextStyle(color: TColor.gray30, fontSize: 11, height: 1.4),
                ),
              ),
              if (!tx.isCredit && _availableCategories.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text('Category', style: TextStyle(color: TColor.gray30, fontSize: 12)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: TColor.gray60.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedCategory,
                      isExpanded: true,
                      dropdownColor: TColor.gray80,
                      icon: Icon(Icons.arrow_drop_down, color: TColor.white),
                      style: TextStyle(color: TColor.white, fontSize: 14),
                      items: _availableCategories.map((cat) =>
                          DropdownMenuItem(value: cat, child: Text(cat))).toList(),
                      onChanged: (val) {
                        if (val != null) setDialogState(() => selectedCategory = val);
                      },
                    ),
                  ),
                ),
              ],
            ],
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Ignore', style: TextStyle(color: TColor.gray30)),
            ),
            OutlinedButton(
              onPressed: () {
                Navigator.pop(ctx);
                showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.transparent,
                  isScrollControlled: true,
                  builder: (_) => AddTransactionView(
                    prefilledAmount: tx.amount,
                    prefilledIsDebit: !tx.isCredit,
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: TColor.secondary,
                side: BorderSide(color: TColor.secondary.withOpacity(0.5)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Edit'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  final now = DateTime.now();
                  final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
                  await _transactionService.addTransaction(
                    amount: tx.amount,
                    category: tx.isCredit ? 'Income' : (selectedCategory.isNotEmpty ? selectedCategory : 'Auto-detected'),
                    date: dateStr,
                    note: 'Auto-detected via ${tx.appName}',
                    isIncome: tx.isCredit,
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('✅ ₹${_formatAmount(tx.amount)} ${tx.isCredit ? 'income' : 'expense'} saved from ${tx.appName}!'),
                        backgroundColor: tx.isCredit ? Colors.green : Colors.redAccent,
                      ),
                    );
                    _loadTotalExpenses();
                  }
                } catch (e) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: tx.isCredit ? Colors.green : Colors.redAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Confirm', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  /// Read SMS inbox and show dialog for any new bank transactions
  void _pollSmsInbox() async {
    await _smsService.checkInboxForNewBankSms(
      onDetected: (SmsTransaction tx) {
        if (mounted) {
          _showSmsConfirmDialog(tx);
        }
      },
    );
  }

  /// Show a confirmation popup when a bank SMS is detected
  void _showSmsConfirmDialog(SmsTransaction tx) {
    String selectedCategory = _availableCategories.isNotEmpty
        ? _availableCategories.first
        : 'Auto-detected';
    bool isDebit = tx.isDebit;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: TColor.gray80,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isDebit
                      ? Colors.redAccent.withOpacity(0.15)
                      : Colors.greenAccent.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.sms_outlined,
                  color: isDebit ? Colors.redAccent : Colors.greenAccent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'SMS Detected',
                style: TextStyle(
                  color: TColor.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Amount chip
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                decoration: BoxDecoration(
                  color: isDebit
                      ? Colors.redAccent.withOpacity(0.1)
                      : Colors.greenAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDebit
                        ? Colors.redAccent.withOpacity(0.3)
                        : Colors.greenAccent.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      isDebit ? '🔴  Expense Detected' : '🟢  Income Detected',
                      style: TextStyle(
                        color: isDebit ? Colors.redAccent : Colors.greenAccent,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '₹ ${_formatAmount(tx.amount)}',
                      style: TextStyle(
                        color: TColor.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              // SMS preview
              Text(
                'From: ${tx.senderAddress}',
                style: TextStyle(color: TColor.gray30, fontSize: 11),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: TColor.gray60.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  tx.rawSms.length > 120
                      ? '${tx.rawSms.substring(0, 120)}...'
                      : tx.rawSms,
                  style: TextStyle(
                    color: TColor.gray30,
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ),
              // Category dropdown (debit only)
              if (isDebit && _availableCategories.isNotEmpty) ...[
                const SizedBox(height: 14),
                Text(
                  'Category',
                  style: TextStyle(color: TColor.gray30, fontSize: 12),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: TColor.gray60.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedCategory,
                      isExpanded: true,
                      dropdownColor: TColor.gray80,
                      icon: Icon(Icons.arrow_drop_down, color: TColor.white),
                      style: TextStyle(color: TColor.white, fontSize: 14),
                      items: _availableCategories.map((cat) {
                        return DropdownMenuItem<String>(
                          value: cat,
                          child: Text(cat),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => selectedCategory = val);
                        }
                      },
                    ),
                  ),
                ),
              ],
            ],
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            // Ignore button
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Ignore',
                style: TextStyle(color: TColor.gray30),
              ),
            ),
            // Edit button – opens AddTransactionView with pre-filled data
            OutlinedButton(
              onPressed: () {
                Navigator.pop(ctx);
                showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.transparent,
                  isScrollControlled: true,
                  builder: (_) => AddTransactionView(
                    prefilledAmount: tx.amount,
                    prefilledIsDebit: tx.isDebit,
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: TColor.secondary,
                side: BorderSide(color: TColor.secondary.withOpacity(0.5)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Edit'),
            ),
            // Confirm button
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  final now = DateTime.now();
                  final dateStr =
                      '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
                  await _transactionService.addTransaction(
                    amount: tx.amount,
                    category: isDebit
                        ? (selectedCategory.isNotEmpty
                            ? selectedCategory
                            : 'Auto-detected')
                        : 'Income',
                    date: dateStr,
                    note: 'Auto-detected via SMS',
                    isIncome: !isDebit,
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '✅ ₹${_formatAmount(tx.amount)} ${isDebit ? "expense" : "income"} saved!',
                        ),
                        backgroundColor: isDebit ? Colors.redAccent : Colors.green,
                      ),
                    );
                    _loadTotalExpenses();
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error saving: $e')),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isDebit ? Colors.redAccent : Colors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Confirm',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
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
// card number removed
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
                                  "₹ ${_formatAmount(monthlyExpenses)}",
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            // Income
                            Column(
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
                                  "₹ ${_formatAmount(monthlyIncomeTotal)}",
                                  style: TextStyle(
                                    color: TColor.primary500,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Bank Balance & Month Balance Row
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: TColor.primary500.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Bank Balance
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Bank Balance",
                                    style: TextStyle(
                                      color: TColor.primary500.withOpacity(0.6),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    "₹ ${_formatAmount(totalIncome - totalExpenses)}",
                                    style: TextStyle(
                                      color: TColor.primary500,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              // Divider
                              Container(
                                width: 1,
                                height: 30,
                                color: TColor.primary500.withOpacity(0.2),
                              ),
                              // Month Balance
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    "${_getMonthAbbr()} Balance",
                                    style: TextStyle(
                                      color: TColor.primary500.withOpacity(0.6),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    "₹ ${_formatAmount(monthlyIncomeTotal - monthlyExpenses)}",
                                    style: TextStyle(
                                      color: (monthlyIncomeTotal - monthlyExpenses) >= 0
                                          ? TColor.primary500
                                          : Colors.redAccent,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
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

            // Expense Log
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Expense Log",
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

                // Group transactions by date
                final grouped = _groupTransactionsByDate(transactions);

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: grouped.entries.map((entry) {
                      final dateKey = entry.key;
                      final dayTransactions = entry.value;

                      // Calculate daily totals
                      double dayIncome = 0;
                      double dayExpense = 0;
                      for (var t in dayTransactions) {
                        final amt = (t['amount'] as num).toDouble();
                        if (t['isIncome'] == true) {
                          dayIncome += amt;
                        } else {
                          dayExpense += amt;
                        }
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Date Header
                          Padding(
                            padding: const EdgeInsets.only(top: 16, bottom: 12),
                            child: Row(
                              children: [
                                Text(
                                  _formatDateHeader(dateKey),
                                  style: TextStyle(
                                    color: TColor.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _getDayName(dateKey),
                                  style: TextStyle(
                                    color: TColor.gray30,
                                    fontSize: 13,
                                  ),
                                ),
                                const Spacer(),
                                if (dayIncome > 0)
                                  Text(
                                    "+${_formatAmount(dayIncome)}",
                                    style: const TextStyle(
                                      color: Colors.greenAccent,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                if (dayIncome > 0 && dayExpense > 0)
                                  const SizedBox(width: 8),
                                if (dayExpense > 0)
                                  Text(
                                    "-${_formatAmount(dayExpense)}",
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          // Timeline transactions
                          ...List.generate(dayTransactions.length, (i) {
                            final t = dayTransactions[i];
                            final category = t['category'] as String? ?? 'Other';
                            final amount = (t['amount'] as num?)?.toDouble() ?? 0;
                            final note = t['note'] as String? ?? '';
                            final isIncome = t['isIncome'] as bool? ?? false;
                            final timeStr = _getTimeFromTransaction(t);
                            final isLast = i == dayTransactions.length - 1;

                            return IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Time + Timeline
                                  SizedBox(
                                    width: 56,
                                    child: Column(
                                      children: [
                                        Text(
                                          timeStr,
                                          style: TextStyle(
                                            color: TColor.gray30,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: isIncome ? Colors.greenAccent : TColor.secondary,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        if (!isLast)
                                          Expanded(
                                            child: Container(
                                              width: 2,
                                              color: TColor.gray60.withOpacity(0.3),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),

                                  // Transaction Card
                                  Expanded(
                                    child: Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: TColor.gray80,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 44,
                                            height: 44,
                                            decoration: BoxDecoration(
                                              color: _getCategoryColor(category).withOpacity(0.15),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            alignment: Alignment.center,
                                            child: Icon(
                                              _getCategoryIcon(category),
                                              color: _getCategoryColor(category),
                                              size: 22,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  note.isNotEmpty ? note : category,
                                                  style: TextStyle(
                                                    color: TColor.white,
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  "$category · $timeStr",
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
                                                ? "+₹${_formatAmount(amount)}"
                                                : "-₹${_formatAmount(amount)}",
                                            style: TextStyle(
                                              color: isIncome
                                                  ? Colors.greenAccent
                                                  : Colors.red,
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      );
                    }).toList(),
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

  // Group transactions by date string
  Map<String, List<Map<String, dynamic>>> _groupTransactionsByDate(
      List<Map<String, dynamic>> transactions) {
    final Map<String, List<Map<String, dynamic>>> grouped = {};

    for (var t in transactions) {
      String dateKey;
      final createdAt = t['createdAt'];
      if (createdAt is Timestamp) {
        final dt = createdAt.toDate();
        dateKey = '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
      } else {
        dateKey = (t['date'] as String?) ?? 'Unknown';
      }

      grouped.putIfAbsent(dateKey, () => []);
      grouped[dateKey]!.add(t);
    }

    return grouped;
  }

  String _formatDateHeader(String dateKey) {
    try {
      final parts = dateKey.split('-');
      if (parts.length == 3) {
        const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        final month = months[int.parse(parts[1]) - 1];
        final day = parts[2];
        return '$month $day';
      }
    } catch (_) {}
    return dateKey;
  }

  String _getDayName(String dateKey) {
    try {
      final parts = dateKey.split('-');
      if (parts.length == 3) {
        final dt = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
        const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        return days[dt.weekday - 1];
      }
    } catch (_) {}
    return '';
  }

  String _getTimeFromTransaction(Map<String, dynamic> t) {
    final createdAt = t['createdAt'];
    if (createdAt is Timestamp) {
      final dt = createdAt.toDate();
      final hour = dt.hour.toString().padLeft(2, '0');
      final minute = dt.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    }
    return '';
  }
}
