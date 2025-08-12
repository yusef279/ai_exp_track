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
}
