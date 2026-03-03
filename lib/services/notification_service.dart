import 'package:flutter/foundation.dart';
import 'package:notification_listener_service/notification_listener_service.dart';
import 'package:notification_listener_service/notification_event.dart';

/// Payment app package names to monitor for notifications
const _paymentPackages = [
  'com.google.android.apps.nbu.paisa.user', // Google Pay
  'net.one97.paytm',                          // Paytm
  'com.phonepe.app',                           // PhonePe
  'in.amazon.mshop.android.shopping',         // Amazon Pay
  'com.mobikwik_new',                          // MobiKwik
  'com.freecharge.android',                    // Freecharge
  'com.bhim.axis',                             // BHIM Axis
  'in.gov.npci.bhimupi',                       // BHIM UPI
  'com.olive.banking.android',                 // Olive (generic)
  'com.whatsapp',                              // WhatsApp Pay
];

/// Parsed notification transaction
class NotificationTransaction {
  final double amount;
  final bool isCredit; // true = received money, false = sent money
  final String appName;
  final String rawText;

  NotificationTransaction({
    required this.amount,
    required this.isCredit,
    required this.appName,
    required this.rawText,
  });
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  /// Check if notification listener permission is granted
  Future<bool> hasPermission() async {
    return await NotificationListenerService.isPermissionGranted();
  }

  /// Open system settings to grant notification access
  Future<void> requestPermission() async {
    await NotificationListenerService.requestPermission();
  }

  /// Start listening to notifications from payment apps
  void startListening({
    required void Function(NotificationTransaction tx) onDetected,
  }) {
    NotificationListenerService.notificationsStream.listen(
      (ServiceNotificationEvent event) {
        debugPrint('🔔 Notification from ${event.packageName}: ${event.title} — ${event.content}');
        final tx = _parsePaymentNotification(event);
        if (tx != null) {
          onDetected(tx);
        }
      },
      onError: (e) => debugPrint('🔔 Notification stream error: $e'),
    );
  }

  /// Parse a notification event and return a transaction if it's a payment
  NotificationTransaction? _parsePaymentNotification(ServiceNotificationEvent event) {
    final pkg = event.packageName ?? '';
    final title = (event.title ?? '').toLowerCase();
    final content = (event.content ?? '').toLowerCase();
    final fullText = '$title $content';

    // Only process known payment apps
    final isPaymentApp = _paymentPackages.any((p) => pkg.contains(p.split('.').last)) ||
        _paymentPackages.contains(pkg);

    // Also catch generic bank notifications
    final isBankNotif = fullText.contains('debited') ||
        fullText.contains('credited') ||
        fullText.contains('debited from') ||
        fullText.contains('credited to');

    if (!isPaymentApp && !isBankNotif) return null;

    // Determine if money received or sent
    final isCredit = fullText.contains('received') ||
        fullText.contains('credited') ||
        fullText.contains('you got') ||
        fullText.contains('money received') ||
        fullText.contains('paid you');

    final isDebitKeyword = fullText.contains('sent') ||
        fullText.contains('paid') ||
        fullText.contains('debited') ||
        fullText.contains('transferred');

    if (!isCredit && !isDebitKeyword) return null;

    // Extract amount from title + content
    final rawFull = '${event.title ?? ''} ${event.content ?? ''}';
    final amount = _extractAmount(rawFull);
    if (amount == null || amount <= 0) return null;

    // Get readable app name
    final appName = _getAppName(pkg);

    debugPrint('✅ Payment notification! ₹$amount, credit=$isCredit, from=$appName');

    return NotificationTransaction(
      amount: amount,
      isCredit: isCredit,
      appName: appName,
      rawText: rawFull,
    );
  }

  String _getAppName(String pkg) {
    if (pkg.contains('paisa') || pkg.contains('gpay')) return 'Google Pay';
    if (pkg.contains('paytm')) return 'Paytm';
    if (pkg.contains('phonepe')) return 'PhonePe';
    if (pkg.contains('whatsapp')) return 'WhatsApp Pay';
    if (pkg.contains('amazon')) return 'Amazon Pay';
    if (pkg.contains('bhim')) return 'BHIM UPI';
    return 'Payment App';
  }

  double? _extractAmount(String text) {
    final patterns = [
      RegExp(r'Rs\.?\s*([\d,]+(?:\.\d{1,2})?)', caseSensitive: false),
      RegExp(r'INR\s*([\d,]+(?:\.\d{1,2})?)', caseSensitive: false),
      RegExp(r'₹\s*([\d,]+(?:\.\d{1,2})?)'),
      RegExp(r'(?:received|sent|paid|got)\s+(?:rs\.?\s*)?([\d,]+(?:\.\d{1,2})?)', caseSensitive: false),
      RegExp(r'\b([\d,]+\.\d{2})\b'),
    ];

    for (final regex in patterns) {
      final match = regex.firstMatch(text);
      if (match != null) {
        final amountStr = match.group(1)!.replaceAll(',', '');
        final parsed = double.tryParse(amountStr);
        if (parsed != null && parsed > 0) return parsed;
      }
    }
    return null;
  }
}
