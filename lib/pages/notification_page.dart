import 'package:flutter/material.dart';

import '../widgets/classic_app_bar.dart';

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const ClassicAppBar(title: 'Pemberitahuan'),
      body: ListView.builder(
        itemCount: 5,
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) {
          // Sample notification items
          return Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 16),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.green.shade100,
                child: const Icon(
                  Icons.notifications,
                  color: Colors.green,
                ),
              ),
              title: Text('Pemberitahuan ${index + 1}'),
              subtitle: const Text(
                'Ini adalah contoh pemberitahuan untuk pengguna. '
                    'Tap untuk melihat detail.',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Text(
                '${DateTime.now().day - index}/${DateTime.now().month}',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
              onTap: () {
                // Handle notification tap
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Pemberitahuan ${index + 1} dipilih'),
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}