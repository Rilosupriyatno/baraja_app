import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/profile/profile_header.dart';
import '../widgets/profile/point_card.dart';
import '../widgets/menu/menu_item.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 80), // Memberi ruang bawah agar tidak tertutup navbar
        child: Column(
          children: [
            const SizedBox(height: 60), // Memberi lebih banyak ruang di atas

            // Profile Header Section
            const ProfileHeader(
              name: 'Rilo Supriyatno',
              phoneNumber: '085xxxxxxxxx',
            ),
            const SizedBox(height: 20),

            // Points and Voucher Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Expanded(
                    child: PointCard(
                      label: 'Point',
                      value: '500',
                      color: Color(0xFF0D8E54),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Expanded(
                    child: PointCard(
                      label: 'Point',
                      value: '500',
                      color: Color(0xFF0D8E54),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: PointCard(
                      label: 'Voucher',
                      value: '5',
                      color: Colors.green.shade300,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Account Information
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Informasi Akun',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const Divider(thickness: 1),

            // Menu Items
            MenuItem(
              icon: Icons.favorite,
              label: 'Favorit',
              onTap: () {
                context.push('/favorite');
              },
              iconColor: Colors.redAccent, // Merah hati
            ),
            const Divider(),
            MenuItem(
              icon: Icons.notifications,
              label: 'Pemberitahuan',
              onTap: () {
                context.push('/notification');
              },
              iconColor: Colors.amber, // Kuning lonceng
            ),
            const Divider(),
            MenuItem(
              icon: Icons.settings,
              label: 'Pengaturan Akun',
              onTap: () {
                context.push('/settings');
              },
              iconColor: Colors.grey, // Abu-abu
            ),
            const Divider(),
            const MenuItem(
              icon: Icons.exit_to_app,
              label: 'Keluar',
              iconColor: Colors.red, // Merah
            ),
            const Divider(),

            const SizedBox(height: 40),

            // Help Center Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 80),
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      FontAwesomeIcons.headset, // Ikon Headset dari FontAwesome
                      size: 18,
                    ),
                    SizedBox(width: 10), // Jarak antara ikon dan teks
                    Text(
                      'Pusat Bantuan',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
