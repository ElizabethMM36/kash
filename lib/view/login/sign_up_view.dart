import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kash/common/color_extension.dart';
import 'package:kash/common_widget/primary_button.dart';
import 'package:kash/common_widget/round_textfield.dart';
import 'package:kash/common_widget/secondary_boutton.dart';
import 'package:kash/view/login/sign_in_view.dart';
import 'package:kash/view/login/social_login.dart';
import 'package:kash/view/main_tab/main_tab_view.dart';
import 'package:kash/services/user_service.dart';
import 'package:kash/firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SignUpView extends StatefulWidget {
  const SignUpView({super.key});

  @override
  State<SignUpView> createState() => _SignUpViewState();
}

class _SignUpViewState extends State<SignUpView> {
  final TextEditingController txtName = TextEditingController();
  final TextEditingController txtEmail = TextEditingController();
  final TextEditingController txtPassword = TextEditingController();

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.sizeOf(context);

    return Scaffold(
      backgroundColor: TColor.primaryBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
          child: Column(
            children: [
              Image.asset(
                "assets/img/nexo_logo.png",
                width: media.width * 0.5,
                fit: BoxFit.contain,
              ),

              const SizedBox(height: 40),

              RoundTextField(title: "Name", controller: txtName),
              const SizedBox(height: 15),

              RoundTextField(
                title: "E-mail address",
                controller: txtEmail,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 15),
              RoundTextField(
                title: "Password",
                controller: txtPassword,
                obscureText: true,
              ),

              const SizedBox(height: 20),

              Row(
                children: List.generate(
                  4,
                  (_) => Expanded(
                    child: Container(
                      height: 5,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 85, 207, 112),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              Text(
                "Use 8 or more with a mix of letters, characters and alphabets",
                textAlign: TextAlign.center,
                softWrap: true,
                style: TextStyle(color: TColor.white, fontSize: 14),
              ),

              const SizedBox(height: 25),

              PrimaryButton(
                title: "Get started",
                onPressed: () async {
                  if (txtName.text.isEmpty ||
                      txtEmail.text.isEmpty ||
                      txtPassword.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("All fields required")),
                    );
                    return;
                  }

                  try {
                    // Create user
                    UserCredential credential = await FirebaseAuth.instance
                        .createUserWithEmailAndPassword(
                          email: txtEmail.text.trim(),
                          password: txtPassword.text.trim(),
                        );
                    // Save the display name
                    final user = credential.user!;
                    final uid = user.uid;
                    await user.updateDisplayName(txtName.text.trim());
                    // Save the name to firestore
                    final service = UserService();
                    await service.createUserProfile(
                      uid: uid,
                      name: txtName.text.trim(),
                      email: txtEmail.text.trim(),
                    );
                    await service.createDefaultBudgets(uid);

                    // Navigate
                    if (context.mounted) {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => MainTabView()),
                        (route) => false,
                      );
                    }
                  } on FirebaseAuthException catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e.message ?? "Sign up failed")),
                    );
                  }
                },
              ),

              const SizedBox(height: 30),

              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SocialLoginView()),
                  );
                },
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    image: const DecorationImage(
                      image: AssetImage("assets/img/fb_btn.png"),
                    ),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset("assets/img/fb.png", width: 15, height: 15),
                      const SizedBox(width: 8),
                      Text(
                        "Continue with Facebook",
                        style: TextStyle(
                          color: TColor.gray,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),

              Text("or", style: TextStyle(color: TColor.white, fontSize: 14)),

              const SizedBox(height: 10),

              Text(
                "Do you already have an account?",
                style: TextStyle(color: TColor.white, fontSize: 14),
              ),

              const SizedBox(height: 25),

              SecondaryButton(
                title: "Sign in",
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SignInView()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
