import 'package:flutter/material.dart';
import 'package:kash/common/color_extension.dart';

class IncomeStep2 extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;
  const IncomeStep2({super.key, required this.onNext, required this.onBack});

  @override
  State<IncomeStep2> createState() => _IncomeStep2State();
}

class _IncomeStep2State extends State<IncomeStep2> {
  // Fixed Expenses
  final List<String> fixedOptions = ["Rent", "EMI / Loan", "Subscriptions", "Utilities", "Insurance"];
  final List<String> selectedFixed = [];
  final Map<String, TextEditingController> fixedAmountControllers = {};
  
  // Savings
  double savingPercentage = 20;

  // Spending Style
  String spendingStyle = "I spend freely but within limits";
  final List<String> styles = [
    "I track every rupee carefully",
    "I spend freely but within limits",
    "I don’t usually track spending"
  ];

  @override
  void dispose() {
    for (var controller in fixedAmountControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

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
                  "Spending Profile",
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
              "Help us customize your experience.",
              style: TextStyle(color: TColor.gray30, fontSize: 14),
                       ),
           ),
          const SizedBox(height: 25),

          // 5. Fixed Expenses
          Text("Fixed Monthly Expenses", style: TextStyle(color: TColor.gray30, fontSize: 14)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: fixedOptions.map((s) => _buildFilterChip(s)).toList(),
          ),
          
          if (selectedFixed.isNotEmpty) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: TColor.gray60.withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: TColor.gray60.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Enter Monthly Amounts", style: TextStyle(color: TColor.white, fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 15),
                  ...selectedFixed.map((key) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              key, 
                              style: TextStyle(color: TColor.gray30, fontSize: 14),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 3,
                            child: SizedBox(
                              height: 40,
                              child: TextField(
                                controller: fixedAmountControllers[key],
                                keyboardType: TextInputType.number,
                                style: TextStyle(color: TColor.white, fontSize: 14),
                                decoration: InputDecoration(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 0),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: TColor.gray60),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: TColor.secondary),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  hintText: "Amount",
                                  hintStyle: TextStyle(color: TColor.gray50),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ],
          
          const SizedBox(height: 25),
          // 6. Savings Preference
           Text("Savings Target: ${savingPercentage.toInt()}%", style: TextStyle(color: TColor.gray30, fontSize: 14)),
           Slider(
             value: savingPercentage,
             min: 0,
             max: 50,
             divisions: 10,
             activeColor: TColor.secondary,
             inactiveColor: TColor.gray60,
             label: "${savingPercentage.toInt()}%",
             onChanged: (val) {
               setState(() {
                 savingPercentage = val;
               });
             },
           ),
           
           const SizedBox(height: 25),
           // 7. Spending Style
           Text("Spending Style", style: TextStyle(color: TColor.gray30, fontSize: 14)),
           const SizedBox(height: 10),
           Column(
             children: styles.map((s) => _buildRadioStyle(s)).toList(),
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

  Widget _buildFilterChip(String label) {
    bool isSelected = selectedFixed.contains(label);
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (val) {
        setState(() {
          if(val) {
            selectedFixed.add(label);
            fixedAmountControllers[label] = TextEditingController();
          } else {
            selectedFixed.remove(label);
            fixedAmountControllers[label]?.dispose();
            fixedAmountControllers.remove(label);
          }
        });
      },
      backgroundColor: TColor.gray60.withOpacity(0.2),
      selectedColor: TColor.secondary,
      labelStyle: TextStyle(
          color: isSelected ? TColor.primary : TColor.gray30,
          fontWeight: FontWeight.w600,
        ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide.none),
      checkmarkColor: TColor.primary,
    );
  }

  Widget _buildRadioStyle(String label) {
    bool isSelected = spendingStyle == label;
    return InkWell(
      onTap: () {
        setState(() {
          spendingStyle = label;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: isSelected ? TColor.secondary.withOpacity(0.1) : TColor.gray60.withOpacity(0.2),
          border: isSelected ? Border.all(color: TColor.secondary) : null,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? TColor.secondary : TColor.gray30,
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: TColor.white,
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
