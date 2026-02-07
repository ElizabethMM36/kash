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

  /// Create default budgets
  Future<void> createDefaultBudgets(String uid) async {
    final budgetRef = _db.collection('users').doc(uid).collection('budgets');

    // Check if budgets already exist
    final snapshot = await budgetRef.limit(1).get();

    if (snapshot.docs.isNotEmpty) return;

    final budgets = [
      {'category': 'Food', 'percentage': 30},
      {'category': 'Rent', 'percentage': 25},
      {'category': 'Transport', 'percentage': 10},
      {'category': 'Savings', 'percentage': 20},
      {'category': 'Others', 'percentage': 15},
    ];

    for (var b in budgets) {
      await budgetRef.doc(b['category'] as String).set({
        'category': b['category'],
        'percentage': b['percentage'],

        'limit': 0,
        'spent': 0,

        'updatedAt': Timestamp.now(),
      });
    }
  }
}
