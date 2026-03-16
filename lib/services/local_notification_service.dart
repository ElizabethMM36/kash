import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

/// Notification channel IDs
const _kBudgetChannelId = 'budget_alerts';
const _kBudgetChannelName = 'Budget Alerts';

const _kReminderChannelId = 'expense_reminders';
const _kReminderChannelName = 'Expense Reminders';

const _kWeeklyChannelId = 'weekly_summary';
const _kWeeklyChannelName = 'Weekly Summary';

const _kSmartChannelId = 'smart_alerts';
const _kSmartChannelName = 'Smart Alerts';

/// Notification IDs — keep each unique
class _NId {
  static const int budgetBase = 1000; // + index per category
  static const int dailyReminder = 2001;
  static const int monthlyReset = 2002;
  static const int weeklySummary = 2003;
  static const int unusualSpending = 2004;
  static const int savingsReminder = 2005;
  static const int recurringBase = 3000; // + index per recurring
}

class LocalNotificationService {
  static final LocalNotificationService _instance =
      LocalNotificationService._internal();
  factory LocalNotificationService() => _instance;
  LocalNotificationService._internal();

  final _plugin = FlutterLocalNotificationsPlugin();

  // ─── Initialise ────────────────────────────────────────────────────────────

  Future<void> init() async {
    tz.initializeTimeZones();

    // Set India timezone as default (change if needed)
    try {
      tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
    } catch (_) {
      // fallback if location not found
    }

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const settings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (details) {
        debugPrint('🔔 Notification tapped: ${details.payload}');
      },
    );

    // Request Android 13+ permission
    final androidPlugin =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();

    debugPrint('🔔 LocalNotificationService initialized');
  }

  // ─── 1. Budget Limit Alerts ─────────────────────────────────────────────────

  /// Call after loading budgets. Fires a notification if any category is at
  /// 70 %, 90 %, or exceeded.
  Future<void> checkBudgetAlerts({
    required List<Map<String, dynamic>> budgets,
    required double monthlyIncome,
  }) async {
    for (int i = 0; i < budgets.length; i++) {
      final budget = budgets[i];
      final category = budget['category'] as String? ?? 'Unknown';
      final percentage = (budget['percentage'] as int? ?? 0);
      final spent = (budget['spent'] as num?)?.toDouble() ?? 0.0;
      final limit = monthlyIncome * percentage / 100;

      if (limit <= 0) continue;

      final ratio = spent / limit;
      final remaining = limit - spent;

      int notifId = _NId.budgetBase + i;
      String? title;
      String? body;

      if (ratio >= 1.0) {
        // Exceeded
        title = '🚨 Budget Exceeded: $category';
        body =
            'You have exceeded your $category budget by ₹${_fmt(remaining.abs())}.';
      } else if (ratio >= 0.9) {
        // 90%+
        title = '⚠️ Almost Out: $category';
        body = 'Only ₹${_fmt(remaining)} left in your $category budget.';
      } else if (ratio >= 0.7) {
        // 70%+
        title = '📊 Budget Warning: $category';
        body =
            "You've used ${(ratio * 100).toStringAsFixed(0)}% of your $category budget this month.";
      }

      if (title != null && body != null) {
        await _show(
          id: notifId,
          title: title,
          body: body,
          channelId: _kBudgetChannelId,
          channelName: _kBudgetChannelName,
          importance: ratio >= 1.0 ? Importance.max : Importance.high,
          priority: ratio >= 1.0 ? Priority.max : Priority.high,
          payload: 'budget_$category',
        );
      }
    }
  }

  // ─── 2. Daily Expense Reminder ──────────────────────────────────────────────

  /// Schedules a daily reminder at 9 PM to log expenses.
  Future<void> scheduleDailyReminder() async {
    await _plugin.cancel(_NId.dailyReminder);

    await _plugin.zonedSchedule(
      _NId.dailyReminder,
      '💸 Daily Expense Reminder',
      "Did you forget to log today's expenses?",
      _nextInstanceOf(hour: 21, minute: 0), // 9 PM daily
      NotificationDetails(
        android: AndroidNotificationDetails(
          _kReminderChannelId,
          _kReminderChannelName,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          styleInformation: const BigTextStyleInformation(''),
        ),
      ),
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time, // repeat daily
      payload: 'daily_reminder',
    );

    debugPrint('🔔 Daily reminder scheduled for 9 PM');
  }

  // ─── 3. Monthly Budget Reset Notification ───────────────────────────────────

  /// Shows a notification on the 1st of every month.
  /// Call this once from main/home after checking the date.
  Future<void> showMonthlyReset() async {
    await _show(
      id: _NId.monthlyReset,
      title: '📅 New Month, Fresh Budget!',
      body: "Your monthly budgets have been reset. Let's start spending wisely!",
      channelId: _kReminderChannelId,
      channelName: _kReminderChannelName,
      importance: Importance.high,
      priority: Priority.high,
      payload: 'monthly_reset',
    );
  }

  // ─── 4. Weekly Spending Summary ─────────────────────────────────────────────

  /// Schedules a weekly summary every Sunday at 8 PM.
  Future<void> scheduleWeeklySummary({
    required double weekTotal,
    required String topCategory,
  }) async {
    await _plugin.cancel(_NId.weeklySummary);

    await _show(
      id: _NId.weeklySummary,
      title: '📊 Your Weekly Spending Summary',
      body:
          'This week you spent ₹${_fmt(weekTotal)}. $topCategory was your highest expense.',
      channelId: _kWeeklyChannelId,
      channelName: _kWeeklyChannelName,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      payload: 'weekly_summary',
    );
  }

  /// Schedule the weekly summary every Sunday at 8 PM
  Future<void> scheduleWeeklySummaryTimer() async {
    await _plugin.cancel(_NId.weeklySummary);

    await _plugin.zonedSchedule(
      _NId.weeklySummary,
      '📊 Weekly Spending Summary',
      'Tap to see how you spent this week.',
      _nextSunday(hour: 20, minute: 0), // 8 PM Sunday
      NotificationDetails(
        android: AndroidNotificationDetails(
          _kWeeklyChannelId,
          _kWeeklyChannelName,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
      ),
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      payload: 'weekly_summary',
    );

    debugPrint('🔔 Weekly summary scheduled for Sundays at 8 PM');
  }

  // ─── 5. Unusual Spending Alert ──────────────────────────────────────────────

  /// Show alert when today's total is notably higher than average.
  /// [todayTotal] — spending so far today.
  /// [avgDaily]   — user's average daily spending (pass 0 to skip).
  Future<void> checkUnusualSpending({
    required double todayTotal,
    required double avgDaily,
  }) async {
    if (avgDaily <= 0 || todayTotal <= avgDaily * 1.5) return;

    await _show(
      id: _NId.unusualSpending,
      title: '⚠️ Unusual Spending Detected',
      body:
          'Your spending today (₹${_fmt(todayTotal)}) is higher than your daily average (₹${_fmt(avgDaily)}).',
      channelId: _kSmartChannelId,
      channelName: _kSmartChannelName,
      importance: Importance.high,
      priority: Priority.high,
      payload: 'unusual_spending',
    );
  }

  // ─── 6. Savings Reminder ────────────────────────────────────────────────────

  /// Remind user about their savings goal progress.
  Future<void> showSavingsReminder({
    required double goalAmount,
    required double savedSoFar,
  }) async {
    if (goalAmount <= 0) return;

    final percent = (savedSoFar / goalAmount * 100).clamp(0, 100);

    await _show(
      id: _NId.savingsReminder,
      title: '🎯 Savings Update',
      body:
          'You planned to save ₹${_fmt(goalAmount)} this month. You\'ve saved ₹${_fmt(savedSoFar)} so far (${percent.toStringAsFixed(0)}%).',
      channelId: _kSmartChannelId,
      channelName: _kSmartChannelName,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      payload: 'savings_reminder',
    );
  }

  // ─── 7. Recurring Expense Reminder ──────────────────────────────────────────

  /// Remind user about a bill/subscription due tomorrow.
  Future<void> showRecurringReminder({
    required String expenseName,
    required String dueDate,
    int index = 0,
  }) async {
    await _show(
      id: _NId.recurringBase + index,
      title: '🧾 Upcoming Payment Reminder',
      body: 'Reminder: $expenseName payment due on $dueDate.',
      channelId: _kReminderChannelId,
      channelName: _kReminderChannelName,
      importance: Importance.high,
      priority: Priority.high,
      payload: 'recurring_$expenseName',
    );
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────────

  Future<void> _show({
    required int id,
    required String title,
    required String body,
    required String channelId,
    required String channelName,
    Importance importance = Importance.high,
    Priority priority = Priority.high,
    String? payload,
  }) async {
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        importance: importance,
        priority: priority,
        styleInformation: BigTextStyleInformation(body),
        enableLights: true,
        enableVibration: true,
      ),
    );

    await _plugin.show(id, title, body, details, payload: payload);
    debugPrint('🔔 Notification shown [$id]: $title');
  }

  /// Next occurrence of a specific time of day (today if not yet passed, else tomorrow)
  tz.TZDateTime _nextInstanceOf({required int hour, required int minute}) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
        tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  /// Next Sunday at a given time
  tz.TZDateTime _nextSunday({required int hour, required int minute}) {
    var now = tz.TZDateTime.now(tz.local);
    // weekday: 1=Mon, 7=Sun
    int daysUntilSunday = (DateTime.sunday - now.weekday + 7) % 7;
    if (daysUntilSunday == 0) daysUntilSunday = 7; // if today is Sunday, next Sunday
    return tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day + daysUntilSunday,
      hour,
      minute,
    );
  }

  String _fmt(double amount) {
    if (amount >= 100000) return '${(amount / 100000).toStringAsFixed(1)}L';
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(1)}K';
    return amount.toStringAsFixed(0);
  }
}
