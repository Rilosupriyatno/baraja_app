import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/utils/classic_app_bar.dart';

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      _darkModeEnabled = prefs.getBool('dark_mode_enabled') ?? false;
    });
  }

  Future<void> _updateNotificationPreference(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', value);
    setState(() {
      _notificationsEnabled = value;
    });

    // Tampilkan feedback ke user
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          value
              ? 'Notifikasi berhasil diaktifkan'
              : 'Notifikasi dinonaktifkan',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const ClassicAppBar(title: 'Pengaturan Akun'),
      body: ListView(
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

          // Dark Mode Settings
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
            onTap: () {
              // Navigate to personal information settings
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Navigasi ke pengaturan informasi pribadi'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
          const Divider(),

          // Password Settings
          ListTile(
            leading: const Icon(Icons.lock),
            title: const Text('Ubah Password'),
            subtitle: const Text('Perbarui password untuk keamanan akun'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // Navigate to change password settings
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Navigasi ke pengaturan password'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
          const Divider(),

          // Address Settings
          // ListTile(
          //   leading: const Icon(Icons.location_on),
          //   title: const Text('Alamat'),
          //   subtitle: const Text('Kelola alamat pengiriman dan penagihan'),
          //   trailing: const Icon(Icons.chevron_right),
          //   onTap: () {
          //     // Navigate to address settings
          //     ScaffoldMessenger.of(context).showSnackBar(
          //       const SnackBar(
          //         content: Text('Navigasi ke pengaturan alamat'),
          //         duration: Duration(seconds: 1),
          //       ),
          //     );
          //   },
          // ),
          // const Divider(),

          // Privacy Settings
          // ListTile(
          //   leading: const Icon(Icons.privacy_tip),
          //   title: const Text('Privasi'),
          //   subtitle: const Text('Kelola pengaturan privasi dan data'),
          //   trailing: const Icon(Icons.chevron_right),
          //   onTap: () {
          //     // Navigate to privacy settings
          //     ScaffoldMessenger.of(context).showSnackBar(
          //       const SnackBar(
          //         content: Text('Navigasi ke pengaturan privasi'),
          //         duration: Duration(seconds: 1),
          //       ),
          //     );
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
    );
  }
}