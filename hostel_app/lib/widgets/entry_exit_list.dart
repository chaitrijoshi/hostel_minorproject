import 'dart:async';

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

  List<String> destinationSuggestions = [];
  bool isLoadingDestinationSuggestions = false;
  Timer? _destinationTimer;

  late Future<List<EntryExitRequest>> requests;

  @override
  void initState() {
    super.initState();
    requests = loadRequests();
  }

  @override
  void dispose() {
    _destinationTimer?.cancel();
    destination.dispose();
    super.dispose();
  }

  void onDestinationChanged(String value) {
    _destinationTimer?.cancel();

    if (value.trim().length < 3) {
      setState(() {
        destinationSuggestions = [];
        isLoadingDestinationSuggestions = false;
      });
      return;
    }

    _destinationTimer = Timer(
      const Duration(milliseconds: 350),
      () => fetchDestinationSuggestions(value.trim()),
    );
  }

  Future<void> fetchDestinationSuggestions(String text) async {
    if (!mounted) return;

    setState(() {
      isLoadingDestinationSuggestions = true;
    });

    try {
      final data = await ApiService.get(
        '/api/entry-exit/destination-suggestions/?text=${Uri.encodeQueryComponent(text)}',
      );

      if (!mounted || destination.text.trim() != text) return;

      final results = (data['results'] as List? ?? [])
          .map((item) => (item['formatted'] ?? item['name'] ?? '').toString())
          .where((item) => item.isNotEmpty)
          .toSet()
          .toList();

      setState(() {
        destinationSuggestions = results;
        isLoadingDestinationSuggestions = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        destinationSuggestions = [];
        isLoadingDestinationSuggestions = false;
      });
    }
  }

  void chooseDestination(String value) {
    destination.text = value;
    destination.selection = TextSelection.collapsed(
      offset: destination.text.length,
    );
    setState(() {
      destinationSuggestions = [];
      isLoadingDestinationSuggestions = false;
    });
  }

  Future<List<EntryExitRequest>> loadRequests() async {
    final data = await ApiService.get(
      '/api/entry-exit/requests/my/',
    );

    return (data as List)
        .map((e) => EntryExitRequest.fromJson(e))
        .toList();
  }

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
              _destinationTimer?.cancel();
              destination.clear();
              destinationSuggestions = [];
              isLoadingDestinationSuggestions = false;
              returnTime = null;
            });
          },
        ),

        if (type == 'EXIT') ...[
          TextField(
            controller: destination,
            onChanged: onDestinationChanged,
            decoration: InputDecoration(
              labelText: 'Destination',
              hintText: 'Type at least 3 letters',
              suffixIcon: isLoadingDestinationSuggestions
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      ),
                    )
                  : null,
            ),
          ),
          if (destinationSuggestions.isNotEmpty)
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              margin: const EdgeInsets.only(top: 4, bottom: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(4),
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: destinationSuggestions.length,
                itemBuilder: (context, index) {
                  final suggestion = destinationSuggestions[index];
                  return ListTile(
                    dense: true,
                    leading: const Icon(Icons.location_on_outlined),
                    title: Text(suggestion),
                    onTap: () => chooseDestination(suggestion),
                  );
                },
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
    String newStatus, {
    String rejectionReason = '',
  }) async {
    try {
      final data = <String, dynamic>{
        'status': newStatus,
      };

      if (newStatus == 'REJECTED') {
        data['rejection_reason'] = rejectionReason;
      }

      await ApiService.patch(
        '/api/entry-exit/requests/${request.id}/',
        data,
      );

      if (!mounted) return;

      setState(() {
        requests = loadRequests();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newStatus == 'REJECTED'
                ? 'Request rejected successfully'
                : 'Request approved successfully',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    }
  }

  Future<void> rejectRequest(
    EntryExitRequest request,
  ) async {
    final controller = TextEditingController();

    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Reject Request'),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Reason for rejection',
              hintText: 'Enter reason',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (controller.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Please enter a rejection reason',
                      ),
                    ),
                  );
                  return;
                }

                Navigator.pop(
                  dialogContext,
                  controller.text.trim(),
                );
              },
              child: const Text('Reject'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (reason == null || reason.trim().isEmpty) return;

    await updateRequest(
      request,
      'REJECTED',
      rejectionReason: reason.trim(),
    );
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
                    '${r.requestType == 'EXIT'
                        ? 'Destination: ${r.destination}'
                        : 'Entry Request Time: ${_formatEntryTime(r.requestTime)}'}',
                  ),
                  trailing: Wrap(
                    spacing: 4,
                    children: [
                      IconButton(
                        tooltip: 'Approve',
                        onPressed: () =>
                            updateRequest(r, 'APPROVED'),
                        icon: const Icon(
                          Icons.check,
                          color: Colors.green,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Reject',
                        onPressed: () => rejectRequest(r),
                        icon: const Icon(
                          Icons.close,
                          color: Colors.red,
                        ),
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
    final rejectionReason =
        request.rejectionReason ?? '';

    return Card(
      child: ListTile(
        title: Text('${request.requestType} Request'),
        subtitle: Text(
          'Student: ${request.studentName}\n'
          '${isExit
              ? 'Destination: ${request.destination}\n'
                'Expected Return: ${request.expectedReturnTime == null ? "Not specified" : formatDateTime(request.expectedReturnTime!)}'
              : 'Entry Time: ${_formatEntryTime(request.entryTime)}'}'
          '${request.status == 'REJECTED' &&
                  rejectionReason.trim().isNotEmpty
              ? '\nRejection Reason: $rejectionReason'
              : ''}',
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
