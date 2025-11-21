
import 'package:expense_tracker/abstraction/models/expense.dart';
import 'package:hive_flutter/hive_flutter.dart';

class DatabaseService {
  static const String _boxName = 'expenses';
  late final Box<Expense> _box;

  Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(ExpenseAdapter());
    _box = await Hive.openBox<Expense>(_boxName);
  }

  // Add expense
  Future<void> addExpense(Expense expense) async {
    await _box.add(expense);
  }

  // Get all expenses
  List<Expense> getAllExpenses() => _box.values.toList();

  // Get recent expenses (last 5)
  List<Expense> getRecentExpenses({int limit = 5}) {
    final all = getAllExpenses();
    all.sort((a, b) => b.date.compareTo(a.date));  // Newest first
    return all.take(limit).toList();
  }

  // Get recent expenses (last 5)
  Map<String, double> getExpensesByCategory(){
    final expenses = getAllExpenses();
    return <String, double>{
      for(final expense in expenses) expense.category: (expenses
      .where((e) => e.category == expense.category)
      .fold(0.0, (sum,e) => sum + e.amount))
      .toDouble(),
    };
  }  

  // Calculate total expenses (added for completeness)
  double getTotalExpenses() {
    return getAllExpenses().fold(0.0, (sum, expense) => sum + expense.amount);
  }

  // Delete expense
  Future<void> deleteExpense(String key) async {
    await _box.delete(key);
  }

  // Clear all
  Future<void> clearAll() async {
    await _box.clear();
  }
}