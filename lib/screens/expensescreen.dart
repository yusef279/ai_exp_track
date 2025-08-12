import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import '../data/expense_service.dart';
import '../models/expense.dart';
import '../data/user_settings_service.dart';
import '../models/user_settings.dart';
import '../utils/currency_format.dart';

class ExpenseScreen extends StatefulWidget {
  const ExpenseScreen({super.key});
  @override
  State<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen> {
  DateTime _month = DateTime.now();
  final _categories = const [
    'Food','Transport','Groceries','Bills','Housing','Shopping',
    'Health','Entertainment','Education','Travel','Debt','Subscriptions','Other'
  ];

  void _pickMonth() async {
    final now = DateTime.now();
    // simple month picker via date picker (ignores day)
    final d = await showDatePicker(
      context: context,
      initialDate: _month,
      firstDate: DateTime(now.year - 3, 1),
      lastDate: DateTime(now.year + 1, 12),
      helpText: 'Select any day in target month',
    );
    if (d != null) setState(() => _month = DateTime(d.year, d.month, 1));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: StreamBuilder<UserSettings>(
        stream: UserSettingsService.instance.stream(),
        builder: (context, settingsSnap) {
          final s = settingsSnap.data ??
              UserSettings(displayName: '', currency: 'EGP', monthlyIncome: 0, monthlyBudget: 0);
          final fmt = CurrencyFmt(s.currency);

          return Column(
            children: [
              // Header row with month picker and total
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
                child: Row(
                  children: [
                    Text(
                      '${_month.year}-${_month.month.toString().padLeft(2, '0')}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: _pickMonth,
                      icon: const Icon(Icons.calendar_today, size: 16),
                      label: const Text('Change'),
                    ),
                    const Spacer(),
                    StreamBuilder<double>(
                      stream: ExpensesService.instance.streamMonthTotal(_month),
                      builder: (context, totalSnap) {
                        final total = totalSnap.data ?? 0.0;
                        return Text(
                          fmt.money(total),
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                        );
                      },
                    ),
                  ],
                ),
              ),

              // Budget alert (>= 80%)
              StreamBuilder<double>(
                stream: ExpensesService.instance.streamMonthTotal(_month),
                builder: (context, totalSnap) {
                  final total = totalSnap.data ?? 0.0;
                  final budget = s.monthlyBudget;
                  final warn = budget > 0 && total >= 0.8 * budget;
                  if (!warn) return const SizedBox.shrink();
                  final percent = (total / budget * 100).clamp(0, 999).toStringAsFixed(0);
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text('Budget warning • $percent% of monthly budget reached'),
                        ),
                      ],
                    ),
                  );
                },
              ),

              // Category breakdown pie
              SizedBox(
                height: 180,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: StreamBuilder<Map<String, double>>(
                    stream: ExpensesService.instance.streamCategoryTotals(_month),
                    builder: (context, snap) {
                      final data = snap.data ?? {};
                      if (data.isEmpty) {
                        return const Center(child: Text('No data for chart'));
                      }
                      final total = data.values.fold<double>(0, (a, b) => a + b);
                      final sections = <PieChartSectionData>[];
                      var idx = 0;
                      data.forEach((k, v) {
                        final pct = (v / total * 100);
                        sections.add(
                          PieChartSectionData(
                            value: v,
                            title: pct >= 8 ? '${k}\n${pct.toStringAsFixed(0)}%' : '',
                            radius: 60,
                            titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        );
                        idx++;
                      });
                      return PieChart(
                        PieChartData(
                          sections: sections,
                          sectionsSpace: 2,
                          centerSpaceRadius: 28,
                        ),
                      );
                    },
                  ),
                ),
              ),

              const Divider(height: 12),

              // List
              Expanded(
                child: StreamBuilder<List<Expense>>(
                  stream: ExpensesService.instance.streamForMonth(_month, newestFirst: true),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final items = snap.data ?? [];
                    if (items.isEmpty) {
                      return const Center(child: Text('No expenses yet'));
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final e = items[i];
                        final when = e.date.toLocal().toString().split('.').first;

                        return Dismissible(
                          key: ValueKey(e.id),
                          background: _swipeBg(Colors.red, Icons.delete, 'Delete'),
                          secondaryBackground: _swipeBg(Colors.indigo, Icons.edit, 'Edit', alignEnd: true),
                          confirmDismiss: (dir) async {
                            if (dir == DismissDirection.startToEnd) {
                              // delete
                              await ExpensesService.instance.delete(e.id);
                              return true;
                            } else {
                              // edit
                              _openEdit(context, e);
                              return false;
                            }
                          },
                          child: ListTile(
                            leading: CircleAvatar(
                              child: Text((e.category.isNotEmpty ? e.category[0] : '?').toUpperCase()),
                            ),
                            title: Text(e.title),
                            subtitle: Text('${e.category} • $when'),
                            trailing: Text(fmt.money(e.amount),
                                style: const TextStyle(fontWeight: FontWeight.w600)),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              // Smart local tip
              StreamBuilder<Map<String, double>>(
                stream: ExpensesService.instance.streamCategoryTotals(_month),
                builder: (context, snap) {
                  final m = snap.data ?? {};
                  if (m.isEmpty) return const SizedBox.shrink();
                  final total = m.values.fold<double>(0, (a, b) => a + b);
                  if (total <= 0) return const SizedBox.shrink();

                  // find largest category
                  String top = m.keys.first;
                  double topVal = m[top]!;
                  m.forEach((k, v) { if (v > topVal) { top = k; topVal = v; }});
                  final save10 = topVal * 0.10;

                  return Container(
                    margin: const EdgeInsets.fromLTRB(12, 6, 12, 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.lightbulb_outline, color: Colors.green),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Tip: If you trim $top by 10%, you could save ~ ${CurrencyFmt((UserSettingsService.instance.latestCurrency ?? "EGP")).money(save10)} next month.',
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _swipeBg(Color c, IconData icon, String label, {bool alignEnd = false}) {
    return Container(
      color: c.withOpacity(.15),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: alignEnd ? Alignment.centerRight : Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: c),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: c, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Future<void> _openEdit(BuildContext context, Expense e) async {
    final title = TextEditingController(text: e.title);
    final amount = TextEditingController(text: e.amount.toStringAsFixed(2));
    String category = e.category;
    DateTime date = e.date;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16, right: 16,
            top: 12,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Edit expense', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              TextField(controller: title, decoration: const InputDecoration(labelText: 'Title')),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _categories.contains(category) ? category : 'Other',
                items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => category = (v == 'Other') ? category : (v ?? category),
                decoration: const InputDecoration(labelText: 'Category'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: amount,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Amount'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () async {
                      final d = await showDatePicker(
                        context: ctx,
                        initialDate: date, firstDate: DateTime(2000), lastDate: DateTime(2100));
                      if (d == null) return;
                      final t = await showTimePicker(
                        context: ctx, initialTime: TimeOfDay.fromDateTime(date));
                      date = DateTime(d.year, d.month, d.day, t?.hour ?? 0, t?.minute ?? 0);
                      setState(() {}); // not strictly needed; list updates via stream
                    },
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: const Text('Change date'),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: () async {
                      final amt = double.tryParse(amount.text.trim());
                      if (amt == null) return;
                      await ExpensesService.instance.updateExpense(
                        e.id, title: title.text.trim(), category: category, amount: amt, date: date);
                      if (context.mounted) Navigator.pop(ctx);
                    },
                    child: const Text('Save'),
                  ),
                ],
              )
            ],
          ),
        );
      },
    );
  }
}
