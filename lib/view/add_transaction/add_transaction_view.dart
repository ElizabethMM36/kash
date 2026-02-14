import 'package:flutter/material.dart';
import 'package:kash/common/color_extension.dart';
import 'package:kash/common_widget/primary_button.dart';
import 'package:kash/common_widget/round_textfield.dart';
import 'package:kash/services/budget_service.dart';
import 'package:kash/services/transaction_service.dart';
import 'dart:async';

class AddTransactionView extends StatefulWidget {
  const AddTransactionView({super.key});

  @override
  State<AddTransactionView> createState() => _AddTransactionViewState();
}

class _AddTransactionViewState extends State<AddTransactionView> {
  TextEditingController txtAmount = TextEditingController();
  TextEditingController txtDate = TextEditingController();
  TextEditingController txtNote = TextEditingController();

  String? selectedCategory;
  List<String> categories = [];
  bool isCategoriesLoading = true;
  bool isLoading = false;

  final TransactionService _transactionService = TransactionService();
  final BudgetService _budgetService = BudgetService();
  StreamSubscription? _categorySub;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  void _loadCategories() {
    _categorySub = _budgetService.getCategoryNames().listen((names) {
      if (mounted) {
        setState(() {
          categories = names;
          isCategoriesLoading = false;

          // If selected category was deleted or not set, pick the first one
          if (selectedCategory == null ||
              !categories.contains(selectedCategory)) {
            selectedCategory = categories.isNotEmpty ? categories.first : null;
          }
        });
      }
    }, onError: (e) {
      if (mounted) {
        setState(() => isCategoriesLoading = false);
      }
    });
  }

  @override
  void dispose() {
    _categorySub?.cancel();
    txtAmount.dispose();
    txtDate.dispose();
    txtNote.dispose();
    super.dispose();
  }

  Future<void> _saveTransaction() async {
    if (txtAmount.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please enter an amount")));
      return;
    }

    final amount = double.tryParse(txtAmount.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid amount")),
      );
      return;
    }

    if (selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a category")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      await _transactionService.addTransaction(
        amount: amount,
        category: selectedCategory!,
        date: txtDate.text.isNotEmpty
            ? txtDate.text
            : DateTime.now().toString().split(' ')[0],
        note: txtNote.text,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Transaction saved successfully!")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error saving transaction: $e")));
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: TColor.gray80,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
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
          Text(
            "Add Transaction",
            style: TextStyle(
              color: TColor.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          RoundTextField(
            title: "Amount",
            controller: txtAmount,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 15),
          Text(
            "Category",
            style: TextStyle(color: TColor.gray30, fontSize: 12),
          ),
          const SizedBox(height: 5),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            decoration: BoxDecoration(
              color: TColor.gray60.withOpacity(0.2),
              borderRadius: BorderRadius.circular(15),
            ),
            child: isCategoriesLoading
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: TColor.gray30,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          "Loading categories...",
                          style: TextStyle(color: TColor.gray30, fontSize: 14),
                        ),
                      ],
                    ),
                  )
                : categories.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Text(
                          "No categories. Set up budgets first.",
                          style: TextStyle(color: TColor.gray30, fontSize: 14),
                        ),
                      )
                    : DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedCategory,
                          isExpanded: true,
                          dropdownColor: TColor.gray80,
                          icon:
                              Icon(Icons.arrow_drop_down, color: TColor.white),
                          style: TextStyle(color: TColor.white, fontSize: 14),
                          items: categories.map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (newValue) {
                            setState(() {
                              selectedCategory = newValue!;
                            });
                          },
                        ),
                      ),
          ),
          const SizedBox(height: 15),
          RoundTextField(
            title: "Date",
            controller: txtDate,
            keyboardType: TextInputType.datetime,
          ),
          const SizedBox(height: 15),
          RoundTextField(title: "Note", controller: txtNote),
          const SizedBox(height: 30),
          PrimaryButton(
            title: isLoading ? "Saving..." : "Save Transaction",
            onPressed: () {
              if (!isLoading) _saveTransaction();
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
