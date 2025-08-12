import 'package:flutter/material.dart';
import '../data/expense_service.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _dateController = TextEditingController();

  // ↓ Category now uses a dropdown
  final List<String> _categories = const [
    'Food',
    'Transport',
    'Groceries',
    'Bills',
    'Housing',
    'Shopping',
    'Health',
    'Entertainment',
    'Education',
    'Travel',
    'Debt',
    'Subscriptions',
    'Other',
  ];
  String? _selectedCategory;
  final _customCategoryCtrl = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _dateController.text = _selectedDate.toLocal().toString().split('.')[0];
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _dateController.dispose();
    _customCategoryCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDate),
    );

    setState(() {
      _selectedDate = DateTime(
        date.year, date.month, date.day, time?.hour ?? 0, time?.minute ?? 0,
      );
      _dateController.text = _selectedDate.toLocal().toString().split('.')[0];
    });
  }

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) return;

    // Resolve category (handles "Other")
    String? category = _selectedCategory;
    if (category == 'Other') {
      final custom = _customCategoryCtrl.text.trim();
      if (custom.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a custom category')),
        );
        return;
      }
      category = custom;
    }

    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await ExpensesService.instance.add(
        title: _titleController.text.trim(),
        amount: amount,
        category: category!, // safe after validation above
        date: _selectedDate,
      );
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final showCustom = _selectedCategory == 'Other';

    return Scaffold(
      appBar: AppBar(title: const Text('Add Expense')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Enter a title' : null,
              ),
              const SizedBox(height: 16),

              // ✅ Category dropdown
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                items: _categories
                    .map((c) => DropdownMenuItem<String>(
                          value: c,
                          child: Text(c),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _selectedCategory = v),
                decoration: const InputDecoration(
                  labelText: 'Category',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                validator: (v) => (v == null || v.isEmpty)
                    ? 'Choose a category'
                    : null,
              ),
              if (showCustom) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _customCategoryCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Custom category',
                    prefixIcon: Icon(Icons.edit_outlined),
                  ),
                ),
              ],

              const SizedBox(height: 16),
              TextFormField(
                controller: _dateController,
                readOnly: true,
                decoration: const InputDecoration(labelText: 'Date & Time'),
                onTap: _pickDateTime,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Amount'),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Enter an amount';
                  return double.tryParse(v.trim()) == null ? 'Enter a valid number' : null;
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _saveExpense,
                  child: _saving
                      ? const SizedBox(
                          height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Save Expense'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
