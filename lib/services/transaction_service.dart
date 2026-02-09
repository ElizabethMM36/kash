import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TransactionService {
  final _db = FirebaseFirestore.instance;

  /// Add a new transaction
  Future<void> addTransaction({
    required double amount,
    required String category,
    required String date,
    String? note,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("User not logged in");

    await _db
        .collection('users')
        .doc(user.uid)
        .collection('transactions')
        .add({
      'amount': amount,
      'category': category,
      'date': date,
      'note': note ?? '',
      'isIncome': false,
      'createdAt': Timestamp.now(),
    });
  }

  /// Get recent transactions stream (limit 5)
  Stream<List<Map<String, dynamic>>> getRecentTransactions() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value([]);

    return _db
        .collection('users')
        .doc(user.uid)
        .collection('transactions')
        .orderBy('createdAt', descending: true)
        .limit(5)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              return {
                'id': doc.id,
                'amount': data['amount'] ?? 0.0,
                'category': data['category'] ?? '',
                'date': data['date'] ?? '',
                'note': data['note'] ?? '',
                'isIncome': data['isIncome'] ?? false,
                'createdAt': data['createdAt'],
              };
            }).toList());
  }
}
