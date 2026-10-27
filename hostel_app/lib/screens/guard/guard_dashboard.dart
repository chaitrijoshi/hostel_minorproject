import 'package:flutter/material.dart';

import '../../widgets/app_drawer.dart';
import '../../widgets/entry_exit_list.dart';
import '../../widgets/notifications_list.dart';
import '../guard/log_visitor_tab.dart';
import '../../widgets/request_reports.dart';

class GuardDashboard extends StatelessWidget {
  const GuardDashboard({
    super.key,
  });


  @override
  Widget build(BuildContext context) {

    return DefaultTabController(

      length: 4,

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
              Tab(
  icon: Icon(Icons.assessment_outlined),
  text: 'Reports',
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
            RequestReports(),

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