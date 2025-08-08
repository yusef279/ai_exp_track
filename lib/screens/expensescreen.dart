import 'package:flutter/material.dart';
import '../data/expense_repository.dart';

class ExpenseScreen extends StatelessWidget {
  const ExpenseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final expenses = ExpenseRepository.instance.expenses;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expenses'),
      ),
      body: expenses.isEmpty
          ? const Center(child: Text('No expenses yet'))
          : ListView.separated(
              itemBuilder: (context, index) {
                final expense = expenses[index];
                return ListTile(
                  title: Text(expense.title),
                  subtitle: Text(
                      '${expense.category} - \$${expense.amount.toStringAsFixed(2)} - ${expense.date.toLocal().toString().split('.')[0]}'),
                );
              },
              separatorBuilder: (_, __) => const Divider(height: 0),
              itemCount: expenses.length,
            ),
    );
  }
}
