import 'package:flutter/material.dart';
import 'package:kash/common/color_extension.dart';
import 'package:kash/view/add_income/income_step1.dart';
import 'package:kash/view/add_income/income_step2.dart';
import 'package:kash/view/add_income/income_step3.dart';

class AddIncomeView extends StatefulWidget {
  const AddIncomeView({super.key});

  @override
  State<AddIncomeView> createState() => _AddIncomeViewState();
}

class _AddIncomeViewState extends State<AddIncomeView> {
  PageController controller = PageController();
  int currentStep = 0;

  @override
  Widget build(BuildContext context) {
    return Container(
       height: MediaQuery.of(context).size.height * 0.85, // Take up mostly full screen
       padding: const EdgeInsets.all(20),
       decoration: BoxDecoration(
        color: TColor.gray80,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
      ),
      child: Column(
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 50,
              height: 4,
              decoration: BoxDecoration(
                color: TColor.gray30,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          
          // Progress Indicator
          Row(
            children: [1, 2, 3].map((step) {
              int index = step - 1;
              bool isActive = index <= currentStep;
              return Expanded(
                child: Container(
                  height: 4,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: isActive ? TColor.secondary : TColor.gray60,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Content
          Expanded(
            child: PageView(
              controller: controller,
              physics: const NeverScrollableScrollPhysics(), // Disable swipe to enforce "Next" button
              children: [
                IncomeStep1(
                  onNext: () {
                    setState(() {
                      currentStep = 1;
                    });
                     controller.animateToPage(1, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                  },
                ),
                IncomeStep2(
                  onNext: () {
                     setState(() {
                      currentStep = 2;
                    });
                     controller.animateToPage(2, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                  },
                  onBack: () {
                     setState(() {
                      currentStep = 0;
                    });
                     controller.animateToPage(0, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                  },
                ),
                IncomeStep3(
                   onFinish: () {
                     // TODO: Save Data
                     Navigator.pop(context);
                  },
                  onBack: () {
                     setState(() {
                      currentStep = 1;
                    });
                     controller.animateToPage(1, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                  },
                )
              ],
            ),
          ),
        ],
      )
    );
  }
}
