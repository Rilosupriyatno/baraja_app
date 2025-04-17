import 'package:baraja_app/widgets/profile/point_button.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../widgets/profile/profile_header.dart';
import '../widgets/menu/menu_item.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    await authService.fetchUserProfile();
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final userData = authService.user;

    return Scaffold(
      backgroundColor: Colors.white,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 80), // Memberi ruang bawah agar tidak tertutup navbar
        child: Column(
          children: [
            const SizedBox(height: 60), // Memberi lebih banyak ruang di atas

            // Profile Header with dynamic data
            userData != null
                ? ProfileHeader(
              name: userData['username'] ?? 'User',
              phoneNumber: userData['phone'] ?? 'No phone',
              email: userData['email'],
              profilePicture: userData['profilePicture'],
              consumerType: userData['consumerType'],
            )
                : const ProfileHeader(
              name: 'Guest User',
              phoneNumber: 'Not signed in',
            ),

            const SizedBox(height: 20),

            // Points and Voucher Row
            userData != null
                ? PointButtons(
              points: userData['loyaltyPoints']?.toString(),
              vouchers: userData['claimedVouchers']?.length ?? 0,
            )
                : const PointButtons(),

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
            MenuItem(
              icon: Icons.exit_to_app,
              label: 'Keluar',
              iconColor: Colors.red, // Merah
              onTap: () async {
                await Provider.of<AuthService>(context, listen: false).logout();
                context.go('/login');
              },
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