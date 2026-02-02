import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kash/common/color_extension.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  String userName = "Baby Mumthas";

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  void loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userName = prefs.getString('user_name') ?? "Baby Mumthas";
    });
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
                    "baby.mumthas@example.com",
                    style: TextStyle(
                      color: TColor.gray30,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 20),
                  InkWell(
                    onTap: () {},
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: TColor.secondary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        "Edit Profile",
                        style: TextStyle(color: TColor.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  )
                ],
              ),
            ),
            
            const SizedBox(height: 20),

            _buildSettingTile(
              title: "General",
              icon: Icons.settings_outlined,
              onTap: () {},
            ),
             _buildSettingTile(
              title: "Currency",
              icon: Icons.currency_exchange_rounded,
              onTap: () {},
            ),
             _buildSettingTile(
              title: "Export Data",
              icon: Icons.file_upload_outlined,
              onTap: () {},
            ),
             _buildSettingTile(
              title: "Log Out",
              icon: Icons.logout_rounded,
              onTap: () {
                // Navigate back to Welcome/Login
              },
              isDestructive: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingTile({required String title, required IconData icon, required VoidCallback onTap, bool isDestructive = false}) {
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
        child: Icon(icon, color: isDestructive ? Colors.red : TColor.white, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? Colors.red : TColor.white,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: isDestructive ? null : Icon(Icons.arrow_forward_ios_rounded, color: TColor.gray30, size: 16),
    );
  }
}
