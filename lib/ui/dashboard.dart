import 'package:expense_tracker/abstraction/database/database_service.dart';
import 'package:expense_tracker/abstraction/models/expense.dart';
import 'package:expense_tracker/main.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with TickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;
  final DatabaseService _db = databaseService;
  late List<Expense> _expenses;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut));
    _animationController.forward();

    _expenses = _db.getAllExpenses();
    if (_expenses.isEmpty) {
      _addSampleExpenses();
    }
  }

  Future<void> _addSampleExpenses() async {
    final now = DateTime.now();
    await _db.addExpense(Expense(amount: 25.50, category: 'Food', description: 'Lunch at cafe', date: now.subtract(const Duration(days: 1))));
    await _db.addExpense(Expense(amount: 150.00, category: 'Transport', description: 'Uber ride', date: now));
    await _db.addExpense(Expense(amount: 45.75, category: 'Shopping', description: 'Groceries', date: now.subtract(const Duration(hours: 2))));
    // Refresh UI
    setState(() => _expenses = _db.getAllExpenses());
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: CustomScrollView(
        slivers: [
           SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text('Dashboard'),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue, Colors.indigo],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SlideTransition(
              position: _slideAnimation,
              child: _buildSummarySection(),
            ),
          ),
          SliverToBoxAdapter(  
            child: _buildRecentTransactions(),
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection() {
    final total = _db.getTotalExpenses();
    final byCategory = _db.getExpensesByCategory();

  return Padding(
    padding: const EdgeInsets.all(16.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Quick Summary', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                title: 'Total Expenses',
                value: total,
                icon: Icons.trending_down,
                color: Colors.red,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildSummaryCard(
                title: 'Categories',
                value: byCategory.length,
                icon: Icons.pie_chart,
                color: Colors.green,
              ),
            ),
          ],
        ),
        if (byCategory.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text('Expenses by Category'),
          const SizedBox(height: 8),
          ...byCategory.entries.map((entry) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                SizedBox(
                  width: 100,
                  child: Text(
                    '${entry.key}:',  
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                    style: const TextStyle(fontWeight: FontWeight.w500),  
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        flex: (entry.value / total * 100).round().clamp(1, 50),
                        child: Container(
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '\$${entry.value.toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )),
        ],
      ],
    ),
  );
  }

  Widget _buildSummaryCard({
    required String title,
    required dynamic value,
    required IconData icon,
    required Color color,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          Text(
            value is double ? NumberFormat.currency(symbol: '\$').format(value) : value.toString(),
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTransactions() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Transactions',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () => _db.clearAll().then((_) => setState(() {
                  _expenses = _db.getAllExpenses();
                })),  // For demo
                child: const Text('Clear All'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_expenses.isEmpty)
            const Center(child: Text('No transactions yet. Add some!'))
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _expenses.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final expense = _expenses[index];
                return Dismissible(
                  key: Key(expense.key.toString()),
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  direction: DismissDirection.endToStart,
                  onDismissed: (_) => _deleteExpense(expense, index),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getCategoryColor(expense.category),
                      child: Text(expense.category[0]),
                    ),
                    title: Text(expense.description),
                    subtitle: Text('${expense.category} • ${expense.formattedDate}'),
                    trailing: Text(expense.formattedAmount, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  void _deleteExpense(Expense expense, int index) {
    _db.deleteExpense(expense.key.toString());
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Expense deleted!')),
    );
    setState(() {
      _expenses.removeAt(index);
    });  // Refresh
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Food': return Colors.orange;
      case 'Transport': return Colors.blue;
      case 'Shopping': return Colors.purple;
      default: return Colors.grey;
    }
  }
}