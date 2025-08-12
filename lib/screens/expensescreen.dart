import 'package:ai_exp_track/data/expense_service.dart';
import 'package:flutter/material.dart';
import '../data/expense_service.dart';
import '../models/expense.dart';

class ExpenseScreen extends StatelessWidget {
  const ExpenseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: StreamBuilder<List<Expense>>(
        // Service uses the signed-in user internally
        stream: ExpensesService.instance.streamAll(newestFirst: true),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snap.data ?? [];
          if (items.isEmpty) {
            return const Center(child: Text('No expenses yet'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final e = items[i];
              final when = e.date.toLocal().toString().split('.').first;
              return ListTile(
                leading: CircleAvatar(
                  child: Text(
                    (e.category.isNotEmpty ? e.category[0] : '?').toUpperCase(),
                  ),
                ),
                title: Text(e.title),
                subtitle: Text('${e.category} • $when'),
                trailing: Text('\$${e.amount.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                onLongPress: () => ExpensesService.instance.delete(e.id),
              );
            },
          );
        },
      ),
    );
  }
}