import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kash/common/color_extension.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kash/view/login/welcome_view.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kash/view/add_income/add_income_view.dart';
import 'package:kash/services/income_service.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  late String userName = '';
  late String userEmail = '';
  final _incomeService = IncomeService();

  Future<void> logout(BuildContext context) async {
    try {
      // 1.Sign out from Firebase
      await FirebaseAuth.instance.signOut();
      // 2. Clear SharePreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      // 3.Navigate to Welcome Screen
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const WelcomeView()),
          (route) => false,
        );
      }
    } catch (e) {
      // Handle error
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error logging out: $e")));
    }
  }

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  void loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    if (doc.exists) {
      setState(() {
        userName = doc['name'] ?? '';
        userEmail = doc['email'] ?? '';
      });
    }
  }

  Future<void> _showCurrentPlanSheet() async {
    final profile = await _incomeService.getCurrentProfile();
    if (!mounted) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        decoration: BoxDecoration(
          color: TColor.gray80,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: TColor.gray50,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Row(
                children: [
                  Icon(Icons.account_balance_wallet_rounded, color: TColor.secondary, size: 28),
                  const SizedBox(width: 12),
                  Text(
                    "Current Budget Plan",
                    style: TextStyle(
                      color: TColor.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: profile == null
                  ? Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.inbox_outlined, size: 48, color: TColor.gray50),
                            const SizedBox(height: 16),
                            Text(
                              "No budget plan yet",
                              style: TextStyle(color: TColor.gray30, fontSize: 16),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Tap \"EDIT YOUR BUDGET PLAN\" to create one.",
                              textAlign: TextAlign.center,
                              style: TextStyle(color: TColor.gray50, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView(
                      shrinkWrap: true,
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      children: _buildPlanListItems(profile),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildPlanListItems(Map<String, dynamic> p) {
    final items = <Widget>[];

    void addRow(String label, String value) {
      if (value.isEmpty) return;
      items.add(
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: TColor.primaryBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: TColor.gray60.withOpacity(0.3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  label,
                  style: TextStyle(color: TColor.gray30, fontSize: 14),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  value,
                  style: TextStyle(color: TColor.white, fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Step 1 – Income
    addRow("Income source", (p['source'] ?? '—').toString());
    final amount = (p['amount'] ?? 0).toDouble();
    addRow("Amount", amount > 0 ? amount.toStringAsFixed(0) : '—');
    addRow("Frequency", (p['frequency'] ?? '—').toString());
    addRow("Expected date", (p['expectedDate'] ?? '—').toString());

    // Step 2 – Spending
    final fixed = p['fixedExpenses'];
    if (fixed is Map && fixed.isNotEmpty) {
      final buffer = StringBuffer();
      fixed.forEach((k, v) {
        final amt = v is num ? v.toDouble() : double.tryParse(v?.toString() ?? '') ?? 0;
        if (buffer.isNotEmpty) buffer.write(', ');
        buffer.write('$k: ${amt.toStringAsFixed(0)}');
      });
      addRow("Fixed expenses", buffer.toString());
    }
    final savings = (p['savingsPercentage'] ?? 0).toDouble();
    addRow("Savings target", savings > 0 ? '${savings.toInt()}%' : '—');
    addRow("Spending style", (p['spendingStyle'] ?? '—').toString());

    // Step 3 – Preferences
    addRow("Financial priority", (p['financialPriority'] ?? '—').toString());
    addRow("Spend close to limit", (p['riskComfort'] == true ? 'Yes, I manage' : 'No, warn me'));

    return items;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TColor.primaryBg,
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              decoration: BoxDecoration(
                color: TColor.gray80,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: TColor.gray60,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Icon(Icons.person, size: 50, color: TColor.white),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    userName,
                    style: TextStyle(
                      color: TColor.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    userEmail,
                    style: TextStyle(color: TColor.gray30, fontSize: 14),
                  ),
                  const SizedBox(height: 20),
                  InkWell(
                    onTap: () {},
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: TColor.secondary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        "Edit Profile",
                        style: TextStyle(
                          color: TColor.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            _buildCurrentPlanTile(),
            _buildSettingTile(
              title: "Log Out",
              icon: Icons.logout_rounded,
              onTap: () {
                logout(context);
              },
              isDestructive: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentPlanTile() {
    return ListTile(
      onTap: _showCurrentPlanSheet,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: TColor.gray80,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Icon(Icons.list_alt_rounded, color: TColor.white, size: 20),
      ),
      title: Text(
        "Current Plan",
        style: TextStyle(
          color: TColor.white,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: InkWell(
        onTap: () {
          showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: const AddIncomeView(),
            ),
          );
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Edit",
                style: TextStyle(
                  color: TColor.secondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.edit_calendar_rounded, color: TColor.secondary, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: TColor.gray80,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Icon(
          icon,
          color: isDestructive ? Colors.red : TColor.white,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? Colors.red : TColor.white,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: isDestructive
          ? null
          : Icon(
              Icons.arrow_forward_ios_rounded,
              color: TColor.gray30,
              size: 16,
            ),
    );
  }
}
