import 'package:flutter/material.dart';
import '../../widgets/app_drawer.dart';
import 'hostels_tab.dart';
import 'wardens_tab.dart';
import '../../widgets/request_reports.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Super Admin'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.apartment), text: 'Hostels'),
              Tab(icon: Icon(Icons.shield_outlined), text: 'Wardens'),
              Tab(
  icon: Icon(Icons.assessment_outlined),
  text: 'Reports',
),
            ],
          ),
        ),
        drawer: const AppDrawer(roleLabel: 'Super Admin'),
        body: const TabBarView(
          children: [
            HostelsTab(),
            WardensTab(),
            RequestReports(),
          ],
        ),
      ),
    );
  }
}
