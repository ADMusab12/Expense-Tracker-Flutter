import 'package:expense_tracker/abstraction/models/daily_expense.dart';
import 'package:expense_tracker/abstraction/models/expense.dart';
import 'package:expense_tracker/main.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> with TickerProviderStateMixin<ReportsScreen>{
 bool _isLoading = true;
  Map<String, double> _expensesByCategory = {};
  List<DailyExpense> _dailyExpenses = [];  
  final DateTime _startDate = DateTime(1900); 
  final DateTime _endDate = DateTime.now();
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState(){
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );
    _loadData();
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try{
      setState(() => _isLoading = true);
      final allExpenses = databaseService.getAllExpenses()
          .where((e) => e.date.isAfter(_startDate.subtract(const Duration(days: 1))) && e.date.isBefore(_endDate.add(const Duration(days: 1))))
          .toList();
      final byCategory = _getExpensesByCategory(allExpenses);
      final daily = _groupByDay(allExpenses);  
      if (mounted) {
        setState(() {
          _expensesByCategory = byCategory;
          _dailyExpenses = daily; 
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading reports: $e'), backgroundColor: Colors.red),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Map<String, double> _getExpensesByCategory(List<Expense> expenses) {
    final Map<String, double> byCategory = {};
    for (final expense in expenses) {
      byCategory[expense.category] = (byCategory[expense.category] ?? 0) + expense.amount;
    }
    return byCategory;
  }

  List<DailyExpense> _groupByDay(List<Expense> expenses){  
    final Map<String, double> dailyTotals = {};
    final Map<String, DateTime> dayDates = {};
    for (final expense in expenses) {
      final dayKey = DateFormat('MMM dd').format(expense.date);  
      dailyTotals[dayKey] = (dailyTotals[dayKey] ?? 0) + expense.amount;
      if (!dayDates.containsKey(dayKey)) {
        dayDates[dayKey] = DateTime(expense.date.year, expense.date.month, expense.date.day);
      }
    }
    final sortedEntries = dailyTotals.entries.toList()
      ..sort((a, b) => dayDates[a.key]!.compareTo(dayDates[b.key]!)); 

    return sortedEntries
        .map((e) => DailyExpense(day: e.key, amount: e.value)) 
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        elevation: 0,

      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : FadeTransition(
              opacity: _fadeAnimation,
              child: RefreshIndicator(
                onRefresh: _loadData,
                child: CustomScrollView(
                  slivers: [
                    SliverAppBar(
                      expandedHeight: 100,
                      floating: false,
                      pinned: true,
                      flexibleSpace: FlexibleSpaceBar(
                        title: Text(DateFormat('MMM dd, yyyy').format(DateTime.now())),
                        background: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.blue, Colors.indigo],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (_expensesByCategory.isEmpty)
                      SliverFillRemaining(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.analytics_outlined, size: 64, color: Colors.grey),
                              const SizedBox(height: 16),
                              const Text('No expenses yet. Add some to see reports!', style: TextStyle(fontSize: 18)),
                            ],
                          ),
                        ),
                      )
                    else ...[
                      SliverToBoxAdapter(
                        child: _buildCategoryPieChart(),
                      ),
                      SliverToBoxAdapter(
                        child: _buildDailyLineChart(),  
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildCategoryPieChart() {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Expenses by Category', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: _expensesByCategory.entries.map((entry) {
                    return PieChartSectionData(
                      color: _getCategoryColor(entry.key),
                      value: entry.value,
                      title: '${entry.key}\n\$${entry.value.toStringAsFixed(0)}',
                      radius: 60,
                      titleStyle: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
                    );
                  }).toList(),
                  borderData: FlBorderData(show: false),
                  sectionsSpace: 2,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: _expensesByCategory.entries.map((entry) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: _getCategoryColor(entry.key),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text('${entry.key}: \$${entry.value.toStringAsFixed(0)}'),
                ],
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyLineChart() { 
    if (_dailyExpenses.isEmpty) return const SizedBox.shrink();

    final numPoints = _dailyExpenses.length;
    if (numPoints < 2) {
      return Card(
        margin: const EdgeInsets.all(16),
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text('Daily Trends', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),  
              const SizedBox(height: 16),
              Text('Need at least 2 days of data to show trends. ${_dailyExpenses.length} day available.'),
            ],
          ),
        ),
      );
    }

    final labelStep = (numPoints > 10) ? (numPoints / 5).round() : 1;

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Daily Trends', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),  
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  minX: 0,
                  maxX: (numPoints - 1).toDouble(),
                  gridData: const FlGridData(show: true),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: labelStep.toDouble(), 
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index % labelStep == 0 && index >= 0 && index < _dailyExpenses.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                _dailyExpenses[index].day,
                                style: const TextStyle(fontSize: 10),
                              ),
                            );
                          }
                          return const Text(''); 
                        },
                        reservedSize: 40,
                      ),
                    ),
                    leftTitles: AxisTitles(  
                      sideTitles: SideTitles(
                        showTitles: false, 
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _dailyExpenses.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.amount)).toList(),
                      isCurved: true,
                      color: Colors.indigo,
                      barWidth: 3,
                      belowBarData: BarAreaData(show: false),
                      dotData: const FlDotData(show: true),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Food': return Colors.orange;
      case 'Transport': return Colors.blue;
      case 'Shopping': return Colors.purple;
      case 'Entertainment': return Colors.green;
      case 'Bills': return Colors.red;
      case 'Other': return Colors.grey;
      default: return Colors.grey;
    }
  }
}