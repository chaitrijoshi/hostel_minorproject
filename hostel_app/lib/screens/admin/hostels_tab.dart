
import 'package:flutter/material.dart';
import '../../models.dart';
import '../../services/api_service.dart';

class HostelsTab extends StatefulWidget {
  const HostelsTab({super.key});

  @override
  State<HostelsTab> createState() => _HostelsTabState();
}
class _HostelsTabState extends State<HostelsTab> {
  late Future<List<Hostel>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Hostel>> _load() async {
    final data = await ApiService.get('/api/hostels/');
    return (data as List).map((e) => Hostel.fromJson(e)).toList();
  }

 
Future<void> _refresh() async {
  final future = _load();

  setState(() {
    _future = future;
  });

  await future;
}

  // ADD HOSTEL
  Future<void> _addHostel() async {
    final nameController = TextEditingController();
    final addressController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add Hostel'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration:
                    const InputDecoration(labelText: 'Hostel name'),
                validator: (v) =>
                    v == null || v.trim().isEmpty
                        ? 'Required'
                        : null,
              ),
              TextFormField(
                controller: addressController,
                decoration:
                    const InputDecoration(labelText: 'Address'),
                maxLines: 2,
                validator: (v) =>
                    v == null || v.trim().isEmpty
                        ? 'Required'
                        : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;

              try {
                await ApiService.post('/api/hostels/', {
                  'name': nameController.text.trim(),
                  'address': addressController.text.trim(),
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
    addressController.dispose();

    if (saved == true && mounted) {
      await _refresh();
    }
  }
  // UPDATE HOSTEL
  Future<void> _editHostel(Hostel hostel) async {
    final nameController =
        TextEditingController(text: hostel.name);
    final addressController =
        TextEditingController(text: hostel.address);
    final formKey = GlobalKey<FormState>();

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Update Hostel'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Hostel name',
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty
                          ? 'Required'
                          : null,
                ),
                TextFormField(
                  controller: addressController,
                  decoration: const InputDecoration(
                    labelText: 'Address',
                  ),
                  maxLines: 2,
                  validator: (v) =>
                      v == null || v.trim().isEmpty
                          ? 'Required'
                          : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;

              try {
                await ApiService.patch(
                  '/api/hostels/${hostel.id}/',
                  {
                    'name': nameController.text.trim(),
                    'address': addressController.text.trim(),
                  },
                );

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
            child: const Text('Update'),
          ),
        ],
      ),
    );

    nameController.dispose();
    addressController.dispose();

    if (saved == true && mounted) {
      try {
        await _refresh();

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Hostel updated successfully'),
          ),
        );
      } catch (e) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _addHostel,
        tooltip: 'Add hostel',
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<Hostel>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState ==
                ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (snapshot.hasError) {
              return ListView(
                children: [
                  const SizedBox(height: 80),
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              );
            }

            final hostels = snapshot.data ?? [];

            if (hostels.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 100),
                  Center(
                    child: Text(
                      'No hostels yet. Tap + to add one.',
                    ),
                  ),
                ],
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: hostels.length,
              itemBuilder: (context, index) {
                final h = hostels[index];

                return Card(
                  child: ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.apartment),
                    ),
                    title: Text(h.name),
                    subtitle: Text(h.address),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${h.studentCount} students\n'
                          '${h.guardCount} guards',
                          textAlign: TextAlign.right,
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit),
                          tooltip: 'Edit hostel',
                          onPressed: () => _editHostel(h),
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
