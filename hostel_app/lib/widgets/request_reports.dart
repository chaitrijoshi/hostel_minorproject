
import 'package:flutter/material.dart';

import '../services/api_service.dart';

class RequestReports extends StatefulWidget {
  const RequestReports({super.key});

  @override
  State<RequestReports> createState() => _RequestReportsState();
}

class _RequestReportsState extends State<RequestReports> {
  late Future<List<dynamic>> _reportsFuture;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  void _loadReports() {
    _reportsFuture = _fetchReports();
  }

  Future<List<dynamic>> _fetchReports() async {
    final response = await ApiService.get(
      '/api/entry-exit/requests/report/',
    );

    // Supports either a direct JSON list or a paginated response.
    if (response is List) {
      return response;
    }

    if (response is Map) {
      final results = response['results'] ?? response['data'];

      if (results is List) {
        return results;
      }
    }

    throw Exception('Unexpected response received from the reports API.');
  }

  Future<void> _refreshReports() async {
    setState(() {
      _loadReports();
    });

    await _reportsFuture;
  }

  String _formatDate(dynamic value) {
    if (value == null || value.toString().isEmpty) {
      return 'Not available';
    }

    final date = DateTime.tryParse(value.toString());

    if (date == null) {
      return value.toString();
    }

    final localDate = date.toLocal();

    String twoDigits(int number) => number.toString().padLeft(2, '0');

    return '${twoDigits(localDate.day)}/'
        '${twoDigits(localDate.month)}/'
        '${localDate.year} '
        '${twoDigits(localDate.hour)}:'
        '${twoDigits(localDate.minute)}';
  }

  String _text(dynamic value, {String fallback = 'Not available'}) {
    if (value == null || value.toString().trim().isEmpty) {
      return fallback;
    }

    return value.toString();
  }

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'APPROVED':
        return Colors.green;
      case 'REJECTED':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  Widget _detail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 145,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(Map report) {
    final status = _text(
      report['status'],
      fallback: 'PENDING',
    );

    final requestType = _text(report['request_type']);

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 7,
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '$requestType Request',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: _statusColor(status).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: _statusColor(status),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 20),

            _detail(
              'Student',
              _text(report['student_name']),
            ),
            _detail(
              'Enrollment No.',
              _text(report['enrollment_no']),
            ),
            _detail(
              'Room No.',
              _text(report['room_no']),
            ),
            _detail(
              'Destination',
              _text(
                report['destination'],
                fallback: 'Not specified',
              ),
            ),
            _detail(
              'Expected Return',
              _formatDate(report['expected_return_time']),
            ),
            _detail(
              'Request Time',
              _formatDate(report['request_time']),
            ),
            _detail(
              'Actual Entry Time',
              _formatDate(report['entry_time']),
            ),
            _detail(
              'Decision By',
              _text(report['decided_by_name']),
            ),

            if (status.toUpperCase() == 'REJECTED')
              _detail(
                'Rejection Reason',
                _text(
                  report['rejection_reason'],
                  fallback: 'No reason provided',
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: _reportsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 45,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Could not load reports.\n${snapshot.error}',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(_loadReports);
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Try Again'),
                  ),
                ],
              ),
            ),
          );
        }

        final reports = snapshot.data ?? [];

        if (reports.isEmpty) {
          return RefreshIndicator(
            onRefresh: _refreshReports,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 140),
                Icon(
                  Icons.description_outlined,
                  size: 55,
                  color: Colors.grey,
                ),
                SizedBox(height: 12),
                Center(
                  child: Text('No request reports available.'),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _refreshReports,
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: reports.length,
            itemBuilder: (context, index) {
              final item = reports[index];

              if (item is! Map) {
                return const SizedBox.shrink();
              }

              return _buildReportCard(item);
            },
          ),
        );
      },
    );
  }
}
