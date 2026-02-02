import 'package:flutter/material.dart';
import 'package:kash/common/color_extension.dart';
import 'package:kash/common_widget/secondary_boutton.dart';
import 'package:kash/view/login/sign_up_view.dart';

class SocialLoginView extends StatefulWidget {
  const SocialLoginView({super.key});

  @override
  State<SocialLoginView> createState() => _SocialLoginViewState();
}

class _SocialLoginViewState extends State<SocialLoginView> {
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

              _socialButton(
                "assets/img/google_btn.png",
                "assets/img/google.png",
                "Continue with Google",
                TColor.black,
              ),

              const SizedBox(height: 15),

              _socialButton(
                "assets/img/fb_btn.png",
                "assets/img/fb.png",
                "Continue with Facebook",
                TColor.gray,
              ),

              const SizedBox(height: 25),

              Text("or", style: TextStyle(color: TColor.white, fontSize: 14)),

              const SizedBox(height: 25),

              SecondaryButton(
                title: "Sign up with email",
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SignUpView()),
                  );
                },
              ),

              const SizedBox(height: 20),

              Text(
                "By registering, you agree to our Terms of Use. Learn how we collect, use and share your data.",
                textAlign: TextAlign.center,
                style: TextStyle(color: TColor.white, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _socialButton(String bg, String icon, String text, Color textColor) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        image: DecorationImage(image: AssetImage(bg)),
        borderRadius: BorderRadius.circular(30),
      ),
      alignment: Alignment.center,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(icon, width: 15, height: 15),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: textColor,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
