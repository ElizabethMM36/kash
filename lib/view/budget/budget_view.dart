import 'package:flutter/material.dart';
import 'package:kash/common/color_extension.dart';
import 'package:kash/services/budget_service.dart';
import 'package:kash/view/budget/add_category_dialog.dart';
import 'dart:async';

class BudgetView extends StatefulWidget {
  const BudgetView({super.key});

  @override
  State<BudgetView> createState() => _BudgetViewState();
}

class _BudgetViewState extends State<BudgetView> {
  final BudgetService _budgetService = BudgetService();
  
  List<Map<String, dynamic>> budgets = [];
  double monthlyIncome = 0.0;
  bool isLoading = true;
  int totalPercentage = 0;
  bool isEditing = false;
  
  // Local state for editing
  List<Map<String, dynamic>> tempBudgets = [];
  StreamSubscription? _budgetSubscription;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    
    try {
      monthlyIncome = await _budgetService.getMonthlyIncome();
      
      _budgetSubscription?.cancel();
      _budgetSubscription = _budgetService.getBudgets().listen((data) {
        if (mounted) {
          int total = 0;
          for (var budget in data) {
            total += (budget['percentage'] as int? ?? 0);
          }
          
          setState(() {
            budgets = data;
            totalPercentage = total;
            isLoading = false;
            
            // If we are editing, we don't want live updates to override unless we handle merging
            // For simplicity, if editing, we ignore stream updates until done.
            if (!isEditing) {
              tempBudgets = List.from(budgets);
            }
          });
        }
      }, onError: (e) {
        if (mounted) {
          setState(() => isLoading = false);
          // Show error properly instead of crashing
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Error loading budgets: $e"),
              backgroundColor: Colors.red,
            ),
          );
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error loading budgets: $e")),
        );
      }
    }
  }

  @override
  void dispose() {
    _budgetSubscription?.cancel();
    super.dispose();
  }

  void _toggleEditMode() async {
    if (isEditing) {
      // Save Changes
      await _saveChanges();
    } else {
      // Enter Edit Mode
      setState(() {
        isEditing = true;
        tempBudgets = budgets.map((b) => Map<String, dynamic>.from(b)).toList();
      });
    }
  }

  Future<void> _saveChanges() async {
    setState(() => isLoading = true);
    try {
      Map<String, int> updates = {};
      for (var budget in tempBudgets) {
        updates[budget['id']] = budget['percentage'];
      }
      
      await _budgetService.updateMultipleBudgets(updates);
      
      setState(() {
        isEditing = false;
        isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Budgets updated successfully")),
      );
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error updating budgets: $e")),
      );
    }
  }
  
  Future<void> _addCategory() async {
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
        // Stream will update the list automatically
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error adding category: $e")),
          );
        }
      }
    }
  }

  Future<void> _deleteCategory(String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Category?"),
        content: const Text("Are you sure you want to delete this budget category?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
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
        await _budgetService.deleteCategory(docId);
        setState(() {
          tempBudgets.removeWhere((b) => b['id'] == docId);
        });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error deleting category: $e")),
          );
        }
      }
    }
  }
  
  Future<void> _resetToDefaults() async {
     final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Reset to Defaults?"),
        content: const Text("This will delete all custom categories and restore default budgets. This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Reset", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _budgetService.resetToDefaults();
        setState(() {
          isEditing = false; 
        });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error resetting budgets: $e")),
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

  Color _getProgressColor(double percent) {
    if (percent >= 0.9) return Colors.red;
    if (percent >= 0.7) return Colors.orange;
    return TColor.secondary;
  }
  
  int _calculateTempTotal() {
    int total = 0;
    for (var budget in tempBudgets) {
      total += (budget['percentage'] as int? ?? 0);
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final displayBudgets = isEditing ? tempBudgets : budgets;
    final displayTotalPercentage = isEditing ? _calculateTempTotal() : totalPercentage;
    
    return Scaffold(
      backgroundColor: TColor.primaryBg,
      appBar: AppBar(
        backgroundColor: TColor.primaryBg,
        elevation: 0,
        centerTitle: true,
        title: Text(
          isEditing ? "Edit Budgets" : "Budgets",
          style: TextStyle(
            color: TColor.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _toggleEditMode,
            icon: Icon(
              isEditing ? Icons.check : Icons.edit, 
              color: TColor.white
            ),
          )
        ],
      ),
      body: isLoading && budgets.isEmpty
          ? Center(child: CircularProgressIndicator(color: TColor.secondary))
          : displayBudgets.isEmpty && !isEditing
              ? _buildEmptyState()
              : _buildBudgetList(displayBudgets, displayTotalPercentage),
      floatingActionButton: isEditing ? FloatingActionButton(
        onPressed: _addCategory,
        backgroundColor: TColor.secondary,
        child: const Icon(Icons.add, color: Colors.white),
      ) : null,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.pie_chart_outline,
            size: 80,
            color: TColor.gray60,
          ),
          const SizedBox(height: 20),
          Text(
            "No budgets set up yet",
            style: TextStyle(
              color: TColor.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "Tap the edit button to create your budgets",
            style: TextStyle(
              color: TColor.gray30,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: _toggleEditMode, // Enter edit mode directly
            icon: const Icon(Icons.add),
            label: const Text("Set Up Budgets"),
            style: ElevatedButton.styleFrom(
              backgroundColor: TColor.secondary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetList(List<Map<String, dynamic>> budgetList, int currentTotalPercentage) {
    return Column(
      children: [
        // Summary Header
        Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                TColor.secondary.withValues(alpha: 0.3),
                TColor.secondary.withValues(alpha: 0.1),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: TColor.secondary.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Monthly Income",
                        style: TextStyle(
                          color: TColor.gray30,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatCurrency(monthlyIncome),
                        style: TextStyle(
                          color: TColor.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: currentTotalPercentage == 100
                          ? TColor.secondary.withValues(alpha: 0.2)
                          : currentTotalPercentage > 100
                              ? Colors.red.withValues(alpha: 0.2)
                              : TColor.yellow.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "$currentTotalPercentage% Allocated",
                      style: TextStyle(
                        color: currentTotalPercentage == 100
                            ? TColor.secondary
                            : currentTotalPercentage > 100
                                ? Colors.red
                                : TColor.yellow,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              if (isEditing) ...[
                const SizedBox(height: 10),
                   SizedBox(
                      width: double.infinity,
                      child: TextButton.icon(
                        onPressed: _resetToDefaults,
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text("Reset to Recommended Defaults"),
                        style: TextButton.styleFrom(
                          foregroundColor: TColor.gray30,
                        ),
                      ),
                    ),
              ]
            ],
          ),
        ),

        // Budget Cards
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20), // Added bottom padding
            itemCount: budgetList.length,
            itemBuilder: (context, index) {
              final budget = budgetList[index];
              final category = budget['category'] as String;
              final percentage = budget['percentage'] as int;
              final colorValue = budget['colorValue'] as int? ?? 0xFF00B894;
              final color = Color(colorValue);
              final spent = (budget['spent'] as num?)?.toDouble() ?? 0.0;
              final limit = monthlyIncome * percentage / 100;
              final remaining = limit - spent;
              final spentPercent = limit > 0 ? (spent / limit).clamp(0.0, 1.0) : 0.0;
              final docId = budget['id'] as String;

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: TColor.gray80,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Row
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _getCategoryIcon(category),
                            color: color,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                category,
                                style: TextStyle(
                                  color: TColor.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                isEditing 
                                  ? "$percentage% limit" 
                                  : "$percentage% of income",
                                style: TextStyle(
                                  color: TColor.gray30,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              _formatCurrency(limit),
                              style: TextStyle(
                                color: TColor.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                         if (isEditing)
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () => _deleteCategory(docId),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Content: Progress Bar OR Slider
                    if (isEditing) 
                      Column(
                        children: [
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
                                min: 1,
                                max: 50,
                                divisions: 49,
                                onChanged: (value) {
                                  setState(() {
                                    budgetList[index]['percentage'] = value.toInt();
                                  });
                                },
                              ),
                            ),
                        ],
                      )
                    else
                      Column(
                        children: [
                           ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: spentPercent,
                              backgroundColor: TColor.gray60.withValues(alpha: 0.3),
                              valueColor: AlwaysStoppedAnimation(
                                _getProgressColor(spentPercent),
                              ),
                              minHeight: 8,
                            ),
                          ),
                           const SizedBox(height: 12),
                           Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                RichText(
                                  text: TextSpan(
                                    children: [
                                      TextSpan(
                                        text: _formatCurrency(spent),
                                        style: TextStyle(
                                          color: TColor.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      TextSpan(
                                        text: " spent",
                                        style: TextStyle(
                                          color: TColor.gray30,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: remaining >= 0
                                        ? TColor.secondary.withValues(alpha: 0.15)
                                        : Colors.red.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    remaining >= 0
                                        ? "${_formatCurrency(remaining)} left"
                                        : "${_formatCurrency(remaining.abs())} over",
                                    style: TextStyle(
                                      color: remaining >= 0 ? TColor.secondary : Colors.red,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                        ] 
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'rent/housing':
      case 'rent_housing': // Handle slugified
        return Icons.home_rounded;
      case 'groceries':
        return Icons.shopping_cart_rounded;
      case 'transport':
        return Icons.directions_car_rounded;
      case 'utilities':
        return Icons.bolt_rounded;
      case 'healthcare':
        return Icons.medical_services_rounded;
      case 'dining out':
        return Icons.restaurant_rounded;
      case 'entertainment':
        return Icons.movie_rounded;
      case 'shopping':
        return Icons.shopping_bag_rounded;
      case 'subscriptions':
        return Icons.subscriptions_rounded;
      case 'personal care':
        return Icons.spa_rounded;
      case 'savings':
        return Icons.savings_rounded;
      case 'others':
        return Icons.more_horiz_rounded;
      case 'education':
        return Icons.school_rounded;
      case 'gifts':
        return Icons.card_giftcard_rounded;
      case 'travel':
        return Icons.flight_rounded;
      case 'pets':
        return Icons.pets_rounded;
      case 'insurance':
        return Icons.security_rounded;
      default:
        return Icons.category_rounded;
    }
  }
}
