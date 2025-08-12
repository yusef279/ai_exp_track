import 'package:cloud_firestore/cloud_firestore.dart';

class Expense {
  final String id;            // Firestore doc id
  final String title;
  final double amount;
  final String category;
  final DateTime date;

  Expense({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
  });

  Map<String, dynamic> toMap() => {
        'title': title,
        'amount': amount,
        'category': category,
        'date': date, // store as Timestamp automatically
      };

  factory Expense.fromMap(String id, Map<String, dynamic> map) => Expense(
        id: id,
        title: map['title'] as String,
        amount: (map['amount'] as num).toDouble(),
        category: map['category'] as String,
        date: (map['date'] as Timestamp).toDate(),
      );
}
