import 'package:flutter/material.dart';
import '../models.dart';
import '../services/api_service.dart';
import '../utils.dart';

/// Reusable read-only list of GET /api/visitors/, scoped per role by the
/// backend. Pass allowMarkExit: true (guard dashboard only) to show a
/// "Mark Exit" button on visitors who are still checked in.
class VisitorListWidget extends StatefulWidget {
  final bool allowMarkExit;
  const VisitorListWidget({super.key, this.allowMarkExit = false});

  @override
  State<VisitorListWidget> createState() => VisitorListWidgetState();
}

class VisitorListWidgetState extends State<VisitorListWidget> {
  late Future<List<VisitorLog>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<VisitorLog>> _load() async {
    final data = await ApiService.get('/api/visitors/');
    return (data as List).map((e) => VisitorLog.fromJson(e)).toList();
  }

  Future<void> refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  Future<void> _markExit(int id) async {
    try {
      await ApiService.post('/api/visitors/$id/mark_exit/', {});
      refresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: refresh,
      child: FutureBuilder<List<VisitorLog>>(
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
          final visitors = snapshot.data ?? [];
          if (visitors.isEmpty) {
            return ListView(children: const [
              SizedBox(height: 100),
              Center(child: Text('No visitor records yet.')),
            ]);
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: visitors.length,
            itemBuilder: (context, index) {
              final v = visitors[index];
              final isIn = v.status == 'IN';
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isIn ? const Color(0xFFFFF3CD) : const Color(0xFFE2E3E5),
                    child: const Icon(Icons.person_outline),
                  ),
                  title: Text('${v.name} (${v.phone})'),
                  subtitle: Text(
                    'Visiting ${v.studentName}'
                    '${v.purpose.isNotEmpty ? " • ${v.purpose}" : ""}'
                    '\nIn: ${formatDateTime(v.entryTime)}   Out: ${formatDateTime(v.exitTime)}',
                  ),
                  isThreeLine: true,
                  trailing: (widget.allowMarkExit && isIn)
                      ? TextButton(
                          onPressed: () => _markExit(v.id),
                          child: const Text('Mark Exit'),
                        )
                      : null,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
