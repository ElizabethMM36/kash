import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BudgetService {
  final _db = FirebaseFirestore.instance;

  /// Get current user's UID
  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  /// Get reference to user's budgets collection
  CollectionReference<Map<String, dynamic>> get _budgetsRef {
    if (_uid == null) throw Exception("User not logged in");
    return _db.collection('users').doc(_uid).collection('budgets');
  }

  /// Get reference to user document
  DocumentReference<Map<String, dynamic>> get _userRef {
    if (_uid == null) throw Exception("User not logged in");
    return _db.collection('users').doc(_uid);
  }

  /// Get all budgets for current user as a stream
  Stream<List<Map<String, dynamic>>> getBudgets() {
    if (_uid == null) return Stream.value([]);

    return _budgetsRef.orderBy('category').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'category': data['category'] ?? '',
          'percentage': data['percentage'] ?? 0,
          'colorValue': data['colorValue'] ?? 0xFF636E72,
          'spent': data['spent'] ?? 0.0,
          'isDefault': data['isDefault'] ?? true,
          'updatedAt': data['updatedAt'],
        };
      }).toList();
    });
  }

  /// Get user's monthly income
  Future<double> getMonthlyIncome() async {
    if (_uid == null) return 0.0;

    final doc = await _userRef.get();
    if (!doc.exists) return 0.0;

    final data = doc.data();
    return (data?['monthlyIncome'] ?? 0).toDouble();
  }

  /// Get user's monthly income as stream
  Stream<double> getMonthlyIncomeStream() {
    if (_uid == null) return Stream.value(0.0);

    return _userRef.snapshots().map((doc) {
      if (!doc.exists) return 0.0;
      final data = doc.data();
      return (data?['monthlyIncome'] ?? 0).toDouble();
    });
  }

  /// Calculate limit from percentage and income
  double calculateLimit(double income, int percentage) {
    return (income * percentage) / 100;
  }

  /// Update a budget's percentage
  Future<void> updateBudgetPercentage(String category, int newPercentage) async {
    if (_uid == null) throw Exception("User not logged in");

    await _budgetsRef.doc(category).update({
      'percentage': newPercentage,
      'isDefault': false,
      'updatedAt': Timestamp.now(),
    });
  }

  /// Update multiple budgets at once
  Future<void> updateMultipleBudgets(Map<String, int> categoryPercentages) async {
    if (_uid == null) throw Exception("User not logged in");

    final batch = _db.batch();

    categoryPercentages.forEach((category, percentage) {
      batch.update(_budgetsRef.doc(category), {
        'percentage': percentage,
        'isDefault': false,
        'updatedAt': Timestamp.now(),
      });
    });

    await batch.commit();
  }

  /// Add a new custom category
  Future<void> addCategory({
    required String category,
    required int percentage,
    required int colorValue,
  }) async {
    if (_uid == null) throw Exception("User not logged in");

    // Check if category already exists
    final existing = await _budgetsRef.doc(category).get();
    if (existing.exists) {
      throw Exception("Category '$category' already exists");
    }

    await _budgetsRef.doc(category).set({
      'category': category,
      'percentage': percentage,
      'colorValue': colorValue,
      'spent': 0.0,
      'isDefault': false,
      'updatedAt': Timestamp.now(),
    });
  }

  /// Delete a category
  Future<void> deleteCategory(String category) async {
    if (_uid == null) throw Exception("User not logged in");

    await _budgetsRef.doc(category).delete();
  }

  /// Update spent amount for a category
  Future<void> updateSpent(String category, double amount) async {
    if (_uid == null) throw Exception("User not logged in");

    await _budgetsRef.doc(category).update({
      'spent': FieldValue.increment(amount),
      'updatedAt': Timestamp.now(),
    });
  }

  /// Reset all budgets to defaults
  Future<void> resetToDefaults() async {
    if (_uid == null) throw Exception("User not logged in");

    // Delete all existing budgets
    final snapshot = await _budgetsRef.get();
    final batch = _db.batch();

    for (var doc in snapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();

    // Create default budgets
    await createDefaultBudgets();
  }

  /// Create default budgets (12 categories totaling 100%)
  Future<void> createDefaultBudgets() async {
    if (_uid == null) throw Exception("User not logged in");

    // Check if budgets already exist
    final snapshot = await _budgetsRef.limit(1).get();
    if (snapshot.docs.isNotEmpty) return;

    final defaultBudgets = [
      {'category': 'Rent/Housing', 'percentage': 25, 'colorValue': 0xFF6C5CE7},
      {'category': 'Groceries', 'percentage': 12, 'colorValue': 0xFF00B894},
      {'category': 'Transport', 'percentage': 10, 'colorValue': 0xFF0984E3},
      {'category': 'Utilities', 'percentage': 5, 'colorValue': 0xFFFDCB6E},
      {'category': 'Healthcare', 'percentage': 5, 'colorValue': 0xFFE17055},
      {'category': 'Dining Out', 'percentage': 5, 'colorValue': 0xFFE84393},
      {'category': 'Entertainment', 'percentage': 5, 'colorValue': 0xFFA29BFE},
      {'category': 'Shopping', 'percentage': 5, 'colorValue': 0xFF74B9FF},
      {'category': 'Subscriptions', 'percentage': 3, 'colorValue': 0xFFFF7675},
      {'category': 'Personal Care', 'percentage': 3, 'colorValue': 0xFF55EFC4},
      {'category': 'Savings', 'percentage': 15, 'colorValue': 0xFF00CEC9},
      {'category': 'Others', 'percentage': 7, 'colorValue': 0xFF636E72},
    ];

    final batch = _db.batch();

    for (var budget in defaultBudgets) {
      final docRef = _budgetsRef.doc(budget['category'] as String);
      batch.set(docRef, {
        'category': budget['category'],
        'percentage': budget['percentage'],
        'colorValue': budget['colorValue'],
        'spent': 0.0,
        'isDefault': true,
        'updatedAt': Timestamp.now(),
      });
    }

    await batch.commit();
  }

  /// Get total percentage allocated
  Future<int> getTotalPercentage() async {
    if (_uid == null) return 0;

    final snapshot = await _budgetsRef.get();
    int total = 0;

    for (var doc in snapshot.docs) {
      total += (doc.data()['percentage'] as int? ?? 0);
    }

    return total;
  }
}
