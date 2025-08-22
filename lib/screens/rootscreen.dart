import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'addexpensescreen.dart';
import 'chatbotscreen.dart';
import 'expensescreen.dart';
import 'profilescreen.dart';

import '../data/expense_service.dart';
import '../data/user_settings_service.dart';
import '../models/user_settings.dart';
import '../utils/currency_format.dart';
import 'package:fl_chart/fl_chart.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class WelcomeNameText extends StatelessWidget {
  const WelcomeNameText({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .snapshots(), // <-- realtime
      builder: (context, snap) {
        // Fallbacks while loading / if no name yet
        final fallback = FirebaseAuth.instance.currentUser?.email ?? 'User';

        if (snap.connectionState == ConnectionState.waiting) {
          return Text(
            'Welcome...',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          );
        }

        final data = snap.data?.data();
        final name = (data?['displayName'] as String?)?.trim();
        final display = (name != null && name.isNotEmpty) ? name : fallback;

        return Text(
          'Welcome, $display',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          overflow: TextOverflow.ellipsis,
        );
      },
    );
  }
}


class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  int _index = 0;

  void _onTap(int i) => setState(() => _index = i);

  @override
  Widget build(BuildContext context) {
    final pages = [
      const _DashboardTab(),
      const ChatScreen(),
      const ExpenseScreen(),
      const ProfileTab(),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: pages),

      // ✅ Frosted-glass, rounded, floating NavigationBar
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 222, 205, 254).withOpacity(0.65),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 12,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: NavigationBar(
                  height: 65,
                  backgroundColor: Colors.transparent,
                  selectedIndex: _index,
                  onDestinationSelected: _onTap,
                  labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                  indicatorColor: const Color(0xFF7B61FF).withOpacity(0.18),
                  destinations: const [
                    NavigationDestination(
                      icon: Icon(Icons.dashboard_outlined),
                      selectedIcon: Icon(Icons.dashboard_rounded, color: Color(0xFF7B61FF)),
                      label: 'Home',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.chat_outlined),
                      selectedIcon: Icon(Icons.chat_rounded, color: Color(0xFF7B61FF)),
                      label: 'Chat',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.list_alt_outlined),
                      selectedIcon: Icon(Icons.list_alt_rounded, color: Color(0xFF7B61FF)),
                      label: 'Expenses',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.person_outline),
                      selectedIcon: Icon(Icons.person_rounded, color: Color(0xFF7B61FF)),
                      label: 'Profile',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashboardTab extends StatefulWidget {
  const _DashboardTab();

  @override
  State<_DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<_DashboardTab> {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? 'User';

    // We'll display THIS month's stats
    final DateTime monthStart = DateTime(DateTime.now().year, DateTime.now().month, 1);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row with title + logout
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Dashboard',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                    if (!context.mounted) return;
                    Navigator.pushReplacementNamed(context, '/login');
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ✅ This month total + mini category pie, formatted by user currency
            StreamBuilder<UserSettings>(
              stream: UserSettingsService.instance.stream(),
              builder: (context, settingsSnap) {
                final s = settingsSnap.data ??
                    UserSettings(
                      displayName: '',
                      currency: 'EGP',
                      monthlyIncome: 0,
                      monthlyBudget: 0,
                    );
                final fmt = CurrencyFmt(s.currency);

                return Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header row: Welcome + this month total
                        Row(
                          children: [
                            Expanded(child: WelcomeNameText()),
                            StreamBuilder<double>(
                              stream: ExpensesService.instance.streamMonthTotal(monthStart),
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
                        const SizedBox(height: 4),
                        Text('This month', style: TextStyle(color: Colors.grey.shade600)),
                        const SizedBox(height: 12),

                        // Mini category pie
                        SizedBox(
                          height: 140,
                          child: StreamBuilder<Map<String, double>>(
                            stream: ExpensesService.instance.streamCategoryTotals(monthStart),
                            builder: (context, snap) {
                              final data = snap.data ?? {};
                              if (data.isEmpty) {
                                return const Center(child: Text('No spending yet'));
                              }
                              final total = data.values.fold<double>(0, (a, b) => a + b);
                              final sections = <PieChartSectionData>[];
                              data.forEach((k, v) {
                                final pct = total == 0 ? 0 : (v / total * 100);
                                sections.add(
                                  PieChartSectionData(
                                    value: v,
                                    radius: 42,
                                    title: pct >= 12 ? '$k\n${pct.toStringAsFixed(0)}%' : '',
                                    titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                                  ),
                                );
                              });
                              return PieChart(
                                PieChartData(
                                  sections: sections,
                                  sectionsSpace: 2,
                                  centerSpaceRadius: 24,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddExpenseScreen(),
                    ),
                  );
                  // No manual refresh needed; streams update UI automatically
                },
                icon: const Icon(Icons.add),
                label: const Text('Add Expense'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: const Color(0xFF7B61FF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
