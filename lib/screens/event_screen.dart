import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class EventScreen extends StatelessWidget {
  const EventScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
        title: const Text(
          'Event',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                FontAwesomeIcons.ticketSimple,
                size: 60,
                color: Colors.green,
              ),
              SizedBox(height: 20),
              Text(
                'Fitur sedang dikembangkan',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 12),
              Text(
                'Kami sedang menyiapkan fitur event yang keren. Nantikan segera!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                ),
              ),
              SizedBox(height: 24),
              // ElevatedButton(
              //   onPressed: () => context.go('/home'),
              //   style: ElevatedButton.styleFrom(
              //     backgroundColor: Colors.green,
              //     shape: RoundedRectangleBorder(
              //       borderRadius: BorderRadius.circular(12),
              //     ),
              //     padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              //   ),
              //   child: const Text(
              //     'Kembali',
              //     style: TextStyle(fontSize: 16),
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}
