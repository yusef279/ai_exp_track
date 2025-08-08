import '../models/expense.dart';

class ExpenseRepository {
  ExpenseRepository._();

  static final ExpenseRepository instance = ExpenseRepository._();

  final List<Expense> _expenses = [];

  List<Expense> get expenses => List.unmodifiable(_expenses);

  double get total =>
      _expenses.fold(0, (previousValue, element) => previousValue + element.amount);

  void addExpense(Expense expense) {
    _expenses.add(expense);
  }
}
