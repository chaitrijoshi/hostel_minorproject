
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models.dart';
import '../utils.dart';

// STUDENT
class StudentEntryExitRequests extends StatefulWidget {
  const StudentEntryExitRequests({super.key});

  @override
  State<StudentEntryExitRequests> createState() =>
      _StudentEntryExitRequestsState();
}

class _StudentEntryExitRequestsState
    extends State<StudentEntryExitRequests> {
  final destination = TextEditingController();
  String type = 'EXIT';
  DateTime? returnTime;

  late Future<List<EntryExitRequest>> requests;

  @override
  void initState() {
    super.initState();
    requests = loadRequests();
  }

  @override
  void dispose() {
    destination.dispose();
    super.dispose();
  }

  // Future<List<EntryExitRequest>> loadRequests() async {
  //   final data = await ApiService.get(
  //     '/api/entry-exit/requests/my/',
  //   );

  //   return (data as List)
  //       .map((e) => EntryExitRequest.fromJson(e))
  //       .toList();
  // }


  //temporary code

  Future<List<EntryExitRequest>> loadRequests() async {
  final data = await ApiService.get(
    '/api/entry-exit/requests/my/',
  );

  debugPrint('MY REQUESTS API: $data');

  return (data as List)
      .map((e) => EntryExitRequest.fromJson(e))
      .toList();
}


// --------end------------------

  Future<void> selectTime() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(
        const Duration(days: 30),
      ),
      initialDate: DateTime.now(),
    );

    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (time == null || !mounted) return;

    setState(() {
      returnTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> submit() async {
    if (type == 'EXIT' &&
        (destination.text.trim().isEmpty ||
            returnTime == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter destination and return time'),
        ),
      );
      return;
    }

    try {
      final data = <String, dynamic>{
        'request_type': type,
      };

      if (type == 'EXIT') {
        data['destination'] = destination.text.trim();
        data['expected_return_time'] =
            returnTime!.toIso8601String();
      }

      await ApiService.post(
        '/api/entry-exit/requests/create/',
        data,
      );

      if (!mounted) return;

      destination.clear();

      setState(() {
        returnTime = null;
        requests = loadRequests();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Request submitted'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        const Text('Create Entry / Exit Request'),

        SegmentedButton<String>(
          segments: const [
            ButtonSegment(
              value: 'EXIT',
              label: Text('EXIT'),
            ),
            ButtonSegment(
              value: 'ENTRY',
              label: Text('ENTRY'),
            ),
          ],
          selected: {type},
          onSelectionChanged: (value) {
            setState(() {
              type = value.first;
              destination.clear();
              returnTime = null;
            });
          },
        ),

        if (type == 'EXIT') ...[
          TextField(
            controller: destination,
            decoration: const InputDecoration(
              labelText: 'Destination',
            ),
          ),
          OutlinedButton(
            onPressed: selectTime,
            child: Text(
              returnTime == null
                  ? 'Expected Return Time'
                  : formatDateTime(
                      returnTime!.toIso8601String(),
                    ),
            ),
          ),
        ],

        FilledButton(
          onPressed: submit,
          child: const Text('Submit Request'),
        ),

        const SizedBox(height: 16),
        const Text('My Requests'),

        FutureBuilder<List<EntryExitRequest>>(
          future: requests,
          builder: (context, snapshot) {
            if (snapshot.connectionState ==
                ConnectionState.waiting) {
              return const CircularProgressIndicator();
            }

            if (snapshot.hasError) {
              return Text('${snapshot.error}');
            }

            final list = snapshot.data ?? [];

            if (list.isEmpty) {
              return const Text('No requests yet');
            }

            return Column(
              children: list
                  .map((r) => RequestCard(request: r))
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

// GUARD
class GuardEntryExitRequests extends StatefulWidget {
  const GuardEntryExitRequests({super.key});

  @override
  State<GuardEntryExitRequests> createState() =>
      _GuardEntryExitRequestsState();
}

class _GuardEntryExitRequestsState
    extends State<GuardEntryExitRequests> {
  late Future<List<EntryExitRequest>> requests;

  @override
  void initState() {
    super.initState();
    requests = loadRequests();
  }

  Future<List<EntryExitRequest>> loadRequests() async {
    final data = await ApiService.get(
      '/api/entry-exit/requests/pending/',
    );

    return (data as List)
        .map((e) => EntryExitRequest.fromJson(e))
        .toList();
  }

  Future<void> updateRequest(
    EntryExitRequest request,
    String status,
  ) async {
    try {
      await ApiService.patch(
        '/api/entry-exit/requests/${request.id}/',
        {'status': status},
      );

      if (!mounted) return;

      setState(() {
        requests = loadRequests();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Request $status')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<EntryExitRequest>>(
      future: requests,
      builder: (context, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('${snapshot.error}'),
          );
        }

        final list = snapshot.data ?? [];

        if (list.isEmpty) {
          return const Center(
            child: Text('No pending requests'),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            final future = loadRequests();

            setState(() {
              requests = future;
            });

            await future;
          },
          child: ListView(
            children: list.map((r) {
              return Card(
                child: ListTile(
                  title: Text('${r.requestType} Request'),
                  subtitle: Text(
                    'Student: ${r.studentName}\n'
                    'Enrollment: ${r.enrollmentNo}\n'
                    'Room: ${r.roomNo}\n'
                    '${r.requestType == 'EXIT'
                        ? 'Destination: ${r.destination}'
                        : 'Entry Time: ${_formatEntryTime(r.entryTime)}'}',
                  ),
                  trailing: Wrap(
                    spacing: 4,
                    children: [
                      IconButton(
                        tooltip: 'Approve',
                        onPressed: () =>
                            updateRequest(r, 'APPROVED'),
                        icon: const Icon(Icons.check),
                      ),
                      IconButton(
                        tooltip: 'Reject',
                        onPressed: () =>
                            updateRequest(r, 'REJECTED'),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

// WARDEN
class EntryExitList extends StatefulWidget {
  const EntryExitList({super.key});

  @override
  State<EntryExitList> createState() =>
      _EntryExitListState();
}

class _EntryExitListState extends State<EntryExitList> {
  late Future<List<EntryExitRequest>> requests;

  @override
  void initState() {
    super.initState();
    requests = loadRequests();
  }

  Future<List<EntryExitRequest>> loadRequests() async {
    final data = await ApiService.get(
      '/api/entry-exit/requests/my/',
    );

    return (data as List)
        .map((e) => EntryExitRequest.fromJson(e))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<EntryExitRequest>>(
      future: requests,
      builder: (context, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('${snapshot.error}'),
          );
        }

        final list = snapshot.data ?? [];

        if (list.isEmpty) {
          return const Center(
            child: Text('No requests'),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            final future = loadRequests();

            setState(() {
              requests = future;
            });

            await future;
          },
          child: ListView(
            children: list
                .map((r) => RequestCard(request: r))
                .toList(),
          ),
        );
      },
    );
  }
}

// COMMON REQUEST CARD
class RequestCard extends StatelessWidget {
  final EntryExitRequest request;

  const RequestCard({
    super.key,
    required this.request,
  });

  @override
  Widget build(BuildContext context) {
    final isExit = request.requestType == 'EXIT';

    return Card(
      child: ListTile(
        title: Text('${request.requestType} Request'),
        subtitle: Text(
          'Student: ${request.studentName}\n'
          '${isExit
              ? 'Destination: ${request.destination}\n'
                'Expected Return: ${request.expectedReturnTime == null ? "Not specified" : formatDateTime(request.expectedReturnTime!)}'
              : 'Entry Time: ${_formatEntryTime(request.entryTime)}'}',
        ),
        trailing: Text(request.status),
      ),
    );
  }
}

// FORMAT ENTRY TIME
String _formatEntryTime(String? entryTime) {
  if (entryTime == null || entryTime.isEmpty) {
    return 'Not available';
  }

  try {
    return formatDateTime(
      DateTime.parse(entryTime).toLocal().toIso8601String(),
    );
  } catch (_) {
    return entryTime;
  }
}
