import 'package:flutter/material.dart';
import 'package:kash/common/color_extension.dart';
import 'package:kash/services/income_service.dart';
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
  bool _isSaving = false;

  // Accumulated data from all steps
  final Map<String, dynamic> _incomeData = {};

  final _incomeService = IncomeService();

  Future<void> _saveIncomeProfile() async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      await _incomeService.saveIncomeProfile(_incomeData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Income profile saved successfully!"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to save: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

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

          // Loading indicator when saving
          if (_isSaving)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: LinearProgressIndicator(
                color: TColor.secondary,
                backgroundColor: TColor.gray60,
              ),
            ),

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
                  onDataChanged: (data) {
                    _incomeData.addAll(data);
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
                  onDataChanged: (data) {
                    _incomeData.addAll(data);
                  },
                ),
                IncomeStep3(
                   onFinish: _saveIncomeProfile,
                   onBack: () {
                     setState(() {
                      currentStep = 1;
                    });
                     controller.animateToPage(1, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                  },
                  onDataChanged: (data) {
                    _incomeData.addAll(data);
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
