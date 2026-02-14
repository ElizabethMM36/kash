import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

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

  /// Check if user already has an income profile
  Future<bool> hasExistingProfile() async {
    if (_uid == null) return false;
    final snapshot = await _incomeRef.limit(1).get();
    return snapshot.docs.isNotEmpty;
  }

  /// Save or update income profile (upsert: create if none exists, update if one already does)
  Future<void> saveIncomeProfile(Map<String, dynamic> data) async {
    if (_uid == null) throw Exception("User not logged in");

    debugPrint('=== IncomeService: uid=$_uid ===');

    final now = Timestamp.now();

    // Build the document fields
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

      'updatedAt': now,
    };

    // Check if a profile already exists
    final existingDocs = await _incomeRef.limit(1).get();

    DocumentReference<Map<String, dynamic>> docRef;

    if (existingDocs.docs.isNotEmpty) {
      // UPDATE existing profile
      docRef = existingDocs.docs.first.reference;
      await docRef.update(document);
      debugPrint('=== IncomeService: UPDATED existing doc id=${docRef.id} ===');
    } else {
      // CREATE new profile
      document['createdAt'] = now;
      docRef = await _incomeRef.add(document);
      debugPrint('=== IncomeService: CREATED new doc id=${docRef.id} ===');
    }

    // Force a server-side read to verify the write actually landed
    try {
      final serverDoc = await docRef.get(const GetOptions(source: Source.server));
      debugPrint('=== IncomeService: server verify exists=${serverDoc.exists} ===');
      if (!serverDoc.exists) {
        throw Exception('Document was not saved to server. Check Firestore security rules.');
      }
    } catch (e) {
      debugPrint('=== IncomeService: SERVER VERIFY FAILED: $e ===');
      rethrow;
    }

    // Also update the user's monthlyIncome field for budget calculations
    final amount = (data['amount'] ?? 0).toDouble();
    if (amount > 0) {
      await _userRef.update({
        'monthlyIncome': amount,
        'incomeFrequency': (data['frequency'] ?? 'Monthly').toString().toLowerCase(),
      });

      // Also add as a transaction so it shows in the expense log
      final nowDt = DateTime.now();
      final dateStr = '${nowDt.year}-${nowDt.month.toString().padLeft(2, '0')}-${nowDt.day.toString().padLeft(2, '0')}';
      await _db.collection('users').doc(_uid).collection('transactions').add({
        'amount': amount,
        'category': data['source'] ?? 'Salary',
        'date': dateStr,
        'note': data['source'] ?? 'Salary',
        'isIncome': true,
        'createdAt': now,
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

