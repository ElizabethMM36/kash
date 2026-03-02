import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AnalyticsService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> get _transactionsRef {
    if (_uid == null) throw Exception("User not logged in");
    return _db.collection('users').doc(_uid).collection('transactions');
  }

  /// 1️⃣ Expense Breakdown (Pie Chart)
  Future<Map<String, double>> getExpenseByCategory() async {
    final snapshot = await _transactionsRef
        .where('isIncome', isEqualTo: false)
        .get();

    Map<String, double> result = {};

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final category = data['category'] ?? "Others";
      final amount = (data['amount'] as num).toDouble();

      result[category] = (result[category] ?? 0) + amount;
    }

    return result;
  }

  /// 2️⃣ Monthly Spending (Current Year)
  Future<Map<int, double>> getMonthlySpending() async {
    final snapshot = await _transactionsRef
        .where('isIncome', isEqualTo: false)
        .get();

    Map<int, double> monthly = {};

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final timestamp = data['createdAt'] as Timestamp;
      final month = timestamp.toDate().month;

      final amount = (data['amount'] as num).toDouble();

      monthly[month] = (monthly[month] ?? 0) + amount;
    }

    return monthly;
  }

  /// 3️⃣ Income vs Expense
  Future<Map<String, double>> getIncomeVsExpense() async {
    final snapshot = await _transactionsRef.get();

    double income = 0;
    double expense = 0;

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final amount = (data['amount'] as num).toDouble();

      if (data['isIncome'] == true) {
        income += amount;
      } else {
        expense += amount;
      }
    }

    return {"Income": income, "Expense": expense};
  }

  /// 4️⃣ Sorted Category Analytics
  Future<List<Map<String, dynamic>>> getCategoryAnalytics() async {
    final data = await getExpenseByCategory();

    final sorted = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.map((e) => {"category": e.key, "amount": e.value}).toList();
  }
}
