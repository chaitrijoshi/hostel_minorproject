import 'package:flutter/material.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/visitor_list.dart';
import 'students_tab.dart';
import 'guards_tab.dart';
import '../../widgets/request_reports.dart';

class WardenDashboard extends StatelessWidget {
  const WardenDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Warden'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(icon: Icon(Icons.school), text: 'Students'),
              Tab(icon: Icon(Icons.shield_outlined), text: 'Guards'),
              Tab(
  icon: Icon(Icons.assessment_outlined),
  text: 'Reports',
),
              Tab(icon: Icon(Icons.people_outline), text: 'Visitors'),
            ],
          ),
        ),
        drawer: const AppDrawer(roleLabel: 'Warden'),
        body: const TabBarView(
          children: [
            StudentsTab(),
            GuardsTab(),
            RequestReports(),
            VisitorListWidget(),
          ],
        ),
      ),
    );
  }
}
