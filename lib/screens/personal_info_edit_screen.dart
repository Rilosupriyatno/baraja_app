import 'package:flutter/material.dart';
import '../utils/form_validator.dart';
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

  bool _isGoogleUser = false;
  bool _isLoading = true;
  bool _isSaving = false;

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
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      setState(() => _isLoading = true);

      final userData = await UserService.getCurrentUser();

      if (userData != null) {
        // Ambil data Google user langsung dari userData tanpa request tambahan
        final isGoogle = (userData['authType']?.toString().toLowerCase() == 'google');

        setState(() {
          _usernameController.text = userData['username'] ?? '';
          _emailController.text = userData['email'] ?? '';
          _phoneController.text = userData['phone'] ?? '';
          _isGoogleUser = isGoogle;
          _isLoading = false;
        });
      } else {
        final localData = await UserService.getUserDataLocally();
        setState(() {
          _usernameController.text = localData['username'] ?? '';
          _emailController.text = localData['email'] ?? '';
          _phoneController.text = localData['phone'] ?? '';
          _isGoogleUser = localData['is_google_user'] ?? false;
          _isLoading = false;
        });
        _showWarningSnackBar('Menggunakan data offline, beberapa informasi mungkin tidak terbaru');
      }
    } catch (e) {
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

    // Client-side validation
    final validationErrors = FormValidators.validateProfileData(
      username: _usernameController.text,
      email: _isGoogleUser ? null : _emailController.text,
      phone: _phoneController.text,
      isGoogleUser: _isGoogleUser,
    );

    if (validationErrors.isNotEmpty) {
      final firstError = validationErrors.values.first;
      _showErrorSnackBar(firstError);
      return;
    }

    try {
      setState(() {
        _isSaving = true;
      });

      // Update data through API
      final result = await UserService.updateUserProfile(
        username: FormValidators.cleanInput(_usernameController.text),
        email: _isGoogleUser ? null : FormValidators.cleanInput(_emailController.text),
        phone: FormValidators.cleanInput(_phoneController.text),
      );

      setState(() {
        _isSaving = false;
      });

      if (result['success']) {
        _showSuccessSnackBar(result['message']);
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
        _isSaving = false;
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
      return const Scaffold(
        backgroundColor: Colors.white,
        appBar: ClassicAppBar(title: 'Informasi Pribadi'),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Memuat data pengguna...'),
            ],
          ),
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
                        'Anda login menggunakan Google. Email tidak dapat diubah melalui aplikasi ini.',
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
                labelText: 'Nama Pengguna *',
                hintText: 'Masukkan nama pengguna',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
                helperText: '3-30 karakter, hanya huruf, angka, titik, underscore, dan spasi',
              ),
              textInputAction: TextInputAction.next,
              validator: FormValidators.validateUsername,
            ),
            const SizedBox(height: 16),

            // Email Field
            TextFormField(
              controller: _emailController,
              enabled: !_isGoogleUser,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: _isGoogleUser ? 'Email' : 'Email',
                hintText: _isGoogleUser ? 'Email tidak dapat diubah' : 'Masukkan email (opsional)',
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
              textInputAction: TextInputAction.next,
              validator: _isGoogleUser ? null : (value) => FormValidators.validateEmail(value, required: false),
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
                helperText: '10-15 digit, format Indonesia',
              ),
              textInputAction: TextInputAction.done,
              validator: (value) => FormValidators.validatePhone(value, required: false),
            ),
            const SizedBox(height: 32),

            // Save Button
            ElevatedButton(
              onPressed: (_isSaving) ? null : _saveUserData,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isSaving
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
            const SizedBox(height: 16),

            // Cancel Button
            TextButton(
              onPressed: _isSaving ? null : () => Navigator.pop(context),
              child: const Text(
                'Batal',
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