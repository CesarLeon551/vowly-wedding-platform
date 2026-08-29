import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';

import '../../data/firebase/firestore_refs.dart';
import '../../domain/entities/dashboard_stats.dart';
import '../../domain/repositories/dashboard_repository.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  DashboardRepositoryImpl(this._db);

  final FirebaseFirestore _db;

  double _sumField(QuerySnapshot<Map<String, dynamic>> snap, String field) {
    return snap.docs.fold<double>(
      0,
      (sum, doc) => sum + ((doc.data()[field] as num?)?.toDouble() ?? 0),
    );
  }

  int _countWhere(
    QuerySnapshot<Map<String, dynamic>> snap,
    String field,
    String value,
  ) {
    return snap.docs.where((d) => d.data()[field] == value).length;
  }

  @override
  Stream<DashboardStats> watchStats(String weddingId) {
    final refs = FirestoreRefs(_db, weddingId);

    return Rx.combineLatest7(
      refs.wedding.snapshots(),
      refs.budgetCategories.snapshots(),
      refs.expenses.snapshots(),
      refs.savingsEntries().snapshots(),
      refs.guests.snapshots(),
      refs.tasks.snapshots(),
      refs.vendors.snapshots(),
      (
        DocumentSnapshot<Map<String, dynamic>> weddingSnap,
        QuerySnapshot<Map<String, dynamic>> budgetSnap,
        QuerySnapshot<Map<String, dynamic>> expensesSnap,
        QuerySnapshot<Map<String, dynamic>> savingsSnap,
        QuerySnapshot<Map<String, dynamic>> guestsSnap,
        QuerySnapshot<Map<String, dynamic>> tasksSnap,
        QuerySnapshot<Map<String, dynamic>> vendorsSnap,
      ) {
        final weddingData = weddingSnap.data();
        final weddingDate = (weddingData?['date'] as Timestamp?)?.toDate();
        final daysRemaining = weddingDate == null
            ? 0
            : weddingDate.difference(DateTime.now()).inDays;

        final now = DateTime.now();
        final upcoming = tasksSnap.docs
            .where((d) {
              final due = (d.data()['dueDate'] as Timestamp?)?.toDate();
              if (due == null) return false;
              final daysUntil = due.difference(now).inDays;
              return daysUntil >= 0 && daysUntil <= 14;
            })
            .map((d) => UpcomingTask(
                  name: d.data()['name'] as String? ?? 'Sin nombre',
                  dueDate: (d.data()['dueDate'] as Timestamp).toDate(),
                ))
            .toList()
          ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

        return DashboardStats(
          daysRemaining: daysRemaining,
          plannedBudget: _sumField(budgetSnap, 'plannedAmount'),
          spent: _sumField(expensesSnap, 'amount'),
          saved: _sumField(savingsSnap, 'amount'),
          totalGuests: guestsSnap.docs.length,
          confirmedGuests: _countWhere(guestsSnap, 'rsvpStatus', 'confirmado'),
          pendingGuests: _countWhere(guestsSnap, 'rsvpStatus', 'pendiente'),
          notAttendingGuests: _countWhere(guestsSnap, 'rsvpStatus', 'no_asistira'),
          tasksCompleted: _countWhere(tasksSnap, 'status', 'completada'),
          tasksPending: tasksSnap.docs.length - _countWhere(tasksSnap, 'status', 'completada'),
          vendorsHired: _countWhere(vendorsSnap, 'status', 'contratado'),
          upcomingTasks: upcoming,
        );
      },
    );
  }
}
