import 'package:flutter/material.dart';
import 'package:kash/common/color_extension.dart';
import 'package:kash/common_widget/round_textfield.dart';

class IncomeStep1 extends StatefulWidget {
  final VoidCallback onNext;
  const IncomeStep1({super.key, required this.onNext});

  @override
  State<IncomeStep1> createState() => _IncomeStep1State();
}

class _IncomeStep1State extends State<IncomeStep1> {
  String selectedSource = "Salary";
  TextEditingController txtAmount = TextEditingController();
  String selectedFrequency = "Monthly";
  TextEditingController txtDate = TextEditingController();

  final List<String> sources = ["Salary", "Freelance", "Business", "Allowance", "Other"];
  final List<String> frequencies = ["Monthly", "Weekly", "Bi-weekly", "One-time"];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Essential Income Details",
            style: TextStyle(
              color: TColor.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Let's get the basics down.",
            style: TextStyle(color: TColor.gray30, fontSize: 14),
          ),
          const SizedBox(height: 25),
          
          // 1. Income Source
          Text("Calculated Source", style: TextStyle(color: TColor.gray30, fontSize: 14)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: sources.map((s) => _buildChoiceChip(s, selectedSource, (val) {
              setState(() {
                selectedSource = val;
              });
            })).toList(),
          ),
          
          const SizedBox(height: 25),
          // 2. Amount
           RoundTextField(
            title: "Amount (Net Income)",
            controller: txtAmount,
            keyboardType: TextInputType.number,
          ),

          const SizedBox(height: 25),
          // 3. Frequency
           Text("Frequency", style: TextStyle(color: TColor.gray30, fontSize: 14)),
          const SizedBox(height: 10),
           Wrap(
            spacing: 10,
            runSpacing: 10,
            children: frequencies.map((s) => _buildChoiceChip(s, selectedFrequency, (val) {
              setState(() {
                selectedFrequency = val;
              });
            })).toList(),
          ),

          const SizedBox(height: 25),
          // 4. Expected Date
          RoundTextField(
            title: "Expected Date (e.g. 1st)",
            controller: txtDate,
            keyboardType: TextInputType.datetime,
          ),
          
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: widget.onNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: TColor.secondary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: Text("Next", style: TextStyle(color: TColor.primary, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildChoiceChip(String label, String currentSelection, Function(String) onSelect) {
    bool isSelected = label == currentSelection;
    return InkWell(
      onTap: () => onSelect(label),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? TColor.secondary : TColor.gray60.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
          border: isSelected ? Border.all(color: TColor.secondary) : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? TColor.primary : TColor.gray30,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
