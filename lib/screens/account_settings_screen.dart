// import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../widgets/utils/classic_app_bar.dart';
import '../services/user_service.dart';
import 'personal_info_edit_screen.dart';
import 'change_password_screen.dart';

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  bool _notificationsEnabled = true;
  // bool _darkModeEnabled = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      // _darkModeEnabled = prefs.getBool('dark_mode_enabled') ?? false;
    });
  }

  Future<void> _updateNotificationPreference(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', value);
    setState(() {
      _notificationsEnabled = value;
    });

    _showSuccessSnackBar(
      value
          ? 'Notifikasi berhasil diaktifkan'
          : 'Notifikasi dinonaktifkan',
    );
  }

  Future<void> _navigateToPersonalInfo() async {
    setState(() {
      _isLoading = true;
    });

    // Check token validity before navigation
    bool isValidToken = await UserService.isTokenValid();

    setState(() {
      _isLoading = false;
    });

    if (!isValidToken) {
      if (mounted) {
        _showErrorSnackBar('Sesi telah berakhir, silakan login ulang');
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
        return;
      }
    }

    if (mounted) {
      final result = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const PersonalInfoEditScreen(),
        ),
      );

      // If update was successful, show confirmation
      if (result == true) {
        _showSuccessSnackBar('Informasi pribadi berhasil diperbarui');

        // Refresh data user supaya ProfileScreen update
        final authService = Provider.of<AuthService>(context, listen: false);
        await authService.fetchUserProfile();
      }

    }
  }

  Future<void> _navigateToChangePassword() async {
    setState(() {
      _isLoading = true;
    });

    // Check token validity and user type before navigation
    bool isValidToken = await UserService.isTokenValid();

    setState(() {
      _isLoading = false;
    });

    if (!isValidToken) {
      if (mounted) {
        _showErrorSnackBar('Sesi telah berakhir, silakan login ulang');
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
        return;
      }
    }

    if (mounted) {
      final result = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const ChangePasswordScreen(),
        ),
      );

      // If password change was successful, show confirmation
      if (result == true) {
        _showSuccessSnackBar('Password berhasil diubah');
      }
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // void _showComingSoonSnackBar(String feature) {
  //   ScaffoldMessenger.of(context).showSnackBar(
  //     SnackBar(
  //       content: Text('$feature akan segera tersedia'),
  //       backgroundColor: Colors.blue,
  //       duration: const Duration(seconds: 1),
  //     ),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const ClassicAppBar(title: 'Pengaturan Akun'),
      body: Stack(
        children: [
          ListView(
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Pengaturan Umum',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ),

              // Notification Settings
              SwitchListTile(
                title: const Text('Aktifkan Notifikasi'),
                subtitle: const Text('Menerima pemberitahuan tentang aktivitas akun'),
                value: _notificationsEnabled,
                onChanged: (value) async {
                  await _updateNotificationPreference(value);
                },
                secondary: const Icon(Icons.notifications_active),
              ),
              const Divider(),

              // Dark Mode Settings (commented out as per original)
              // SwitchListTile(
              //   title: const Text('Mode Gelap'),
              //   subtitle: const Text('Gunakan tema gelap untuk aplikasi'),
              //   value: AdaptiveTheme.of(context).mode == AdaptiveThemeMode.dark,
              //   onChanged: (value) {
              //     if (value) {
              //       AdaptiveTheme.of(context).setDark();
              //     } else {
              //       AdaptiveTheme.of(context).setLight();
              //     }
              //   },
              //   secondary: const Icon(Icons.dark_mode),
              // ),
              // const Divider(),

              // Personal Information Settings
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('Informasi Pribadi'),
                subtitle: const Text('Perbarui nama, email, dan nomor telepon'),
                trailing: const Icon(Icons.chevron_right),
                onTap: _navigateToPersonalInfo,
              ),
              const Divider(),

              // Password Settings
              ListTile(
                leading: const Icon(Icons.lock),
                title: const Text('Ubah Password'),
                subtitle: const Text('Perbarui password untuk keamanan akun'),
                trailing: const Icon(Icons.chevron_right),
                onTap: _navigateToChangePassword,
              ),
              const Divider(),

              // Address Settings (commented out as per original)
              // ListTile(
              //   leading: const Icon(Icons.location_on),
              //   title: const Text('Alamat'),
              //   subtitle: const Text('Kelola alamat pengiriman dan penagihan'),
              //   trailing: const Icon(Icons.chevron_right),
              //   onTap: () {
              //     _showComingSoonSnackBar('Pengaturan Alamat');
              //   },
              // ),
              // const Divider(),

              // Privacy Settings (commented out as per original)
              // ListTile(
              //   leading: const Icon(Icons.privacy_tip),
              //   title: const Text('Privasi'),
              //   subtitle: const Text('Kelola pengaturan privasi dan data'),
              //   trailing: const Icon(Icons.chevron_right),
              //   onTap: () {
              //     _showComingSoonSnackBar('Pengaturan Privasi');
              //   },
              // ),
              // const Divider(),

              const SizedBox(height: 40),

              // Version Information
              Center(
                child: Text(
                  'Versi Aplikasi: 1.0.0',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),

          // Loading overlay
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Memverifikasi sesi...',
                      style: TextStyle(color: Colors.white),
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