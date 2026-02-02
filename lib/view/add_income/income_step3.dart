import 'package:flutter/material.dart';
import 'package:kash/common/color_extension.dart';

class IncomeStep3 extends StatefulWidget {
  final VoidCallback onFinish;
  final VoidCallback onBack;
  const IncomeStep3({super.key, required this.onFinish, required this.onBack});

  @override
  State<IncomeStep3> createState() => _IncomeStep3State();
}

class _IncomeStep3State extends State<IncomeStep3> {
  // Priorities
  String priority = "Save more";
  final List<String> priorities = ["Save more", "Reduce expenses", "Clear debt", "Enjoy life 😄"];

  // Risk Comfort
  bool riskComfort = true; // Yes I manage

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Row(
            children: [
               IconButton(onPressed: widget.onBack, icon: Icon(Icons.arrow_back, color: TColor.white)),
               const SizedBox(width: 8),
               Expanded(
                 child: Text(
                  "Smart Preferences",
                  style: TextStyle(
                    color: TColor.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                             ),
               ),
            ],
          ),
          const SizedBox(height: 8),
           Padding(
             padding: const EdgeInsets.only(left: 48.0),
             child: Text(
              "Optional customization.",
              style: TextStyle(color: TColor.gray30, fontSize: 14),
                       ),
           ),
          const SizedBox(height: 25),
          
          // 8. Financial Priority
          Text("What’s important to you now?", style: TextStyle(color: TColor.gray30, fontSize: 14)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: priorities.map((s) => _buildChoiceChip(s, priority, (val) {
              setState(() {
                priority = val;
              });
            })).toList(),
          ),

          const SizedBox(height: 25),
          // 9. Risk Comfort
          Text("Are you comfortable spending close to limit?", style: TextStyle(color: TColor.gray30, fontSize: 14)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _buildRiskOption("Yes, I manage", true)),
              const SizedBox(width: 15),
              Expanded(child: _buildRiskOption("No, warn me", false)),
            ],
          ),

          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: widget.onFinish,
              style: ElevatedButton.styleFrom(
                backgroundColor: TColor.secondary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: Text("Finish", style: TextStyle(color: TColor.primary, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
          const SizedBox(height: 15),
           Center(
             child: TextButton(
               onPressed: widget.onFinish,
               child: Text("Skip for now", style: TextStyle(color: TColor.gray30)),
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

  Widget _buildRiskOption(String label, bool value) {
    bool isSelected = riskComfort == value;
    return InkWell(
      onTap: () {
        setState(() {
          riskComfort = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
           color: isSelected ? TColor.secondary.withOpacity(0.2) : TColor.gray60.withOpacity(0.2),
           border: isSelected ? Border.all(color: TColor.secondary) : null,
           borderRadius: BorderRadius.circular(15),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
             color: isSelected ? TColor.secondary : TColor.gray30,
             fontWeight: FontWeight.w600
          ),
        ),
      ),
    );
  }
}
