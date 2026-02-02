import 'package:flutter/material.dart';
import 'package:kash/common/color_extension.dart';

class SplitStep3 extends StatefulWidget {
  final VoidCallback onFinish;
  final VoidCallback onBack;
  const SplitStep3({super.key, required this.onFinish, required this.onBack});

  @override
  State<SplitStep3> createState() => _SplitStep3State();
}

class _SplitStep3State extends State<SplitStep3> {
    
  // Settlement Date
  String settleDate = "Today";
  List<String> dates = ["Today", "In 7 days", "Custom date"];

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
                  "Summary & Confirm",
                  style: TextStyle(
                    color: TColor.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                             ),
               ),
            ],
          ),
          const SizedBox(height: 25),
          
          // 6. Settlement
          Text("When should this be settled?", style: TextStyle(color: TColor.gray30, fontSize: 14)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: dates.map((s) => _buildChoiceChip(s, settleDate, (val) {
              setState(() {
                settleDate = val;
              });
            })).toList(),
          ),
          
          const SizedBox(height: 30),
          // Summary Card
          Container(
            padding: const EdgeInsets.all(20),
             decoration: BoxDecoration(
                color: TColor.gray60.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: TColor.secondary.withOpacity(0.5)),
              ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Expense Summary", style: TextStyle(color: TColor.secondary, fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 15),
                _buildSummaryLine("You paid", "₹1,200", isBold: true),
                const Divider(color: Colors.white24, height: 20),
                _buildSummaryLine("You'll get from Alex", "₹300"),
                _buildSummaryLine("You'll get from Sam", "₹300"),
                _buildSummaryLine("You'll get from Taylor", "₹300"),
                 const Divider(color: Colors.white24, height: 20),
                 Text("Clear expectation = Better trust.", style: TextStyle(color: TColor.gray30, fontStyle: FontStyle.italic, fontSize: 12)),
              ],
            ),
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
              child: Text("Save & Notify", style: TextStyle(color: TColor.primary, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          )
        ],
      ),
    );
  }
  
  Widget _buildSummaryLine(String label, String amount, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: TColor.white, fontSize: 14, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(amount, style: TextStyle(color: TColor.white, fontSize: 14, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
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
