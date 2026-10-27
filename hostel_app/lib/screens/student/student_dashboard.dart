import 'package:flutter/material.dart';

import '../../widgets/app_drawer.dart';
import '../../widgets/entry_exit_list.dart';
import '../../widgets/visitor_list.dart';
import '../../widgets/notifications_list.dart';
import '../../widgets/request_reports.dart';


class StudentDashboard extends StatelessWidget {
  const StudentDashboard({
    super.key,
  });


  @override
  Widget build(BuildContext context) {

    return DefaultTabController(

      length: 4,

      child: Scaffold(

        appBar: AppBar(

          title: const Text(
            'Student',
          ),

          bottom: const TabBar(

            tabs: [

              Tab(
                icon:
                    Icon(Icons.swap_horiz),
                text:
                    'Entry / Exit',
              ),
              Tab(
               icon:
                Icon(Icons.assessment_outlined),
              text: 
                    'Reports',
            ),

              Tab(
                icon:
                    Icon(Icons.people_outline),
                text:
                    'My Visitors',
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
          roleLabel: 'Student',
        ),


        body: const TabBarView(

          children: [

            // Student creates request
            // and sees request status.
            StudentEntryExitRequests(),

            // Existing visitor section
            VisitorListWidget(),

            // Notifications
            NotificationsList(),

            // Request Reports
            RequestReports(),
          ],
        ),
      ),
    );
  }
}