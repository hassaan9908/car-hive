import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
import 'admin_login_page.dart';
import 'admin_layout.dart';

class AdminMain extends StatefulWidget {
  const AdminMain({super.key});

  @override
  State<AdminMain> createState() => _AdminMainState();
}

class _AdminMainState extends State<AdminMain> {
  bool _hasCheckedPrivileges = false;

  @override
  void initState() {
    super.initState();
    print('AdminMain: Widget initialized');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('AdminMain: Starting admin provider initialization...');
      _checkAdminPrivileges();
    });
  }

  Future<void> _checkAdminPrivileges() async {
    if (_hasCheckedPrivileges) {
      print('AdminMain: Privileges already checked, skipping...');
      return;
    }

    print('AdminMain: Checking admin privileges...');
    await context.read<AdminProvider>().initialize();
    _hasCheckedPrivileges = true;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (context, adminProvider, child) {
        print('AdminMain: Building with isLoading: ${adminProvider.isLoading}, isAuthenticated: ${adminProvider.isAuthenticated}, hasAdminPrivileges: ${adminProvider.hasAdminPrivileges}');
        
        // Show loading only during initial check
        if (adminProvider.isLoading && !_hasCheckedPrivileges) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Checking Admin Privileges...'),
                ],
              ),
            ),
          );
        }

        // Check if user is authenticated as admin
        if (adminProvider.isAuthenticated && adminProvider.currentAdmin != null) {
          // Verify the user actually has admin role
          if (adminProvider.hasAdminPrivileges) {
            print('AdminMain: User has admin privileges, showing AdminLayout');
            return const AdminLayout();
          } else {
            print('AdminMain: User is authenticated but does not have admin privileges');
          }
        } else {
          print('AdminMain: User is not authenticated or no current admin data');
        }

        // Show access denied page for non-admin users
        print('AdminMain: Showing access denied page');
        return Scaffold(
          appBar: AppBar(
            title: const Text('Access Denied'),
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.block,
                  size: 64,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Access Denied',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'You do not have permission to access the admin panel.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  'Current Role: ${adminProvider.currentUserRole}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'User: ${adminProvider.currentAdmin?.email ?? 'Unknown'}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pushReplacementNamed(context, '/'),
                  child: const Text('Back to Home'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
