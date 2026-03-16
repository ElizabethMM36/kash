import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:telephony_fix/telephony.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Represents a detected bank transaction from an SMS
class SmsTransaction {
  final double amount;
  final bool isDebit; // true = Expense, false = Income
  final String rawSms;
  final String senderAddress;

  SmsTransaction({
    required this.amount,
    required this.isDebit,
    required this.rawSms,
    required this.senderAddress,
  });
}

class SmsService {
  static final SmsService _instance = SmsService._internal();

  factory SmsService() => _instance;

  SmsService._internal();

  final Telephony _telephony = Telephony.instance;

  static const String _lastSmsIdKey = 'last_processed_sms_id';

  /// Request SMS permissions from the user
  Future<bool> requestSmsPermission() async {
    // Request both READ_SMS and RECEIVE_SMS
    final statuses = await [
      Permission.sms,
    ].request();
    return statuses[Permission.sms]?.isGranted ?? false;
  }

  /// Check if SMS permission is already granted
  Future<bool> hasSmsPermission() async {
    return await Permission.sms.isGranted;
  }

  /// Poll SMS inbox for new bank transactions since last check.
  /// Call this in initState and on app resume (AppLifecycleState.resumed).
  /// [onDetected] is called for each new bank transaction found.
  Future<void> checkInboxForNewBankSms({
    required void Function(SmsTransaction transaction) onDetected,
  }) async {
    final hasPermission = await hasSmsPermission();
    if (!hasPermission) {
      debugPrint('📩 No SMS permission, skipping inbox check');
      return;
    }

    try {
      // Get the last processed SMS id
      final prefs = await SharedPreferences.getInstance();
      final lastProcessedId = prefs.getInt(_lastSmsIdKey) ?? 0;
      debugPrint('📩 Checking inbox, last processed id: $lastProcessedId');

      // Fetch recent inbox SMS (last 20)
      final messages = await _telephony.getInboxSms(
        columns: [
          SmsColumn.ID,
          SmsColumn.ADDRESS,
          SmsColumn.BODY,
          SmsColumn.DATE,
        ],
        sortOrder: [
          OrderBy(SmsColumn.DATE, sort: Sort.DESC),
        ],
        filter: SmsFilter.where(SmsColumn.DATE)
            .greaterThan(
              (DateTime.now().subtract(const Duration(hours: 24)).millisecondsSinceEpoch).toString(),
            ),
      );

      debugPrint('📩 Found ${messages.length} SMS in last 24h');

      int newMaxId = lastProcessedId;
      final newTransactions = <SmsTransaction>[];

      for (final msg in messages) {
        final id = msg.id ?? 0;

        // Skip already processed SMSes
        if (id <= lastProcessedId) continue;

        if (id > newMaxId) newMaxId = id;

        debugPrint('📩 Checking SMS id=$id from=${msg.address} body=${msg.body}');

        final parsed = _parseBankSms(msg);
        if (parsed != null) {
          newTransactions.add(parsed);
        }
      }

      // Save the max ID we've seen
      if (newMaxId > lastProcessedId) {
        await prefs.setInt(_lastSmsIdKey, newMaxId);
      }

      // Fire callback for each new transaction (oldest first)
      for (final tx in newTransactions.reversed) {
        onDetected(tx);
      }
    } catch (e) {
      debugPrint('📩 Error reading SMS inbox: $e');
    }
  }

  /// Also try listening to live SMS (works on some devices)
  void listenToIncomingSms({
    required void Function(SmsTransaction transaction) onDetected,
  }) {
    try {
      _telephony.listenIncomingSms(
        onNewMessage: (SmsMessage message) {
          debugPrint('📩 Live SMS received from: ${message.address}');
          final parsed = _parseBankSms(message);
          if (parsed != null) {
            onDetected(parsed);
          }
        },
        listenInBackground: false,
      );
      debugPrint('📩 Live SMS listener registered');
    } catch (e) {
      debugPrint('📩 Live listener failed (may not work on this device): $e');
    }
  }

  /// Parse an SMS message and return a SmsTransaction if it looks like a bank SMS
  SmsTransaction? _parseBankSms(SmsMessage message) {
    final sender = (message.address ?? '').toUpperCase();
    final body = message.body ?? '';
    final bodyLower = body.toLowerCase();

    if (body.isEmpty) return null;

    // Check if from known bank sender
    const bankSenders = [
      'HDFCBK', 'SBIINB', 'ICICIB', 'AXISBK', 'KOTAKB',
      'INDUS',  'PNBSMS', 'BOIIND', 'CANBNK', 'CENTBK',
      'UNIONB', 'YESBNK', 'IDBIBK', 'RBLBNK', 'FEDBNK',
      'PAYTMB', 'SCBANK', 'CIBBNK', 'BARODAB', 'IOBSMS',
      'SYNBNK', 'SBICRD', 'HDFCCC', 'ICICICC', 'BANK',
    ];
    final isBankSender = bankSenders.any((b) => sender.contains(b));

    // Debit/credit keyword detection
    final hasDebitKeyword = bodyLower.contains('debited') ||
        bodyLower.contains('debit') ||
        bodyLower.contains('withdrawn') ||
        bodyLower.contains('spent');
    final hasCreditKeyword = bodyLower.contains('credited') ||
        bodyLower.contains('credit') ||
        bodyLower.contains('received');

    // Trigger on: bank sender with debit/credit, OR any message with debit/credit + amount
    if (!hasDebitKeyword && !hasCreditKeyword) return null;

    // Extract amount
    final amount = _extractAmount(body);
    if (amount == null || amount <= 0) return null;

    debugPrint('✅ Bank SMS matched! ₹$amount, debit=$hasDebitKeyword, sender=$sender');

    return SmsTransaction(
      amount: amount,
      isDebit: hasDebitKeyword,
      rawSms: body,
      senderAddress: sender,
    );
  }

  /// Try multiple regex patterns to extract money amount from SMS
  double? _extractAmount(String body) {
    final patterns = [
      // Rs. 1,250 or Rs 1250
      RegExp(r'Rs\.?\s*([\d,]+(?:\.\d{1,2})?)', caseSensitive: false),
      // INR 1250 or INR1,250
      RegExp(r'INR\s*([\d,]+(?:\.\d{1,2})?)', caseSensitive: false),
      // ₹1250 or ₹ 1,250
      RegExp(r'₹\s*([\d,]+(?:\.\d{1,2})?)'),
      // Amt 1250 or Amount: 1250
      RegExp(r'[Aa]mt\.?\s*:?\s*([\d,]+(?:\.\d{1,2})?)'),
      // "debited by 10.00" or "credited by 500"
      RegExp(r'(?:debited|credited)\s+by\s+([\d,]+(?:\.\d{1,2})?)', caseSensitive: false),
      // "for 500.00" or "of 1000"
      RegExp(r'(?:for|of)\s+([\d,]+(?:\.\d{1,2})?)\s', caseSensitive: false),
      // "sent 100" or "received 500"
      RegExp(r'(?:sent|received|transfer(?:red)?)\s+([\d,]+(?:\.\d{1,2})?)', caseSensitive: false),
      // Standalone decimal number with 2 decimal places (last resort): "10.00"
      RegExp(r'\b([\d,]+\.\d{2})\b'),
    ];

    for (final regex in patterns) {
      final match = regex.firstMatch(body);
      if (match != null) {
        final amountStr = match.group(1)!.replaceAll(',', '');
        final parsed = double.tryParse(amountStr);
        if (parsed != null && parsed > 0) {
          return parsed;
        }
      }
    }
    return null;
  }
}
