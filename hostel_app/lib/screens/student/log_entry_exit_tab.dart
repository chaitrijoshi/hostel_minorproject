import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../widgets/entry_exit_list.dart';

/// Guard-only: a short form to log a student in/out by enrollment number
/// (POST /api/entry-exit/), sitting above a live history list.
class LogEntryExitTab extends StatefulWidget {
  const LogEntryExitTab({super.key});

  @override
  State<LogEntryExitTab> createState() => _LogEntryExitTabState();
}

class _LogEntryExitTabState extends State<LogEntryExitTab> {
  final _enrollmentController = TextEditingController();
  final _remarksController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _listKey = GlobalKey<EntryExitListState>();
  String _status = 'IN';
  bool _loading = false;

  @override
  void dispose() {
    _enrollmentController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ApiService.post('/api/entry-exit/', {
        'enrollment_no': _enrollmentController.text.trim(),
        'status': _status,
        'remarks': _remarksController.text.trim(),
      });
      _enrollmentController.clear();
      _remarksController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Logged successfully.')));
      }
      _listKey.currentState?.refresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Card(
          margin: const EdgeInsets.all(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Log Student Entry / Exit', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _enrollmentController,
                    decoration: const InputDecoration(
                      labelText: 'Enrollment number',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'IN', label: Text('Entry (IN)'), icon: Icon(Icons.login)),
                      ButtonSegment(value: 'OUT', label: Text('Exit (OUT)'), icon: Icon(Icons.logout)),
                    ],
                    selected: {_status},
                    onSelectionChanged: (s) => setState(() => _status = s.first),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _remarksController,
                    decoration: const InputDecoration(
                      labelText: 'Remarks (optional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _loading ? null : _submit,
                    child: _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Submit'),
                  ),
                ],
              ),
            ),
          ),
        ),
        const Divider(height: 1),
        Expanded(child: EntryExitList(key: _listKey)),
      ],
    );
  }
}
