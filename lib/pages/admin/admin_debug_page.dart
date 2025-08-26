import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../../providers/admin_provider.dart';
import '../../auth/auth_provider.dart' as app_auth;
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminDebugPage extends StatelessWidget {
  const AdminDebugPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Debug Info'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: Consumer2<AdminProvider, app_auth.AuthProvider>(
        builder: (context, adminProvider, authProvider, _) {
          final currentUser = firebase_auth.FirebaseAuth.instance.currentUser;
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Debug Information',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                
                // Firebase Auth Info
                _buildInfoCard(
                  'Firebase Auth',
                  [
                    'Current User: ${currentUser?.email ?? 'None'}',
                    'User ID: ${currentUser?.uid ?? 'None'}',
                    'Is Logged In: ${authProvider.isLoggedIn}',
                  ],
                  Colors.blue,
                ),
                
                const SizedBox(height: 16),
                
                // Admin Provider Info
                _buildInfoCard(
                  'Admin Provider',
                  [
                    'Is Loading: ${adminProvider.isLoading}',
                    'Is Authenticated: ${adminProvider.isAuthenticated}',
                    'Current Admin: ${adminProvider.currentAdmin?.email ?? 'None'}',
                    'Admin Role: ${adminProvider.currentUserRole}',
                    'Has Admin Privileges: ${adminProvider.hasAdminPrivileges}',
                    'Can Access Admin Panel: ${adminProvider.canAccessAdminPanel}',
                    'Error Message: ${adminProvider.errorMessage ?? 'None'}',
                  ],
                  Colors.green,
                ),
                
                const SizedBox(height: 16),
                
                // Actions
                _buildInfoCard(
                  'Actions',
                  [
                    'Click buttons below to test functionality',
                  ],
                  Colors.orange,
                ),
                
                const SizedBox(height: 20),
                
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          adminProvider.debugCurrentState();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Debug info printed to console')),
                          );
                        },
                        child: const Text('Print Debug Info'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          await adminProvider.initialize();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Admin provider re-initialized')),
                          );
                        },
                        child: const Text('Re-initialize'),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          await adminProvider.refreshAdminStatus();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Admin status refreshed')),
                          );
                        },
                        child: const Text('Refresh Status'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          adminProvider.adminLogout();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Admin logged out')),
                          );
                        },
                        child: const Text('Admin Logout'),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                ElevatedButton(
                  onPressed: () {
                    adminProvider.resetState();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Admin provider state reset'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Reset Admin State'),
                ),
                
                const SizedBox(height: 20),
                
                ElevatedButton(
                  onPressed: () => Navigator.pushReplacementNamed(context, '/admin'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Go to Admin Panel'),
                ),
                
                const SizedBox(height: 20),
                
                // Admin Setup Section
                _buildInfoCard(
                  'Admin Setup',
                  [
                    'Use this button to set current user as super_admin',
                    'This will update your Firestore document',
                  ],
                  Colors.red,
                ),
                
                const SizedBox(height: 16),
                
                ElevatedButton(
                  onPressed: () async {
                    try {
                      final currentUser = firebase_auth.FirebaseAuth.instance.currentUser;
                      if (currentUser != null) {
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(currentUser.uid)
                            .update({
                          'role': 'super_admin',
                          'isActive': true,
                        });
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('User role updated to super_admin'),
                            backgroundColor: Colors.green,
                          ),
                        );
                        
                        // Re-initialize admin provider
                        await adminProvider.initialize();
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Set Current User as Super Admin'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildInfoCard(String title, List<String> items, Color color) {
    return Card(
      color: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 8),
            ...items.map((item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(
                '• $item',
                style: const TextStyle(fontSize: 14),
              ),
            )),
          ],
        ),
      ),
    );
  }
}
