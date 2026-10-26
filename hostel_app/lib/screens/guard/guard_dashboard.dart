import 'package:flutter/material.dart';

import '../../widgets/app_drawer.dart';
import '../../widgets/entry_exit_list.dart';
import '../../widgets/notifications_list.dart';
import '../guard/log_visitor_tab.dart';


class GuardDashboard extends StatelessWidget {
  const GuardDashboard({
    super.key,
  });


  @override
  Widget build(BuildContext context) {

    return DefaultTabController(

      length: 3,

      child: Scaffold(

        appBar: AppBar(

          title: const Text(
            'Security Guard',
          ),

          bottom: const TabBar(

            tabs: [

              Tab(
                icon:
                    Icon(Icons.swap_horiz),
                text:
                    'Requests',
              ),

              Tab(
                icon:
                    Icon(Icons.people_outline),
                text:
                    'Visitors',
              ),

              Tab(
                icon:
                    Icon(Icons.notifications_none),
                text:
                    'Alerts',
              ),
            ],
          ),
        ),


        drawer: const AppDrawer(
          roleLabel: 'Security Guard',
        ),


        body: const TabBarView(

          children: [

            // Guard receives student requests
            // and approves/rejects them.
            GuardEntryExitRequests(),

            // Existing visitor section
            LogVisitorTab(),

            // Guard notifications
            NotificationsList(),
          ],
        ),
      ),
    );
  }
}