import 'package:flutter/material.dart';
import 'package:kash/common/color_extension.dart';
import 'package:kash/services/budget_service.dart';
import 'package:kash/view/budget/edit_budget_view.dart';

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

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    
    try {
      monthlyIncome = await _budgetService.getMonthlyIncome();
      
      _budgetService.getBudgets().listen((data) {
        if (mounted) {
          int total = 0;
          for (var budget in data) {
            total += (budget['percentage'] as int? ?? 0);
          }
          
          setState(() {
            budgets = data;
            totalPercentage = total;
            isLoading = false;
          });
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

  void _openEditBudgets() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EditBudgetView()),
    );
    
    if (result == true) {
      _loadData();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TColor.primaryBg,
      appBar: AppBar(
        backgroundColor: TColor.primaryBg,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "Budgets",
          style: TextStyle(
            color: TColor.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _openEditBudgets,
            icon: Icon(Icons.edit, color: TColor.white),
          )
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: TColor.secondary))
          : budgets.isEmpty
              ? _buildEmptyState()
              : _buildBudgetList(),
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
            onPressed: _openEditBudgets,
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

  Widget _buildBudgetList() {
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
                      color: totalPercentage == 100
                          ? TColor.secondary.withValues(alpha: 0.2)
                          : totalPercentage > 100
                              ? Colors.red.withValues(alpha: 0.2)
                              : TColor.yellow.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "$totalPercentage% Allocated",
                      style: TextStyle(
                        color: totalPercentage == 100
                            ? TColor.secondary
                            : totalPercentage > 100
                                ? Colors.red
                                : TColor.yellow,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Budget Cards
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: budgets.length,
            itemBuilder: (context, index) {
              final budget = budgets[index];
              final category = budget['category'] as String;
              final percentage = budget['percentage'] as int;
              final colorValue = budget['colorValue'] as int? ?? 0xFF00B894;
              final color = Color(colorValue);
              final spent = (budget['spent'] as num?)?.toDouble() ?? 0.0;
              final limit = monthlyIncome * percentage / 100;
              final remaining = limit - spent;
              final spentPercent = limit > 0 ? (spent / limit).clamp(0.0, 1.0) : 0.0;

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
                                "$percentage% of income",
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
                            Text(
                              "limit",
                              style: TextStyle(
                                color: TColor.gray30,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Progress Bar
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

                    // Footer Row
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
