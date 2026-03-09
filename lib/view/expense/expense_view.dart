import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:kash/common/color_extension.dart';
import 'package:kash/services/transaction_service.dart';

class ExpenseView extends StatefulWidget {
  const ExpenseView({super.key});

  @override
  State<ExpenseView> createState() => _ExpenseViewState();
}

class _ExpenseViewState extends State<ExpenseView> {
  final TransactionService _transactionService = TransactionService();

  // Search
  final TextEditingController _searchController = TextEditingController();
  String _searchText = '';

  // Filter selections (null = not applied)
  String? _selectedDateFilter;
  String? _appliedDateFilter;

  String? _selectedAmountFilter;
  String? _appliedAmountFilter;

  String? _selectedTransactionFilter;
  String? _appliedTransactionFilter;

  // Filter options
  final List<String> _dateOptions = [
    'This Month',
    'Last 30 Days',
    'Last 90 Days',
  ];

  final List<String> _amountOptions = [
    'Up to ₹200',
    '₹200 – ₹500',
    '₹500 – ₹2000',
    'Above ₹2000',
  ];

  final List<String> _transactionOptions = ['Debit', 'Credit'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // --------------- Filtering Logic ---------------

  List<Map<String, dynamic>> _applyFilters(
    List<Map<String, dynamic>> transactions,
  ) {
    List<Map<String, dynamic>> filtered = List.from(transactions);

    // Search filter
    if (_searchText.isNotEmpty) {
      final query = _searchText.toLowerCase();
      filtered = filtered.where((t) {
        final note = (t['note'] as String? ?? '').toLowerCase();
        final category = (t['category'] as String? ?? '').toLowerCase();
        final date = (t['date'] as String? ?? '').toLowerCase();
        return note.contains(query) ||
            category.contains(query) ||
            date.contains(query);
      }).toList();
    }

    // Date filter
    if (_appliedDateFilter != null) {
      final now = DateTime.now();
      DateTime cutoff;
      switch (_appliedDateFilter) {
        case 'This Month':
          cutoff = DateTime(now.year, now.month, 1);
          break;
        case 'Last 30 Days':
          cutoff = now.subtract(const Duration(days: 30));
          break;
        case 'Last 90 Days':
          cutoff = now.subtract(const Duration(days: 90));
          break;
        default:
          cutoff = DateTime(2000);
      }
      filtered = filtered.where((t) {
        final createdAt = t['createdAt'];
        if (createdAt is Timestamp) {
          return createdAt.toDate().isAfter(cutoff);
        }
        return true;
      }).toList();
    }

    // Amount filter
    if (_appliedAmountFilter != null) {
      filtered = filtered.where((t) {
        final amount = (t['amount'] as num?)?.toDouble() ?? 0.0;
        switch (_appliedAmountFilter) {
          case 'Up to ₹200':
            return amount <= 200;
          case '₹200 – ₹500':
            return amount > 200 && amount <= 500;
          case '₹500 – ₹2000':
            return amount > 500 && amount <= 2000;
          case 'Above ₹2000':
            return amount > 2000;
          default:
            return true;
        }
      }).toList();
    }

    // Transaction type filter
    if (_appliedTransactionFilter != null) {
      filtered = filtered.where((t) {
        final isIncome = (t['isIncome'] as bool?) ?? false;
        if (_appliedTransactionFilter == 'Credit') return isIncome;
        if (_appliedTransactionFilter == 'Debit') return !isIncome;
        return true;
      }).toList();
    }

    return filtered;
  }

  // --------------- Filter Popup Builder ---------------

  void _showFilterPopup({
    required String title,
    required List<String> options,
    required String? currentSelection,
    required ValueChanged<String?> onApply,
    required VoidCallback onClear,
  }) {
    String? tempSelection = currentSelection;

    showModalBottomSheet(
      context: context,
      backgroundColor: TColor.gray80,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: TColor.gray60,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Title
                  Text(
                    title,
                    style: TextStyle(
                      color: TColor.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Options
                  ...options.map((option) {
                    final isSelected = tempSelection == option;
                    return GestureDetector(
                      onTap: () {
                        setModalState(() {
                          tempSelection = option;
                        });
                      },
                      child: Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? TColor.secondary.withValues(alpha: 0.15)
                              : TColor.gray70,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? TColor.secondary
                                : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                option,
                                style: TextStyle(
                                  color: isSelected
                                      ? TColor.secondary
                                      : TColor.white,
                                  fontSize: 15,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                ),
                              ),
                            ),
                            if (isSelected)
                              Icon(
                                Icons.check_circle,
                                color: TColor.secondary,
                                size: 20,
                              ),
                          ],
                        ),
                      ),
                    );
                  }),

                  const SizedBox(height: 12),

                  // Apply & Clear buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            onClear();
                          },
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: TColor.gray60),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Clear',
                            style: TextStyle(
                              color: TColor.gray30,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            onApply(tempSelection);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: TColor.secondary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Apply',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // --------------- Filter Chip Widget ---------------

  Widget _buildFilterChip({
    required IconData icon,
    required String label,
    required String? appliedValue,
    required VoidCallback onTap,
  }) {
    final bool isActive = appliedValue != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? TColor.secondary.withValues(alpha: 0.15)
              : TColor.gray80,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? TColor.secondary : TColor.gray60,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isActive ? TColor.secondary : TColor.gray30),
            const SizedBox(width: 6),
            Text(
              appliedValue ?? label,
              style: TextStyle(
                color: isActive ? TColor.secondary : TColor.gray30,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 16,
              color: isActive ? TColor.secondary : TColor.gray30,
            ),
          ],
        ),
      ),
    );
  }

  // --------------- Build ---------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TColor.primaryBg,
      appBar: AppBar(
        backgroundColor: TColor.primaryBg,
        elevation: 0,
        centerTitle: true,
        leading: Container(),
        title: Text(
          "Expenses",
          style: TextStyle(
            color: TColor.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.more_horiz, color: TColor.white),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Search Bar ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: TextField(
              controller: _searchController,
              style: TextStyle(color: TColor.white, fontSize: 14),
              onChanged: (val) {
                setState(() {
                  _searchText = val;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search transactions...',
                hintStyle: TextStyle(color: TColor.gray50, fontSize: 14),
                prefixIcon: Icon(Icons.search, color: TColor.gray50, size: 20),
                suffixIcon: _searchText.isNotEmpty
                    ? GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          setState(() {
                            _searchText = '';
                          });
                        },
                        child: Icon(Icons.close, color: TColor.gray50, size: 18),
                      )
                    : null,
                filled: true,
                fillColor: TColor.gray80,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(color: TColor.secondary, width: 1),
                ),
              ),
            ),
          ),

          // ── Filter Chips Row ──
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Row(
              children: [
                // Date filter
                _buildFilterChip(
                  icon: Icons.calendar_today_rounded,
                  label: 'Date',
                  appliedValue: _appliedDateFilter,
                  onTap: () {
                    _showFilterPopup(
                      title: 'Filter by Date',
                      options: _dateOptions,
                      currentSelection: _selectedDateFilter,
                      onApply: (val) {
                        setState(() {
                          _selectedDateFilter = val;
                          _appliedDateFilter = val;
                        });
                      },
                      onClear: () {
                        setState(() {
                          _selectedDateFilter = null;
                          _appliedDateFilter = null;
                        });
                      },
                    );
                  },
                ),
                const SizedBox(width: 8),

                // Amount filter
                _buildFilterChip(
                  icon: Icons.currency_rupee_rounded,
                  label: 'Amount',
                  appliedValue: _appliedAmountFilter,
                  onTap: () {
                    _showFilterPopup(
                      title: 'Filter by Amount',
                      options: _amountOptions,
                      currentSelection: _selectedAmountFilter,
                      onApply: (val) {
                        setState(() {
                          _selectedAmountFilter = val;
                          _appliedAmountFilter = val;
                        });
                      },
                      onClear: () {
                        setState(() {
                          _selectedAmountFilter = null;
                          _appliedAmountFilter = null;
                        });
                      },
                    );
                  },
                ),
                const SizedBox(width: 8),

                // Transaction type filter
                _buildFilterChip(
                  icon: Icons.swap_horiz_rounded,
                  label: 'Transaction',
                  appliedValue: _appliedTransactionFilter,
                  onTap: () {
                    _showFilterPopup(
                      title: 'Filter by Transaction',
                      options: _transactionOptions,
                      currentSelection: _selectedTransactionFilter,
                      onApply: (val) {
                        setState(() {
                          _selectedTransactionFilter = val;
                          _appliedTransactionFilter = val;
                        });
                      },
                      onClear: () {
                        setState(() {
                          _selectedTransactionFilter = null;
                          _appliedTransactionFilter = null;
                        });
                      },
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 4),

          // ── Transaction List ──
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _transactionService.getRecentTransactions(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final allTransactions = snapshot.data ?? [];
                final transactions = _applyFilters(allTransactions);

                if (allTransactions.isNotEmpty && transactions.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(20),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.filter_list_off,
                            color: TColor.gray30,
                            size: 48,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "No transactions match your filters",
                            style: TextStyle(
                              color: TColor.gray30,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (transactions.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(20),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.receipt_long,
                            color: TColor.gray30,
                            size: 48,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "No transactions yet",
                            style: TextStyle(
                              color: TColor.gray30,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: transactions.length,
                  itemBuilder: (context, index) {
                    final tObj = transactions[index];
                    final isIncome = (tObj['isIncome'] as bool?) ?? false;
                    final amount =
                        (tObj['amount'] as num?)?.toDouble() ?? 0.0;
                    final note = (tObj['note'] as String?) ?? '';
                    final dateStr = (tObj['date'] as String?) ?? '';

                    final displayAmount =
                        '${isIncome ? '+' : '-'}₹${amount.abs().toStringAsFixed(2)}';

                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: TColor.gray80,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: TColor.gray60.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.shopping_bag_outlined,
                              color: isIncome
                                  ? Colors.greenAccent
                                  : TColor.secondary,
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  note.isNotEmpty ? note : dateStr,
                                  style: TextStyle(
                                    color: TColor.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  dateStr,
                                  style: TextStyle(
                                    color: TColor.gray30,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            displayAmount,
                            style: TextStyle(
                              color: isIncome
                                  ? Colors.greenAccent
                                  : Colors.red,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
