import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/utils/classic_app_bar.dart';
import '../services/user_service.dart';

class PersonalInfoEditScreen extends StatefulWidget {
  const PersonalInfoEditScreen({super.key});

  @override
  State<PersonalInfoEditScreen> createState() => _PersonalInfoEditScreenState();
}

class _PersonalInfoEditScreenState extends State<PersonalInfoEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isGoogleUser = false;
  bool _isLoading = true;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      // Coba ambil data dari API terlebih dahulu
      final userData = await UserService.getCurrentUser();

      if (userData != null) {
        // Simpan ke local storage
        await UserService.saveUserDataLocally(userData);

        setState(() {
          _usernameController.text = userData['username'] ?? '';
          _emailController.text = userData['email'] ?? '';
          _phoneController.text = userData['phone'] ?? '';
          _isGoogleUser = userData['password'] == '-' || userData['password'] == null;
          _isLoading = false;
        });
      } else {
        // Fallback ke data lokal jika API gagal
        final localData = await UserService.getUserDataLocally();

        setState(() {
          _usernameController.text = localData['username'] ?? '';
          _emailController.text = localData['email'] ?? '';
          _phoneController.text = localData['phone'] ?? '';
          _isGoogleUser = localData['is_google_user'] ?? false;
          _isLoading = false;
        });
      }
    } catch (e) {
      // Jika ada error, coba gunakan data lokal
      final localData = await UserService.getUserDataLocally();

      setState(() {
        _usernameController.text = localData['username'] ?? '';
        _emailController.text = localData['email'] ?? '';
        _phoneController.text = localData['phone'] ?? '';
        _isGoogleUser = localData['is_google_user'] ?? false;
        _isLoading = false;
      });

      _showErrorSnackBar('Gagal memuat data dari server, menggunakan data lokal');
    }
  }

  Future<void> _saveUserData() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });

      // Update data melalui API
      bool success = await UserService.updateUserProfile(
        username: _usernameController.text,
        email: _isGoogleUser ? null : _emailController.text,
        phone: _phoneController.text.isEmpty ? null : _phoneController.text,
      );

      if (success) {
        // Update local storage juga
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('username', _usernameController.text);
        await prefs.setString('phone', _phoneController.text);

        if (!_isGoogleUser) {
          await prefs.setString('email', _emailController.text);

          // Update password jika diisi
          if (_passwordController.text.isNotEmpty) {
            // Note: Password update harus dilakukan di screen terpisah untuk keamanan
            await prefs.setString('password', _passwordController.text);
          }
        }

        setState(() {
          _isLoading = false;
        });

        _showSuccessSnackBar('Data berhasil diperbarui');
        Navigator.pop(context);
      } else {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar('Gagal memperbarui data di server');
      }

    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Terjadi kesalahan jaringan');
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: const ClassicAppBar(title: 'Informasi Pribadi'),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const ClassicAppBar(title: 'Informasi Pribadi'),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Info untuk Google User
            if (_isGoogleUser)
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue.shade600),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Anda login menggunakan Google. Email dan password tidak dapat diubah.',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Username Field
            TextFormField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Nama Pengguna',
                hintText: 'Masukkan nama pengguna',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Nama pengguna tidak boleh kosong';
                }
                if (value.trim().length < 3) {
                  return 'Nama pengguna minimal 3 karakter';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Email Field
            TextFormField(
              controller: _emailController,
              enabled: !_isGoogleUser,
              decoration: InputDecoration(
                labelText: 'Email',
                hintText: _isGoogleUser ? 'Email tidak dapat diubah' : 'Masukkan email',
                prefixIcon: Icon(
                  Icons.email,
                  color: _isGoogleUser ? Colors.grey : null,
                ),
                border: const OutlineInputBorder(),
                fillColor: _isGoogleUser ? Colors.grey.shade100 : null,
                filled: _isGoogleUser,
              ),
              style: TextStyle(
                color: _isGoogleUser ? Colors.grey : Colors.black,
              ),
              validator: _isGoogleUser ? null : (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Email tidak boleh kosong';
                }
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                  return 'Format email tidak valid';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Phone Field
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Nomor Telepon',
                hintText: 'Masukkan nomor telepon (opsional)',
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  if (!RegExp(r'^[0-9+\-\s()]+$').hasMatch(value)) {
                    return 'Format nomor telepon tidak valid';
                  }
                  if (value.replaceAll(RegExp(r'[^0-9]'), '').length < 10) {
                    return 'Nomor telepon minimal 10 digit';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Password Section - hanya untuk non-Google user
            if (!_isGoogleUser) ...[
              const Divider(),
              const SizedBox(height: 16),
              Text(
                'Ubah Password (Opsional)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
              ),
              const SizedBox(height: 16),

              // New Password Field
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Password Baru',
                  hintText: 'Kosongkan jika tidak ingin mengubah password',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    if (value.length < 6) {
                      return 'Password minimal 6 karakter';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Confirm Password Field
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                decoration: InputDecoration(
                  labelText: 'Konfirmasi Password Baru',
                  hintText: 'Ulangi password baru',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
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
                ),
                validator: (value) {
                  if (_passwordController.text.isNotEmpty) {
                    if (value != _passwordController.text) {
                      return 'Konfirmasi password tidak cocok';
                    }
                  }
                  return null;
                },
              ),
            ],

            const SizedBox(height: 32),

            // Save Button
            ElevatedButton(
              onPressed: _isLoading ? null : _saveUserData,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
                  : const Text(
                'Simpan Perubahan',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}