import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class IncomeService {
  final _db = FirebaseFirestore.instance;

  /// Get current user's UID
  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  /// Reference to the user's income_profiles subcollection
  CollectionReference<Map<String, dynamic>> get _incomeRef {
    if (_uid == null) throw Exception("User not logged in");
    return _db.collection('users').doc(_uid).collection('income_profiles');
  }

  /// Reference to the user document
  DocumentReference<Map<String, dynamic>> get _userRef {
    if (_uid == null) throw Exception("User not logged in");
    return _db.collection('users').doc(_uid);
  }

  /// Save a new income profile from the 3-step wizard
  Future<void> saveIncomeProfile(Map<String, dynamic> data) async {
    if (_uid == null) throw Exception("User not logged in");

    final now = Timestamp.now();

    // Build the document to save
    final document = {
      // Step 1
      'source': data['source'] ?? 'Salary',
      'amount': (data['amount'] ?? 0).toDouble(),
      'frequency': data['frequency'] ?? 'Monthly',
      'expectedDate': data['expectedDate'] ?? '',

      // Step 2
      'fixedExpenses': data['fixedExpenses'] ?? {},
      'savingsPercentage': (data['savingsPercentage'] ?? 20).toDouble(),
      'spendingStyle': data['spendingStyle'] ?? 'I spend freely but within limits',

      // Step 3
      'financialPriority': data['financialPriority'] ?? 'Save more',
      'riskComfort': data['riskComfort'] ?? true,

      'createdAt': now,
      'updatedAt': now,
    };

    // Save to income_profiles subcollection
    await _incomeRef.add(document);

    // Also update the user's monthlyIncome field for budget calculations
    final amount = (data['amount'] ?? 0).toDouble();
    if (amount > 0) {
      await _userRef.update({
        'monthlyIncome': amount,
        'incomeFrequency': (data['frequency'] ?? 'Monthly').toString().toLowerCase(),
      });
    }
  }

  /// Get all income profiles as a stream
  Stream<List<Map<String, dynamic>>> getIncomeProfiles() {
    if (_uid == null) return Stream.value([]);

    return _incomeRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              return {
                'id': doc.id,
                ...data,
              };
            }).toList());
  }
}
