import 'package:flutter/material.dart';

import '../models.dart';
import '../services/api_service.dart';
import '../utils.dart';


class NotificationsList extends StatefulWidget {
  const NotificationsList({super.key});

  @override
  State<NotificationsList> createState() =>
      NotificationsListState();
}


class NotificationsListState
    extends State<NotificationsList> {

  late Future<List<AppNotification>> _future;


  @override
  void initState() {
    super.initState();
    _future = _load();
  }


  Future<List<AppNotification>> _load() async {

    final data = await ApiService.get(
      '/api/notifications/',
    );

    return (data as List)
        .map(
          (e) => AppNotification.fromJson(e),
        )
        .toList();
  }


  Future<void> refresh() async {

    setState(() {
      _future = _load();
    });

    await _future;
  }


  Future<void> _markRead(int id) async {

    try {

      await ApiService.patch(
        '/api/notifications/$id/mark_read/',
        {},
      );

      await refresh();

    } catch (e) {

      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          SnackBar(
            content: Text(
              e.toString(),
            ),
          ),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {

    return RefreshIndicator(
      onRefresh: refresh,

      child: FutureBuilder<List<AppNotification>>(
        future: _future,

        builder: (context, snapshot) {

          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child:
                  CircularProgressIndicator(),
            );
          }


          if (snapshot.hasError) {

            return ListView(
              children: [
                const SizedBox(height: 80),

                const Icon(
                  Icons.error_outline,
                  size: 48,
                ),

                const SizedBox(height: 10),

                Center(
                  child: Text(
                    snapshot.error.toString(),
                    textAlign:
                        TextAlign.center,
                  ),
                ),
              ],
            );
          }


          final items =
              snapshot.data ?? [];


          if (items.isEmpty) {

            return ListView(
              children: const [
                SizedBox(height: 100),

                Center(
                  child: Icon(
                    Icons.notifications_none,
                    size: 50,
                  ),
                ),

                SizedBox(height: 10),

                Center(
                  child: Text(
                    'No notifications.',
                  ),
                ),
              ],
            );
          }


          return ListView.builder(

            padding:
                const EdgeInsets.all(12),

            itemCount:
                items.length,

            itemBuilder:
                (context, index) {

              final notification =
                  items[index];


              return Card(

                color: notification.isRead
                    ? null
                    : const Color(
                        0xFFEAF2FF,
                      ),

                child: ListTile(

                  leading: Icon(
                    notification.isRead
                        ? Icons.notifications_none
                        : Icons.notifications_active,
                  ),


                  title: Text(
                    notification.title,

                    style: TextStyle(
                      fontWeight:
                          notification.isRead
                              ? FontWeight.normal
                              : FontWeight.bold,
                    ),
                  ),


                  subtitle: Text(
                    '${notification.message}\n'
                    '${formatDateTime(notification.createdAt)}',
                  ),

                  isThreeLine: true,


                  trailing:
                      notification.isRead
                          ? null
                          : TextButton(
                              onPressed:
                                  () =>
                                      _markRead(
                                notification.id,
                              ),

                              child:
                                  const Text(
                                'Mark read',
                              ),
                            ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}