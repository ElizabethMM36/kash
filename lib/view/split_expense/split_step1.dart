import 'package:flutter/material.dart';
import 'package:kash/common/color_extension.dart';

class SplitStep1 extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;
  const SplitStep1({super.key, required this.onNext, required this.onBack});

  @override
  State<SplitStep1> createState() => _SplitStep1State();
}

class _SplitStep1State extends State<SplitStep1> {
  // Who paid?
  String payer = "You";
  List<String> possiblePayers = ["You", "Alex", "Sam"]; // Example: Should be dynamic

  // With whom?
  List<String> potentialSplitters = ["Alex", "Sam", "Jordan", "Taylor"];
  List<String> selectedSplitters = [];

  TextEditingController newPersonController = TextEditingController();

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
                  "Who paid & With whom?",
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

          // 1. Who paid?
          Text("Who paid for this expense?", style: TextStyle(color: TColor.gray30, fontSize: 14)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: possiblePayers.map((s) => _buildChoiceChip(s, payer, (val) {
              setState(() {
                payer = val;
              });
            })).toList(),
          ),
          
          const SizedBox(height: 25),
          // 2. With whom?
          Text("Split with?", style: TextStyle(color: TColor.gray30, fontSize: 14)),
          const SizedBox(height: 10),
          ...potentialSplitters.map((s) => _buildCheckboxRow(s)).toList(),
          
          // Add new person
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: newPersonController,
                    style: TextStyle(color: TColor.white),
                    decoration: InputDecoration(
                       hintText: "Add new person (+ Name)",
                       hintStyle: TextStyle(color: TColor.gray50),
                       isDense: true,
                       enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: TColor.gray60)),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.add_circle, color: TColor.secondary),
                  onPressed: () {
                    if(newPersonController.text.isNotEmpty) {
                      setState(() {
                         potentialSplitters.add(newPersonController.text);
                         selectedSplitters.add(newPersonController.text);
                         newPersonController.clear();
                      });
                    }
                  },
                )
              ],
            ),
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

  Widget _buildCheckboxRow(String name) {
    bool isSelected = selectedSplitters.contains(name);
    return InkWell(
      onTap: () {
        setState(() {
          if(isSelected) {
            selectedSplitters.remove(name);
          } else {
            selectedSplitters.add(name);
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.check_box : Icons.check_box_outline_blank,
              color: isSelected ? TColor.secondary : TColor.gray30,
            ),
            const SizedBox(width: 15),
            Text(name, style: TextStyle(color: TColor.white, fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
