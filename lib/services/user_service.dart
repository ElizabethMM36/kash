import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  final _db = FirebaseFirestore.instance;

  /// Create user profile
  Future<void> createUserProfile({
    required String uid,
    required String name,
    required String email,
  }) async {
    final ref = _db.collection('users').doc(uid);

    final doc = await ref.get();

    // Prevent overwrite
    if (doc.exists) return;

    await ref.set({
      'name': name,
      'email': email,

      'currency': 'INR',
      'monthlyIncome': 0,
      'incomeFrequency': 'monthly',

      'createdAt': Timestamp.now(),
    });
  }

  /// Create default budgets (12 categories totaling 100%)
  Future<void> createDefaultBudgets(String uid) async {
    final budgetRef = _db.collection('users').doc(uid).collection('budgets');

    // Check if budgets already exist
    final snapshot = await budgetRef.limit(1).get();

    if (snapshot.docs.isNotEmpty) return;

    final defaultBudgets = [
      {
        'category': 'Rent & Housing',
        'percentage': 25,
        'colorValue': 0xFF6C5CE7,
      },
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
      final docRef = budgetRef.doc(budget['category'] as String);
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
}
