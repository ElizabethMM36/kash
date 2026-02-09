import 'package:flutter/material.dart';
import 'package:kash/common/color_extension.dart';
import 'package:kash/services/budget_service.dart';
import 'package:kash/view/budget/add_category_dialog.dart';

class EditBudgetView extends StatefulWidget {
  const EditBudgetView({super.key});

  @override
  State<EditBudgetView> createState() => _EditBudgetViewState();
}

class _EditBudgetViewState extends State<EditBudgetView> {
  final BudgetService _budgetService = BudgetService();
  
  List<Map<String, dynamic>> budgets = [];
  double monthlyIncome = 0.0;
  bool isLoading = true;
  bool hasChanges = false;
  
  // Track local changes before saving
  Map<String, int> localPercentages = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    
    try {
      monthlyIncome = await _budgetService.getMonthlyIncome();
      
      // Listen to budgets stream
      _budgetService.getBudgets().listen((data) {
        if (mounted) {
          setState(() {
            budgets = data;
            // Initialize local percentages
            for (var budget in data) {
              if (!localPercentages.containsKey(budget['category'])) {
                localPercentages[budget['category']] = budget['percentage'];
              }
            }
            isLoading = false;
          });
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error loading data: $e")),
        );
      }
    }
  }

  int get totalPercentage {
    int total = 0;
    for (var entry in localPercentages.entries) {
      total += entry.value;
    }
    return total;
  }

  double get remainingAmount {
    return monthlyIncome * (100 - totalPercentage) / 100;
  }

  Future<void> _saveChanges() async {
    try {
      await _budgetService.updateMultipleBudgets(localPercentages);
      if (mounted) {
        setState(() => hasChanges = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Budgets saved successfully!"),
            backgroundColor: TColor.secondary,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error saving: $e")),
        );
      }
    }
  }

  Future<void> _resetToDefaults() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: TColor.gray80,
        title: Text("Reset to Defaults?", style: TextStyle(color: TColor.white)),
        content: Text(
          "This will delete all your custom budgets and restore the default categories.",
          style: TextStyle(color: TColor.gray30),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("Cancel", style: TextStyle(color: TColor.gray30)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text("Reset", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _budgetService.resetToDefaults();
        localPercentages.clear();
        _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text("Budgets reset to defaults!"),
              backgroundColor: TColor.secondary,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error resetting: $e")),
          );
        }
      }
    }
  }

  Future<void> _deleteCategory(String category) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: TColor.gray80,
        title: Text("Delete '$category'?", style: TextStyle(color: TColor.white)),
        content: Text(
          "This category and its budget will be permanently deleted.",
          style: TextStyle(color: TColor.gray30),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("Cancel", style: TextStyle(color: TColor.gray30)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _budgetService.deleteCategory(category);
        setState(() {
          localPercentages.remove(category);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("'$category' deleted!"),
              backgroundColor: TColor.secondary,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error deleting: $e")),
          );
        }
      }
    }
  }

  void _showAddCategoryDialog() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const AddCategoryDialog(),
    );

    if (result != null) {
      try {
        await _budgetService.addCategory(
          category: result['category'],
          percentage: result['percentage'],
          colorValue: result['colorValue'],
        );
        setState(() {
          localPercentages[result['category']] = result['percentage'];
          hasChanges = true;
        });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error adding category: $e")),
          );
        }
      }
    }
  }

  String _formatCurrency(double amount) {
    if (amount >= 100000) {
      return "₹${(amount / 100000).toStringAsFixed(1)}L";
    } else if (amount >= 1000) {
      return "₹${(amount / 1000).toStringAsFixed(1)}K";
    }
    return "₹${amount.toStringAsFixed(0)}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TColor.primaryBg,
      appBar: AppBar(
        backgroundColor: TColor.primaryBg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: TColor.white),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          "Edit Budgets",
          style: TextStyle(
            color: TColor.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          TextButton(
            onPressed: hasChanges ? _saveChanges : null,
            child: Text(
              "Save",
              style: TextStyle(
                color: hasChanges ? TColor.secondary : TColor.gray60,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddCategoryDialog,
        backgroundColor: TColor.secondary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: TColor.secondary))
          : Column(
              children: [
                // Monthly Income Header
                Container(
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: TColor.gray80,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Monthly Income",
                        style: TextStyle(
                          color: TColor.gray30,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        _formatCurrency(monthlyIncome),
                        style: TextStyle(
                          color: TColor.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                // Budget List
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: budgets.length,
                    itemBuilder: (context, index) {
                      final budget = budgets[index];
                      final category = budget['category'] as String;
                      final percentage = localPercentages[category] ?? budget['percentage'];
                      final colorValue = budget['colorValue'] as int;
                      final color = Color(colorValue);
                      final limit = monthlyIncome * percentage / 100;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: TColor.gray80,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Category header with delete button
                            Row(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    category,
                                    style: TextStyle(
                                      color: TColor.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Text(
                                  "$percentage%",
                                  style: TextStyle(
                                    color: TColor.secondary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: Icon(Icons.delete_outline, color: TColor.gray60, size: 20),
                                  onPressed: () => _deleteCategory(category),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Slider
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                activeTrackColor: color,
                                inactiveTrackColor: TColor.gray60.withValues(alpha: 0.3),
                                thumbColor: color,
                                overlayColor: color.withValues(alpha: 0.2),
                                trackHeight: 6,
                              ),
                              child: Slider(
                                value: percentage.toDouble(),
                                min: 0,
                                max: 50,
                                divisions: 50,
                                onChanged: (value) {
                                  setState(() {
                                    localPercentages[category] = value.toInt();
                                    hasChanges = true;
                                  });
                                },
                              ),
                            ),

                            // Amount display
                            Text(
                              "= ${_formatCurrency(limit)}",
                              style: TextStyle(
                                color: TColor.gray30,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // Total Percentage Footer
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: TColor.gray80,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: SafeArea(
                    child: Column(
                      children: [
                        // Progress bar
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: (totalPercentage / 100).clamp(0.0, 1.0),
                                  backgroundColor: TColor.gray60.withValues(alpha: 0.3),
                                  valueColor: AlwaysStoppedAnimation(
                                    totalPercentage > 100 ? Colors.red : TColor.secondary,
                                  ),
                                  minHeight: 8,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              "$totalPercentage%",
                              style: TextStyle(
                                color: totalPercentage > 100 ? Colors.red : TColor.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Status text
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              totalPercentage > 100
                                  ? "⚠️ Over-allocated by ${totalPercentage - 100}%"
                                  : totalPercentage == 100
                                      ? "✅ Perfectly allocated!"
                                      : "💰 Remaining: ${100 - totalPercentage}%",
                              style: TextStyle(
                                color: totalPercentage > 100 ? Colors.red : TColor.gray30,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              _formatCurrency(remainingAmount.abs()),
                              style: TextStyle(
                                color: totalPercentage > 100 ? Colors.red : TColor.secondary,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Reset button
                        TextButton.icon(
                          onPressed: _resetToDefaults,
                          icon: Icon(Icons.refresh, color: TColor.gray30, size: 18),
                          label: Text(
                            "Reset to Defaults",
                            style: TextStyle(color: TColor.gray30),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
