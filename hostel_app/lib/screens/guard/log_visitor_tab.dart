import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../widgets/visitor_list.dart';

/// Guard-only: a short form to log a visitor against a student's
/// enrollment number (POST /api/visitors/), sitting above a live list
/// that also lets the guard mark a visitor's exit.
class LogVisitorTab extends StatefulWidget {
  const LogVisitorTab({super.key});

  @override
  State<LogVisitorTab> createState() => _LogVisitorTabState();
}

class _LogVisitorTabState extends State<LogVisitorTab> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _purposeController = TextEditingController();
  final _enrollmentController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _listKey = GlobalKey<VisitorListWidgetState>();
  bool _loading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _purposeController.dispose();
    _enrollmentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ApiService.post('/api/visitors/', {
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'purpose': _purposeController.text.trim(),
        'enrollment_no': _enrollmentController.text.trim(),
      });
      _nameController.clear();
      _phoneController.clear();
      _purposeController.clear();
      _enrollmentController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Visitor logged.')));
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
                  const Text('Log a Visitor', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: "Visitor's name", border: OutlineInputBorder()),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(labelText: 'Phone', border: OutlineInputBorder()),
                    keyboardType: TextInputType.phone,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _purposeController,
                    decoration: const InputDecoration(
                      labelText: 'Purpose of visit (optional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _enrollmentController,
                    decoration: const InputDecoration(
                      labelText: 'Student enrollment number (who they are visiting)',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
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
        Expanded(child: VisitorListWidget(key: _listKey, allowMarkExit: true)),
      ],
    );
  }
}
