import 'package:flutter/material.dart';
import 'package:kash/common/color_extension.dart';

class SplitStep2 extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;
  const SplitStep2({super.key, required this.onNext, required this.onBack});

  @override
  State<SplitStep2> createState() => _SplitStep2State();
}

class _SplitStep2State extends State<SplitStep2> {
  // Method
  String method = "Equally";
  List<String> methods = ["Equally", "Unequally", "Percentage"];

  // Exclude self?
  bool excludeSelf = false;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: widget.onBack,
                icon: Icon(Icons.arrow_back, color: TColor.white),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "How to split?",
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

          // 3. Method
          Text(
            "How do you want to split?",
            style: TextStyle(color: TColor.gray30, fontSize: 14),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: methods
                .map(
                  (s) => _buildChoiceChip(s, method, (val) {
                    setState(() {
                      method = val;
                    });
                  }),
                )
                .toList(),
          ),

          const SizedBox(height: 30),
          // 5. Exclude self
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Are you included in this split?",
                style: TextStyle(color: TColor.white, fontSize: 16),
              ),
              Switch(
                value: !excludeSelf,
                onChanged: (val) {
                  setState(() {
                    excludeSelf = !val;
                  });
                },
                activeThumbColor: TColor.secondary,
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 5.0),
            child: Text(
              excludeSelf ? "No (You didn't partake)" : "Yes (Default)",
              style: TextStyle(color: TColor.gray30, fontSize: 12),
            ),
          ),

          const SizedBox(height: 40),
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
              child: Text(
                "Next",
                style: TextStyle(
                  color: TColor.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChoiceChip(
    String label,
    String currentSelection,
    Function(String) onSelect,
  ) {
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
