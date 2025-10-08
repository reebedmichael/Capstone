import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../shared/utils/admin_permissions.dart';

class UserManagementSummary extends ConsumerStatefulWidget {
  const UserManagementSummary({Key? key}) : super(key: key);

  @override
  ConsumerState<UserManagementSummary> createState() =>
      _UserManagementSummaryState();
}

class _UserManagementSummaryState extends ConsumerState<UserManagementSummary> {
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _users = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final sb = Supabase.instance.client;

      // Load users with related data
      final gebruikers = await sb
          .from('gebruikers')
          .select(
            '*, gebr_tipe:gebr_tipe_id(gebr_tipe_naam, gebr_toelaag), admin_tipe:admin_tipe_id(admin_tipe_naam), kampus:kampus_id(kampus_naam)',
          )
          .limit(100); // Limit for dashboard performance

      if (mounted) {
        setState(() {
          _users = List<Map<String, dynamic>>.from(gebruikers);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> _getRandomUsers() {
    if (_users.length <= 6) return _users;

    final random = Random();
    final shuffled = List<Map<String, dynamic>>.from(_users)..shuffle(random);
    return shuffled.take(6).toList();
  }

  Widget _summaryBox(String number, String label, Color base) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: base.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: base.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text(
              number,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: base,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: base.withOpacity(0.8)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Card(
        elevation: 1,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Laai gebruiker data...'),
              ],
            ),
          ),
        ),
      );
    }

    if (_error != null) {
      return Card(
        elevation: 1,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(
                'Fout met laai van gebruiker data',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                style: TextStyle(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadData,
                child: const Text('Probeer weer'),
              ),
            ],
          ),
        ),
      );
    }

    // Calculate statistics
    final totalAdmins = _users
        .where((u) => (u['admin_tipe']?['admin_tipe_naam'] ?? '') != '')
        .length;
    final students = _users
        .where((u) => (u['gebr_tipe']?['gebr_tipe_naam'] ?? '') == 'Student')
        .length;
    final personeel = _users
        .where((u) => (u['gebr_tipe']?['gebr_tipe_naam'] ?? '') == 'Personeel')
        .length;

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Gebruiker Bestuur Oorsig',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Gebruiker statistieke en beheer opsomming',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () => context.go('/gebruikers'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  child: const Text('Meer'),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Summary statistics
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _summaryBox('$totalAdmins', 'Totaal Admins', Colors.purple),
                _summaryBox('$students', 'Studente', Colors.teal),
                _summaryBox('$personeel', 'Personeel', Colors.orange),
              ],
            ),
            const SizedBox(height: 12),

            // Recent users section
            if (_users.isNotEmpty) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Onlangse Gebruikers',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 200, // Fixed height to enable scrolling
                child: SingleChildScrollView(
                  child: Column(
                    children: _getRandomUsers().map((user) {
                      final name =
                          '${user['gebr_naam'] ?? ''} ${user['gebr_van'] ?? ''}'
                              .trim();
                      final role =
                          user['gebr_tipe']?['gebr_tipe_naam'] ?? 'Onbekend';
                      final isActive = user['is_aktief'] == true;
                      final isPending = AdminPermissions.isPendingApproval(
                        user,
                      );

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Icon(
                                      isPending
                                          ? Icons.person_add
                                          : Icons.person,
                                      size: 18,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name.isEmpty ? '(Geen naam)' : name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      role,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: isPending
                                    ? Colors.amber.shade100
                                    : isActive
                                    ? Colors.green.shade100
                                    : Colors.red.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                isPending
                                    ? 'Wag'
                                    : isActive
                                    ? 'Aktief'
                                    : 'Nie aktief',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: isPending
                                      ? Colors.amber.shade800
                                      : isActive
                                      ? Colors.green.shade800
                                      : Colors.red.shade800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              if (_users.length > 6)
                TextButton(
                  onPressed: () => context.go('/gebruikers'),
                  child: Text('Bekyk ${_users.length - 6} meer gebruikers'),
                ),
            ] else ...[
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text('Geen gebruikers gevind nie'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
