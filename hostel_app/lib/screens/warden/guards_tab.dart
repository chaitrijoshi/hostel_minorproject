import 'package:flutter/material.dart';
import '../../models.dart';
import '../../services/api_service.dart';

/// Warden-only: list security guards in their own hostel (GET
/// /api/guards/, auto-scoped server-side) and create new ones.
class GuardsTab extends StatefulWidget {
  const GuardsTab({super.key});

  @override
  State<GuardsTab> createState() => _GuardsTabState();
}

class _GuardsTabState extends State<GuardsTab> {
  late Future<List<Guard>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Guard>> _load() async {
    final data = await ApiService.get('/api/guards/');
    return (data as List).map((e) => Guard.fromJson(e)).toList();
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  Future<void> _addGuard() async {
    final nameController = TextEditingController();
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();
    final shiftController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Security Guard'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Full name'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                TextFormField(
                  controller: usernameController,
                  decoration: const InputDecoration(labelText: 'Temporary username'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                TextFormField(
                  controller: passwordController,
                  decoration: const InputDecoration(labelText: 'Temporary password'),
                  validator: (v) => (v == null || v.length < 6) ? 'At least 6 characters' : null,
                ),
                TextFormField(
                  controller: shiftController,
                  decoration: const InputDecoration(labelText: 'Shift time (e.g. 8 AM - 4 PM)'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              try {
                await ApiService.post('/api/guards/', {
                  'full_name': nameController.text.trim(),
                  'username': usernameController.text.trim(),
                  'password': passwordController.text,
                  'shift_time': shiftController.text.trim(),
                });
                if (context.mounted) Navigator.pop(context, true);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (saved == true) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _addGuard,
        tooltip: 'Add guard',
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<Guard>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return ListView(children: [
                const SizedBox(height: 80),
                Icon(Icons.error_outline, size: 48, color: Colors.grey.shade400),
                const SizedBox(height: 8),
                Center(child: Text(snapshot.error.toString(), textAlign: TextAlign.center)),
              ]);
            }
            final guards = snapshot.data ?? [];
            if (guards.isEmpty) {
              return ListView(children: const [
                SizedBox(height: 100),
                Center(child: Text('No guards yet. Tap + to add one.')),
              ]);
            }
            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: guards.length,
              itemBuilder: (context, index) {
                final g = guards[index];
                return Card(
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.shield)),
                    title: Text(g.name.isNotEmpty ? g.name : g.username),
                    subtitle: Text('${g.shiftTime}\n@${g.username}'),
                    isThreeLine: true,
                    trailing: g.pendingFirstLogin
                        ? const Chip(label: Text('Not activated'), backgroundColor: Color(0xFFFFF3CD))
                        : const Chip(label: Text('Active'), backgroundColor: Color(0xFFD4EDDA)),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
