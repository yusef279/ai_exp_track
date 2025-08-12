import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/user_settings_service.dart';
import '../models/user_settings.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});
  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  final _currencies = const ['EGP', 'USD', 'EUR', 'SAR', 'AED', 'GBP'];

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? '';

    return SafeArea( // ✅ keep all content below the notch/status bar
      child: StreamBuilder<UserSettings>(
        stream: UserSettingsService.instance.stream(),
        builder: (context, snap) {
          final s = snap.data ??
              UserSettings(
                displayName: user?.displayName ?? '',
                currency: 'EGP',
                monthlyIncome: 0,
                monthlyBudget: 0,
              );

          final initial = (s.displayName.isNotEmpty
                  ? s.displayName[0]
                  : (email.isNotEmpty ? email[0] : '?'))
              .toUpperCase();

          return CustomScrollView(
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7B61FF), Color(0xFFA18AFF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.white,
                        child: Text(
                          initial,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF7B61FF),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.displayName.isEmpty
                                  ? 'Set your name'
                                  : s.displayName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              email,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Summary card
              SliverToBoxAdapter(
                child: Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 0.5,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        _kv('Currency', s.currency),
                        const Divider(height: 16),
                        _kv(
                            'Monthly income',
                            s.monthlyIncome == 0
                                ? '-'
                                : s.monthlyIncome.toStringAsFixed(0)),
                        const Divider(height: 16),
                        _kv(
                            'Monthly budget',
                            s.monthlyBudget == 0
                                ? '-'
                                : s.monthlyBudget.toStringAsFixed(0)),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _openEditSheet(context, s),
                            icon: const Icon(Icons.edit),
                            label: const Text('Edit profile'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Actions
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      TextButton.icon(
                        onPressed: () async {
                          final e =
                              FirebaseAuth.instance.currentUser?.email;
                          if (e == null) return;
                          await FirebaseAuth.instance
                              .sendPasswordResetEmail(email: e);
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content:
                                  Text('Password reset sent to $e'),
                            ),
                          );
                        },
                        icon: const Icon(Icons.lock_reset),
                        label: const Text('Reset password'),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () async {
                          await FirebaseAuth.instance.signOut();
                          if (!mounted) return;
                          Navigator.pushReplacementNamed(
                              context, '/login');
                        },
                        icon: const Icon(Icons.logout),
                        label: const Text('Sign out'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Edit sheet (unchanged)
  Future<void> _openEditSheet(
      BuildContext context, UserSettings current) async {
    final nameCtrl =
        TextEditingController(text: current.displayName);
    final incomeCtrl = TextEditingController(
        text: current.monthlyIncome == 0
            ? ''
            : current.monthlyIncome.toStringAsFixed(0));
    final budgetCtrl = TextEditingController(
        text: current.monthlyBudget == 0
            ? ''
            : current.monthlyBudget.toStringAsFixed(0));
    String currency = current.currency;
    final formKey = GlobalKey<FormState>();
    bool saving = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (_, __) => StatefulBuilder(
            builder: (context, setLocal) {
              Future<void> save() async {
                if (!formKey.currentState!.validate()) return;
                setLocal(() => saving = true);
                try {
                  await UserSettingsService.instance.save(UserSettings(
                    displayName: nameCtrl.text.trim(),
                    currency: currency,
                    monthlyIncome:
                        double.tryParse(incomeCtrl.text.trim()) ?? 0,
                    monthlyBudget:
                        double.tryParse(budgetCtrl.text.trim()) ?? 0,
                  ));
                  if (mounted) Navigator.pop(context);
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    const SnackBar(
                        content: Text('Profile updated ✅')),
                  );
                } catch (e) {
                  setLocal(() => saving = false);
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    SnackBar(content: Text('Failed to save: $e')),
                  );
                }
              }

              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 16)
                  ],
                ),
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 12,
                  bottom:
                      MediaQuery.of(context).viewInsets.bottom + 16,
                ),
                child: Form(
                  key: formKey,
                  child: Column(
                    children: [
                      Container(
                        width: 48,
                        height: 5,
                        margin:
                            const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius:
                              BorderRadius.circular(8),
                        ),
                      ),
                      const Text('Edit profile',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Display name',
                          prefixIcon:
                              Icon(Icons.person_outline),
                        ),
                        validator: (v) => v == null ||
                                v.trim().isEmpty
                            ? 'Enter a name'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: currency,
                        items: _currencies
                            .map((c) => DropdownMenuItem(
                                  value: c,
                                  child: Text(c),
                                ))
                            .toList(),
                        onChanged: (v) =>
                            setLocal(() => currency = v ?? currency),
                        decoration: const InputDecoration(
                          labelText: 'Currency',
                          prefixIcon:
                              Icon(Icons.attach_money),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: incomeCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Monthly net income',
                          prefixIcon:
                              Icon(Icons.payments_outlined),
                        ),
                        validator: (v) {
                          if (v == null ||
                              v.trim().isEmpty) return null;
                          return double.tryParse(v) == null
                              ? 'Enter a number'
                              : null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: budgetCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Monthly budget (optional)',
                          prefixIcon: Icon(Icons
                              .account_balance_wallet_outlined),
                        ),
                        validator: (v) {
                          if (v == null ||
                              v.trim().isEmpty) return null;
                          return double.tryParse(v) == null
                              ? 'Enter a number'
                              : null;
                        },
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: saving ? null : save,
                          child: saving
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child:
                                      CircularProgressIndicator(
                                          strokeWidth: 2),
                                )
                              : const Text('Save'),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _kv(String k, String v) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(k, style: const TextStyle(color: Colors.black54)),
          Text(v, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      );
}
