import 'package:flutter/material.dart';
import 'package:carhive/screens/video_capture_360_screen.dart';
import 'package:carhive/services/backend_360_service.dart';

/// Debug screen for testing 360 video capture and viewer
class Debug360Screen extends StatelessWidget {
  const Debug360Screen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('360° Debug Tools'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Backend health check
          Card(
            child: ListTile(
              leading: const Icon(Icons.health_and_safety),
              title: const Text('Backend Health Check'),
              subtitle: const Text('Check if backend server is running'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () async {
                final service = Backend360Service();
                final isHealthy = await service.checkHealth();
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isHealthy
                            ? 'Backend is healthy! ✓'
                            : 'Backend is not responding. Make sure the server is running on http://localhost:8000',
                      ),
                      backgroundColor: isHealthy ? Colors.green : Colors.red,
                    ),
                  );
                }
              },
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Video capture
          Card(
            child: ListTile(
              leading: const Icon(Icons.videocam),
              title: const Text('Capture 360° Video'),
              subtitle: const Text('Record 15-20 second video around car'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => VideoCapture360Screen(
                      onComplete: (frameUrls) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Generated ${frameUrls.length} frames!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Test viewer with sample frames
          Card(
            child: ListTile(
              leading: const Icon(Icons.view_in_ar),
              title: const Text('Test 360° Viewer'),
              subtitle: const Text('Preview viewer with sample frames (requires processed frames)'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                // Example: You can provide test frame URLs here
                // For now, show a message
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Test Viewer'),
                    content: const Text(
                      'To test the viewer, you need to:\n\n'
                      '1. Capture a video using the "Capture 360° Video" option\n'
                      '2. Process it through the backend\n'
                      '3. The viewer will open automatically after processing\n\n'
                      'Or provide frame URLs manually in the code.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Instructions
          Card(
            color: Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      Text(
                        'Setup Instructions',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '1. Start the backend server:\n'
                    '   cd backend\n'
                    '   python process.py\n\n'
                    '2. Make sure FFmpeg is installed\n\n'
                    '3. Use "Capture 360° Video" to record\n\n'
                    '4. The video will be processed automatically\n\n'
                    '5. View the result in the 360° viewer',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

