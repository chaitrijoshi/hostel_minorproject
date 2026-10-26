import 'package:flutter/material.dart';
import '../../models.dart';
import '../../services/api_service.dart';

/// Warden-only: list students in their own hostel (GET /api/students/,
/// auto-scoped server-side) and create new ones (POST /api/students/,
/// the hostel is assigned automatically to the warden's own hostel).
class StudentsTab extends StatefulWidget {
  const StudentsTab({super.key});

  @override
  State<StudentsTab> createState() => _StudentsTabState();
}

class _StudentsTabState extends State<StudentsTab> {
  late Future<List<Student>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Student>> _load() async {
    final data = await ApiService.get('/api/students/');
    return (data as List).map((e) => Student.fromJson(e)).toList();
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  Future<void> _addStudent() async {
    final nameController = TextEditingController();
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();
    final enrollmentController = TextEditingController();
    final roomController = TextEditingController();
    final phoneController = TextEditingController();
    final parentController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Student'),
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
                  controller: enrollmentController,
                  decoration: const InputDecoration(labelText: 'Enrollment number'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                TextFormField(
                  controller: roomController,
                  decoration: const InputDecoration(labelText: 'Room number'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                TextFormField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: 'Phone (optional)'),
                  keyboardType: TextInputType.phone,
                ),
                TextFormField(
                  controller: parentController,
                  decoration: const InputDecoration(labelText: "Parent contact (optional)"),
                  keyboardType: TextInputType.phone,
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
                await ApiService.post('/api/students/', {
                  'full_name': nameController.text.trim(),
                  'username': usernameController.text.trim(),
                  'password': passwordController.text,
                  'enrollment_no': enrollmentController.text.trim(),
                  'room_no': roomController.text.trim(),
                  'phone': phoneController.text.trim(),
                  'parent_contact': parentController.text.trim(),
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
        onPressed: _addStudent,
        tooltip: 'Add student',
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<Student>>(
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
            final students = snapshot.data ?? [];
            if (students.isEmpty) {
              return ListView(children: const [
                SizedBox(height: 100),
                Center(child: Text('No students yet. Tap + to add one.')),
              ]);
            }
            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: students.length,
              itemBuilder: (context, index) {
                final s = students[index];
                return Card(
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.school)),
                    title: Text(s.name.isNotEmpty ? s.name : s.username),
                    subtitle: Text('Room ${s.roomNo} • ${s.enrollmentNo}\n@${s.username}'),
                    isThreeLine: true,
                    trailing: s.pendingFirstLogin
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
