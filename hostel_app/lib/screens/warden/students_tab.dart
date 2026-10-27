
import 'package:flutter/material.dart';
import '../../models.dart';
import '../../services/api_service.dart';

class StudentsTab extends StatefulWidget {
  const StudentsTab({super.key});

  @override
  State<StudentsTab> createState() => _StudentsTabState();
}

class _StudentsTabState extends State<StudentsTab> {
  late Future<List<Student>> _future;
  final Set<int> _updatingStudents = {};

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Student>> _load() async {
    final data = await ApiService.get('/api/students/');
    return (data as List)
        .map((e) => Student.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> _refresh() async {
    final future = _load();

    setState(() {
      _future = future;
    });

    await future;
  }

  Future<void> _changeStudentStatus(Student student) async {
    final newStatus = !student.isActive;
    final name =
        student.name.isNotEmpty ? student.name : student.username;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(newStatus ? 'Activate Student' : 'Deactivate Student'),
        content: Text(
          'Are you sure you want to '
          '${newStatus ? 'activate' : 'deactivate'} $name?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(newStatus ? 'Activate' : 'Deactivate'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _updatingStudents.add(student.id));

    try {
      await ApiService.patch(
        '/api/students/${student.id}/change-active-status/',
        {'is_active': newStatus},
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newStatus
                ? 'Student activated successfully.'
                : 'Student deactivated successfully.',
          ),
        ),
      );

      await _refresh();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update student: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _updatingStudents.remove(student.id));
      }
    }
  }

  Future<void> _addStudent() async {
    final nameController = TextEditingController();
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();
    final enrollmentController = TextEditingController();
    final departmentController = TextEditingController();
    final roomController = TextEditingController();
    final phoneController = TextEditingController();
    final parentController = TextEditingController();

    final formKey = GlobalKey<FormState>();

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add Student'),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Full name',
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Name is required';
                      }
                      if (!RegExp(r'^[a-zA-Z ]+$')
                          .hasMatch(v.trim())) {
                        return 'Only letters and spaces allowed';
                      }
                      return null;
                    },
                  ),

                  TextFormField(
                    controller: usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Temporary username',
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return 'Username is required';
                      }
                      if (!RegExp(r'^[a-zA-Z0-9]+$').hasMatch(v)) {
                        return 'Only letters and numbers allowed';
                      }
                      return null;
                    },
                  ),

                  TextFormField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Temporary password',
                    ),
                    validator: (v) {
                      if (v == null || v.length < 6) {
                        return 'At least 6 characters';
                      }
                      return null;
                    },
                  ),

                  TextFormField(
                    controller: enrollmentController,
                    keyboardType: TextInputType.number,
                    maxLength: 12,
                    decoration: const InputDecoration(
                      labelText: 'Enrollment number',
                    ),
                    validator: (v) {
                      if (v == null ||
                          !RegExp(r'^[0-9]{12}$').hasMatch(v)) {
                        return 'Enrollment number must be 12 digits';
                      }
                      return null;
                    },
                  ),

                  TextFormField(
                    controller: departmentController,
                    decoration: const InputDecoration(
                      labelText: 'Department',
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Department is required';
                      }
                      return null;
                    },
                  ),

                  TextFormField(
                    controller: roomController,
                    decoration: const InputDecoration(
                      labelText: 'Room number',
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty
                            ? 'Room number is required'
                            : null,
                  ),

                  TextFormField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Phone (optional)',
                    ),
                  ),

                  TextFormField(
                    controller: parentController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Parent contact (optional)',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;

              try {
                await ApiService.post('/api/students/', {
                  'full_name': nameController.text.trim(),
                  'username': usernameController.text.trim(),
                  'password': passwordController.text,
                  'enrollment_no':
                      enrollmentController.text.trim(),
                  'department': departmentController.text.trim(),
                  'room_no': roomController.text.trim(),
                  'phone': phoneController.text.trim(),
                  'parent_contact': parentController.text.trim(),
                });

                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext, true);
                }
              } catch (e) {
                if (dialogContext.mounted) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(content: Text(e.toString())),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    nameController.dispose();
    usernameController.dispose();
    passwordController.dispose();
    enrollmentController.dispose();
    departmentController.dispose();
    roomController.dispose();
    phoneController.dispose();
    parentController.dispose();

    if (saved == true && mounted) {
      await _refresh();
    }
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
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (snapshot.hasError) {
              return ListView(
                children: [
                  const SizedBox(height: 80),
                  const Icon(Icons.error_outline, size: 48),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      'Unable to load students.\n${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              );
            }

            final students = snapshot.data ?? [];

            if (students.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 100),
                  Center(
                    child: Text(
                      'No students found. Tap + to add one.',
                    ),
                  ),
                ],
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: students.length,
              itemBuilder: (context, index) {
                final student = students[index];
                final updating =
                    _updatingStudents.contains(student.id);

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            child: Icon(
                              student.isActive
                                  ? Icons.school
                                  : Icons.person_off,
                            ),
                          ),
                          title: Text(
                            student.name.isNotEmpty
                                ? student.name
                                : student.username,
                          ),
                          subtitle: Text(
                            'Room ${student.roomNo}\n'
                            'Enrollment: ${student.enrollmentNo}\n'
                            '@${student.username}',
                          ),
                          isThreeLine: true,
                        ),
                        const Divider(),
                        Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Chip(
                              avatar: Icon(
                                student.isActive
                                    ? Icons.check_circle
                                    : Icons.cancel,
                                size: 18,
                              ),
                              label: Text(
                                student.isActive
                                    ? 'Active'
                                    : 'Inactive',
                              ),
                            ),
                            if (updating)
                              const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            else
                              ElevatedButton.icon(
                                onPressed: () =>
                                    _changeStudentStatus(student),
                                icon: Icon(
                                  student.isActive
                                      ? Icons.person_off
                                      : Icons.person,
                                ),
                                label: Text(
                                  student.isActive
                                      ? 'Deactivate'
                                      : 'Activate',
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
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
