class FormValidators {
  // Validator untuk username - matching backend validation
  static String? validateUsername(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Username tidak boleh kosong';
    }

    final trimmed = value.trim();

    if (trimmed.length < 3) {
      return 'Username harus 3-30 karakter';
    }

    if (trimmed.length > 30) {
      return 'Username harus 3-30 karakter';
    }

    // Matching backend regex: /^[a-zA-Z0-9._\s]+$/
    if (!RegExp(r'^[a-zA-Z0-9._\s]+$').hasMatch(trimmed)) {
      return 'Username hanya boleh berisi huruf, angka, titik, underscore, dan spasi';
    }

    return null;
  }

  // Validator untuk email - matching backend validation
  static String? validateEmail(String? value, {bool required = true}) {
    if (!required && (value == null || value.trim().isEmpty)) {
      return null;
    }

    if (value == null || value.trim().isEmpty) {
      return 'Email tidak boleh kosong';
    }

    final trimmed = value.trim();

    // More comprehensive email validation matching backend
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(trimmed)) {
      return 'Format email tidak valid';
    }

    return null;
  }

  // Validator untuk nomor telepon - matching backend validation
  static String? validatePhone(String? value, {bool required = false}) {
    if (!required && (value == null || value.trim().isEmpty)) {
      return null;
    }

    if (required && (value == null || value.trim().isEmpty)) {
      return 'Nomor telepon tidak boleh kosong';
    }

    if (value != null && value.trim().isNotEmpty) {
      // Hapus semua karakter selain angka untuk pengecekan
      final numbersOnly = value.replaceAll(RegExp(r'[^0-9]'), '');

      // Matching backend validation: 10-15 digits
      if (numbersOnly.length < 10) {
        return 'Nomor telepon harus 10-15 digit';
      }

      if (numbersOnly.length > 15) {
        return 'Nomor telepon harus 10-15 digit';
      }

      // Cek format nomor telepon Indonesia
      if (!RegExp(r'^(\+?62|0)[0-9\s\-()]+$').hasMatch(value.trim())) {
        return 'Format nomor telepon tidak valid';
      }
    }

    return null;
  }

  // Validator untuk password - matching backend validation exactly
  static String? validatePassword(String? value, {bool required = true}) {
    if (!required && (value == null || value.isEmpty)) {
      return null;
    }

    if (value == null || value.isEmpty) {
      return 'Password tidak boleh kosong';
    }

    // Matching backend: minimum 6 characters
    if (value.length < 6) {
      return 'Password baru minimal 6 karakter';
    }

    if (value.length > 128) {
      return 'Password maksimal 128 karakter';
    }

    // Matching backend: must contain letters
    if (!RegExp(r'[a-zA-Z]').hasMatch(value)) {
      return 'Password harus mengandung huruf';
    }

    // Matching backend: must contain numbers
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Password harus mengandung angka';
    }

    return null;
  }

  // Validator untuk konfirmasi password
  static String? validateConfirmPassword(String? value, String? originalPassword) {
    if (value == null || value.isEmpty) {
      return 'Konfirmasi password tidak boleh kosong';
    }

    if (value != originalPassword) {
      return 'Konfirmasi password tidak cocok';
    }

    return null;
  }

  // Validator untuk password baru (dengan pengecekan password lama)
  static String? validateNewPassword(String? value, String? currentPassword, {bool required = true}) {
    // Validasi password biasa
    String? passwordValidation = validatePassword(value, required: required);
    if (passwordValidation != null) {
      return passwordValidation;
    }

    // Jika password diisi, cek apakah berbeda dengan password lama
    if (value != null && value.isNotEmpty && currentPassword != null) {
      if (value == currentPassword) {
        return 'Password baru harus berbeda dengan password lama';
      }
    }

    return null;
  }

  // Validator untuk current password (for change password)
  static String? validateCurrentPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password saat ini diperlukan';
    }
    return null;
  }

  // Validator untuk alamat
  static String? validateAddress(String? value, {bool required = false}) {
    if (!required && (value == null || value.trim().isEmpty)) {
      return null;
    }

    if (required && (value == null || value.trim().isEmpty)) {
      return 'Alamat tidak boleh kosong';
    }

    if (value != null && value.trim().isNotEmpty) {
      if (value.trim().length < 10) {
        return 'Alamat minimal 10 karakter';
      }

      if (value.trim().length > 200) {
        return 'Alamat maksimal 200 karakter';
      }
    }

    return null;
  }

  // Helper method untuk format nomor telepon Indonesia
  static String formatPhoneNumber(String phone) {
    // Hapus semua karakter selain angka dan +
    String cleaned = phone.replaceAll(RegExp(r'[^0-9+]'), '');

    // Jika dimulai dengan 0, ganti dengan +62
    if (cleaned.startsWith('0')) {
      cleaned = '+62${cleaned.substring(1)}';
    }

    // Jika dimulai dengan 62, tambahkan +
    if (cleaned.startsWith('62') && !cleaned.startsWith('+62')) {
      cleaned = '+$cleaned';
    }

    return cleaned;
  }

  // Helper method untuk membersihkan input
  static String cleanInput(String? input) {
    if (input == null) return '';
    return input.trim();
  }

  // Validator untuk field yang tidak boleh diubah (untuk Google users)
  static String? validateReadOnlyField(String? value, bool isReadOnly) {
    if (isReadOnly) {
      return null; // Tidak perlu validasi untuk field read-only
    }
    return null;
  }

  // Composite validator untuk update profile
  static String? validateUpdateProfile(String field, String? value, {bool isGoogleUser = false}) {
    switch (field) {
      case 'username':
        return validateUsername(value);
      case 'email':
        return isGoogleUser ? null : validateEmail(value, required: false);
      case 'phone':
        return validatePhone(value, required: false);
      default:
        return null;
    }
  }

  // Validate all fields for profile update
  static Map<String, String> validateProfileData({
    required String username,
    String? email,
    String? phone,
    bool isGoogleUser = false,
  }) {
    Map<String, String> errors = {};

    String? usernameError = validateUsername(username);
    if (usernameError != null) {
      errors['username'] = usernameError;
    }

    if (!isGoogleUser && email != null && email.isNotEmpty) {
      String? emailError = validateEmail(email, required: false);
      if (emailError != null) {
        errors['email'] = emailError;
      }
    }

    if (phone != null && phone.isNotEmpty) {
      String? phoneError = validatePhone(phone, required: false);
      if (phoneError != null) {
        errors['phone'] = phoneError;
      }
    }

    return errors;
  }

  // Validate change password data
  static Map<String, String> validateChangePasswordData({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) {
    Map<String, String> errors = {};

    String? currentPasswordError = validateCurrentPassword(currentPassword);
    if (currentPasswordError != null) {
      errors['currentPassword'] = currentPasswordError;
    }

    String? newPasswordError = validateNewPassword(newPassword, currentPassword);
    if (newPasswordError != null) {
      errors['newPassword'] = newPasswordError;
    }

    String? confirmPasswordError = validateConfirmPassword(confirmPassword, newPassword);
    if (confirmPasswordError != null) {
      errors['confirmPassword'] = confirmPasswordError;
    }

    return errors;
  }
}