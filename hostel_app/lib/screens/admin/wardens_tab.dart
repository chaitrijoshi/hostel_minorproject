import 'package:flutter/material.dart';
import '../../models.dart';
import '../../services/api_service.dart';

/// Admin-only: list every warden login (GET /api/wardens/) and create new
/// ones (POST /api/wardens/), each tied to a hostel. This is the only way
/// a warden account gets created.
class WardensTab extends StatefulWidget {
  const WardensTab({super.key});

  @override
  State<WardensTab> createState() => _WardensTabState();
}

class _WardensTabState extends State<WardensTab> {
  late Future<List<Warden>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Warden>> _load() async {
    final data = await ApiService.get('/api/wardens/');
    return (data as List).map((e) => Warden.fromJson(e)).toList();
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  Future<void> _addWarden() async {
    List<Hostel> hostels;
    try {
      final data = await ApiService.get('/api/hostels/');
      hostels = (data as List).map((e) => Hostel.fromJson(e)).toList();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
      return;
    }
    if (hostels.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Add a hostel first, from the Hostels tab.')),
        );
      }
      return;
    }

    final nameController = TextEditingController();
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    Hostel? selectedHostel = hostels.first;

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Warden'),
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
                  DropdownButtonFormField<Hostel>(
                    value: selectedHostel,
                    decoration: const InputDecoration(labelText: 'Hostel'),
                    items: hostels
                        .map((h) => DropdownMenuItem(value: h, child: Text(h.name)))
                        .toList(),
                    onChanged: (v) => setDialogState(() => selectedHostel = v),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate() || selectedHostel == null) return;
                try {
                  await ApiService.post('/api/wardens/', {
                    'full_name': nameController.text.trim(),
                    'username': usernameController.text.trim(),
                    'password': passwordController.text,
                    'hostel_id': selectedHostel!.id,
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
      ),
    );

    if (saved == true) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _addWarden,
        tooltip: 'Add warden',
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<Warden>>(
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
            final wardens = snapshot.data ?? [];
            if (wardens.isEmpty) {
              return ListView(children: const [
                SizedBox(height: 100),
                Center(child: Text('No wardens yet. Tap + to add one.')),
              ]);
            }
            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: wardens.length,
              itemBuilder: (context, index) {
                final w = wardens[index];
                return Card(
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.shield)),
                    title: Text(w.name.isNotEmpty ? w.name : w.username),
                    subtitle: Text('${w.hostelName} • @${w.username}'),
                    trailing: w.pendingFirstLogin
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
