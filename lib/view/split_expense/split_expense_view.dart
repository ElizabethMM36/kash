import 'package:flutter/material.dart';
import 'package:kash/common/color_extension.dart';
import 'package:kash/view/split_expense/split_step1.dart';
import 'package:kash/view/split_expense/split_step2.dart';
import 'package:kash/view/split_expense/split_step3.dart';

class SplitExpenseView extends StatefulWidget {
  final Map<String, dynamic> initialData; // Pass amount, category etc.
  const SplitExpenseView({super.key, required this.initialData});

  @override
  State<SplitExpenseView> createState() => _SplitExpenseViewState();
}

class _SplitExpenseViewState extends State<SplitExpenseView> {
  PageController controller = PageController();
  int currentStep = 0;

  @override
  Widget build(BuildContext context) {
    return Container(
       height: MediaQuery.of(context).size.height * 0.9,
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
          const SizedBox(height: 10),
          
          // Header info
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Splitting ", style: TextStyle(color: TColor.gray30, fontSize: 14)),
              Text("₹${widget.initialData['amount'] ?? '0'}", style: TextStyle(color: TColor.white, fontWeight: FontWeight.bold, fontSize: 14)),
              Text(" for ", style: TextStyle(color: TColor.gray30, fontSize: 14)),
              Text("${widget.initialData['category'] ?? 'Expense'}", style: TextStyle(color: TColor.white, fontWeight: FontWeight.bold, fontSize: 14)),
            ],
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
              physics: const NeverScrollableScrollPhysics(),
              children: [
                SplitStep1(
                  onNext: () {
                    setState(() {
                      currentStep = 1;
                    });
                     controller.animateToPage(1, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                  },
                  onBack: () => Navigator.pop(context),
                ),
                SplitStep2(
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
                SplitStep3(
                   onFinish: () {
                     // TODO: Save Split Data
                     Navigator.pop(context); // Close Split Wizard
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
