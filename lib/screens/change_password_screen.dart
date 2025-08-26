import 'package:flutter/material.dart';
import '../utils/form_validator.dart';
import '../widgets/utils/classic_app_bar.dart';
import '../services/user_service.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isGoogleUser = false;
  bool _isLoading = true;
  bool _isChanging = false;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _checkUserType();
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _checkUserType() async {
    setState(() => _isLoading = true);

    try {
      print('DEBUG: Mulai cek user type...');

      // Ambil data user sekali saja
      final userData = await UserService.getCurrentUser();

      if (userData != null) {
        print('DEBUG: userData = $userData');

        final isGoogle = (userData['authType']?.toString().toLowerCase() == 'google');

        if (mounted) {
          setState(() {
            _isGoogleUser = isGoogle;
            _isLoading = false;
          });
        }
      } else {
        // fallback ke local
        final localData = await UserService.getUserDataLocally();
        print('DEBUG: fallback localData = $localData');

        if (mounted) {
          setState(() {
            _isGoogleUser = localData['is_google_user'] ?? false;
            _isLoading = false;
          });
        }
        _showWarningSnackBar('Menggunakan data offline, beberapa informasi mungkin tidak terbaru');
      }
    } catch (e) {
      print('ERROR: _checkUserType gagal => $e');

      try {
        final localData = await UserService.getUserDataLocally();
        if (mounted) {
          setState(() {
            _isGoogleUser = localData['is_google_user'] ?? false;
            _isLoading = false;
          });
        }
        _showErrorSnackBar('Gagal memuat data dari server, menggunakan data lokal');
      } catch (localError) {
        if (mounted) {
          setState(() {
            _isGoogleUser = false; // default jika semua gagal
            _isLoading = false;
          });
        }
      }
    }
  }

  Future<void> _changePassword() async {
    // Jangan lakukan apapun jika user adalah Google user
    if (_isGoogleUser) {
      _showErrorSnackBar('Anda tidak dapat mengubah password untuk akun Google');
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Client-side validation
    final validationErrors = FormValidators.validateChangePasswordData(
      currentPassword: _currentPasswordController.text,
      newPassword: _newPasswordController.text,
      confirmPassword: _confirmPasswordController.text,
    );

    if (validationErrors.isNotEmpty) {
      final firstError = validationErrors.values.first;
      _showErrorSnackBar(firstError);
      return;
    }

    try {
      setState(() {
        _isChanging = true;
      });

      // Call API to change password
      final result = await UserService.changePassword(
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
      );

      setState(() {
        _isChanging = false;
      });

      if (result['success']) {
        _showSuccessSnackBar(result['message']);
        // Clear form fields
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();

        // Delay navigation to let user see the success message
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) {
            Navigator.pop(context, true); // Return true to indicate success
          }
        });
      } else {
        _showErrorSnackBar(result['message']);
      }

    } catch (e) {
      setState(() {
        _isChanging = false;
      });
      _showErrorSnackBar('Terjadi kesalahan jaringan');
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
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showWarningSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: const ClassicAppBar(title: 'Ubah Password'),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              const Text('Memuat informasi pengguna...'),
              const SizedBox(height: 24),
              // Add a fallback button in case loading takes too long
              TextButton(
                onPressed: () {
                  setState(() {
                    _isLoading = false;
                    _isGoogleUser = false; // Default to regular user
                  });
                },
                child: const Text('Lewati dan lanjutkan'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const ClassicAppBar(title: 'Ubah Password'),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Info Section - berbeda untuk Google user dan regular user
            Container(
              margin: const EdgeInsets.only(bottom: 24),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _isGoogleUser ? Colors.orange.shade50 : Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _isGoogleUser ? Colors.orange.shade200 : Colors.blue.shade200,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _isGoogleUser ? Icons.info_outline : Icons.security,
                    color: _isGoogleUser ? Colors.orange.shade600 : Colors.blue.shade600,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isGoogleUser ? 'Akun Google' : 'Keamanan Password',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _isGoogleUser ? Colors.orange.shade700 : Colors.blue.shade700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _isGoogleUser
                              ? 'Anda login menggunakan akun Google. Password dikelola oleh Google dan tidak dapat diubah melalui aplikasi ini.'
                              : 'Password harus minimal 6 karakter dan mengandung huruf serta angka.',
                          style: TextStyle(
                            fontSize: 12,
                            color: _isGoogleUser ? Colors.orange.shade600 : Colors.blue.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Current Password Field
            TextFormField(
              controller: _currentPasswordController,
              obscureText: _obscureCurrentPassword,
              enabled: !_isGoogleUser, // Disable jika Google user
              decoration: InputDecoration(
                labelText: 'Password Saat Ini *',
                hintText: _isGoogleUser ? 'Tidak tersedia untuk akun Google' : 'Masukkan password saat ini',
                prefixIcon: Icon(
                  Icons.lock_outline,
                  color: _isGoogleUser ? Colors.grey.shade400 : null,
                ),
                suffixIcon: _isGoogleUser
                    ? Icon(Icons.block, color: Colors.grey.shade400)
                    : IconButton(
                  icon: Icon(
                    _obscureCurrentPassword ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureCurrentPassword = !_obscureCurrentPassword;
                    });
                  },
                ),
                border: const OutlineInputBorder(),
                filled: _isGoogleUser,
                fillColor: _isGoogleUser ? Colors.grey.shade100 : null,
              ),
              textInputAction: TextInputAction.next,
              validator: _isGoogleUser ? null : FormValidators.validateCurrentPassword,
            ),
            const SizedBox(height: 16),

            // New Password Field
            TextFormField(
              controller: _newPasswordController,
              obscureText: _obscureNewPassword,
              enabled: !_isGoogleUser, // Disable jika Google user
              decoration: InputDecoration(
                labelText: 'Password Baru *',
                hintText: _isGoogleUser ? 'Tidak tersedia untuk akun Google' : 'Masukkan password baru',
                prefixIcon: Icon(
                  Icons.lock,
                  color: _isGoogleUser ? Colors.grey.shade400 : null,
                ),
                suffixIcon: _isGoogleUser
                    ? Icon(Icons.block, color: Colors.grey.shade400)
                    : IconButton(
                  icon: Icon(
                    _obscureNewPassword ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureNewPassword = !_obscureNewPassword;
                    });
                  },
                ),
                border: const OutlineInputBorder(),
                helperText: _isGoogleUser ? null : 'Min. 6 karakter, harus ada huruf dan angka',
                filled: _isGoogleUser,
                fillColor: _isGoogleUser ? Colors.grey.shade100 : null,
              ),
              textInputAction: TextInputAction.next,
              validator: _isGoogleUser ? null : (value) => FormValidators.validateNewPassword(
                value,
                _currentPasswordController.text,
              ),
            ),
            const SizedBox(height: 16),

            // Confirm New Password Field
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: _obscureConfirmPassword,
              enabled: !_isGoogleUser, // Disable jika Google user
              decoration: InputDecoration(
                labelText: 'Konfirmasi Password Baru *',
                hintText: _isGoogleUser ? 'Tidak tersedia untuk akun Google' : 'Ulangi password baru',
                prefixIcon: Icon(
                  Icons.lock_reset,
                  color: _isGoogleUser ? Colors.grey.shade400 : null,
                ),
                suffixIcon: _isGoogleUser
                    ? Icon(Icons.block, color: Colors.grey.shade400)
                    : IconButton(
                  icon: Icon(
                    _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureConfirmPassword = !_obscureConfirmPassword;
                    });
                  },
                ),
                border: const OutlineInputBorder(),
                filled: _isGoogleUser,
                fillColor: _isGoogleUser ? Colors.grey.shade100 : null,
              ),
              textInputAction: TextInputAction.done,
              validator: _isGoogleUser ? null : (value) => FormValidators.validateConfirmPassword(
                value,
                _newPasswordController.text,
              ),
            ),
            const SizedBox(height: 32),

            // Change Password Button
            ElevatedButton(
              onPressed: _isGoogleUser || _isChanging ? null : _changePassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isGoogleUser ? Colors.grey : Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isChanging
                  ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
                  : Text(
                _isGoogleUser ? 'Tidak Dapat Diubah' : 'Ubah Password',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Cancel Button
            TextButton(
              onPressed: _isChanging ? null : () => Navigator.pop(context),
              child: const Text(
                'Kembali',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}