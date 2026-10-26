import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../screens/login_screen.dart';
import '../screens/change_password_screen.dart';

/// Drawer shared by every role's dashboard: shows who's logged in and
/// offers "Change Password" (works anytime, not just on forced first login)
/// and "Log Out".
class AppDrawer extends StatelessWidget {
  final String roleLabel;
  const AppDrawer({super.key, required this.roleLabel});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: FutureBuilder<String?>(
          future: ApiService.getUsername(),
          builder: (context, snapshot) {
            return Column(
              children: [
                DrawerHeader(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const CircleAvatar(radius: 24, child: Icon(Icons.person)),
                      const SizedBox(height: 8),
                      Text(snapshot.data ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(roleLabel, style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.lock_reset),
                  title: const Text('Change Password'),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
                    );
                  },
                ),
                const Spacer(),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text('Log Out', style: TextStyle(color: Colors.red)),
                  onTap: () async {
                    await ApiService.logout();
                    if (context.mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (route) => false,
                      );
                    }
                  },
                ),
                const SizedBox(height: 16),
              ],
            );
          },
        ),
      ),
    );
  }
}
