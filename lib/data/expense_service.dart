import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/expense.dart';

class ExpensesService {
  ExpensesService._();
  static final ExpensesService instance = ExpensesService._();

  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String get _uid {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw StateError('Not signed in');
    return uid;
  }

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('expenses'); // top-level; filtered by userId

  /// ✅ Create a new expense using plain fields (no model/id needed)
  Future<String> add({
    required String title,
    required double amount,
    required String category,
    DateTime? date,
  }) async {
    final doc = await _col.add({
      'userId': _uid,
      'title': title,
      'category': category,
      'amount': amount,
      'date': date != null ? Timestamp.fromDate(date) : FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  Future<void> delete(String id) => _col.doc(id).delete();

  Future<void> update(String id, Map<String, dynamic> patch) =>
      _col.doc(id).update(patch);

  /// Live list (only current user)
  Stream<List<Expense>> streamAll({bool newestFirst = true}) {
    return _col
        .where('userId', isEqualTo: _uid)
        .orderBy('date', descending: newestFirst)
        .snapshots()
        .map((snap) => snap.docs
            .where((d) => d.data()['date'] != null)
            .map((d) => Expense.fromMap(d.id, d.data()))
            .toList());
  }

  /// Live total (only current user)
  Stream<double> streamTotal() {
    return _col
        .where('userId', isEqualTo: _uid)
        .snapshots()
        .map((snap) {
      double sum = 0;
      for (final d in snap.docs) {
        final data = d.data();
        final num amt = (data['amount'] ?? 0) as num;
        sum += amt.toDouble();
      }
      return sum;
    });
  }

// Month range
DateTime _firstDayOfMonth(DateTime d) => DateTime(d.year, d.month, 1);
DateTime _firstDayOfNextMonth(DateTime d) =>
    (d.month == 12) ? DateTime(d.year + 1, 1, 1) : DateTime(d.year, d.month + 1, 1);

// Stream expenses for a month
Stream<List<Expense>> streamForMonth(DateTime month, {bool newestFirst = true}) {
  final start = _firstDayOfMonth(month);
  final end = _firstDayOfNextMonth(month);
  return _col
      .where('userId', isEqualTo: _uid)
      .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
      .where('date', isLessThan: Timestamp.fromDate(end))
      .orderBy('date', descending: newestFirst)
      .snapshots()
      .map((s) => s.docs
          .where((d) => d.data()['date'] != null)
          .map((d) => Expense.fromMap(d.id, d.data()))
          .toList());
}

// Total for a month
Stream<double> streamMonthTotal(DateTime month) {
  return streamForMonth(month).map((list) =>
      list.fold<double>(0, (sum, e) => sum + e.amount));
}

// Category totals for a month
Stream<Map<String, double>> streamCategoryTotals(DateTime month) {
  return streamForMonth(month).map((list) {
    final map = <String, double>{};
    for (final e in list) {
      map[e.category] = (map[e.category] ?? 0) + e.amount;
    }
    return map;
  });
}

// Update helper (for quick edit)
Future<void> updateExpense(String id, {
  String? title,
  String? category,
  double? amount,
  DateTime? date,
}) {
  final patch = <String, dynamic>{};
  if (title != null) patch['title'] = title;
  if (category != null) patch['category'] = category;
  if (amount != null) patch['amount'] = amount;
  if (date != null) patch['date'] = Timestamp.fromDate(date);
  return _col.doc(id).update(patch);
}

}
