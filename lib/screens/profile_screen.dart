import 'package:baraja_amphitheater_app/widgets/profile/point_button.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../services/auth_service.dart';
import '../widgets/profile/profile_header.dart';
import '../widgets/menu/menu_item.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../services/voucher_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  int _voucherCount = 0;
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    final authService = Provider.of<AuthService>(context, listen: false);
    await authService.fetchUserProfile();

    try {
      final vouchers = await VoucherService().fetchVouchers();
      _voucherCount = vouchers.length;
    } catch (e) {
      _voucherCount = 0;
    }

    if (mounted) {
      setState(() {
        _userData = authService.user;
        _isLoading = false;
      });
    }
  }

  // Dummy user data untuk skeleton
  Map<String, dynamic> _getDummyUserData() {
    return {
      'username': 'Loading Username Name',
      'phone': '08123456789012',
      'email': 'loading@example.com',
      'profilePicture': null,
      'consumerType': 'regular',
      'loyaltyPoints': 1234,
    };
  }

  @override
  Widget build(BuildContext context) {
    // Use dummy data when loading, real data when loaded
    final displayUserData = _isLoading ? _getDummyUserData() : _userData;
    final displayVoucherCount = _isLoading ? 5 : _voucherCount;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Skeletonizer(
        enabled: _isLoading,
        enableSwitchAnimation: true,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 80),
          child: Column(
            children: [
              const SizedBox(height: 60),

              // Profile Header with dynamic or dummy data
              displayUserData != null
                  ? ProfileHeader(
                name: displayUserData['username'] ?? 'User',
                phoneNumber: displayUserData['phone'] ?? 'No phone',
                email: displayUserData['email'],
                profilePicture: displayUserData['profilePicture'],
                consumerType: displayUserData['consumerType'],
              )
                  : const ProfileHeader(
                name: 'Guest User',
                phoneNumber: 'Not signed in',
              ),

              const SizedBox(height: 20),

              // Points and Voucher Row
              displayUserData != null
                  ? PointButtons(
                points: displayUserData['loyaltyPoints']?.toString(),
                vouchers: displayVoucherCount,
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

              // Menu Items - disabled when loading
              MenuItem(
                icon: Icons.favorite,
                label: 'Favorit',
                onTap: _isLoading
                    ? () {}
                    : () {
                  context.push('/favorite');
                },
                iconColor: Colors.redAccent,
              ),

              const Divider(),
              MenuItem(
                icon: Icons.settings,
                label: 'Pengaturan Akun',
                onTap: _isLoading
                    ? () {}
                    : () {
                  context.push('/settings');
                },
                iconColor: Colors.grey,
              ),
              const Divider(),
              MenuItem(
                icon: Icons.exit_to_app,
                label: 'Keluar',
                iconColor: Colors.red,
                onTap: _isLoading
                    ? () {}
                    : () async {
                  await Provider.of<AuthService>(context, listen: false)
                      .logout();
                  context.go('/login');
                },
              ),
              const Divider(),

              const SizedBox(height: 40),

              // Help Center Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 80),
                child: ElevatedButton(
                  onPressed: _isLoading ? () {} : () {},
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
                        FontAwesomeIcons.headset,
                        size: 18,
                      ),
                      SizedBox(width: 10),
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
      ),
    );
  }
}