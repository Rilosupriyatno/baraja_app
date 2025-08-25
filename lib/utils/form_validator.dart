class FormValidators {
  // Validator untuk username
  static String? validateUsername(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Nama pengguna tidak boleh kosong';
    }

    if (value.trim().length < 3) {
      return 'Nama pengguna minimal 3 karakter';
    }

    if (value.trim().length > 30) {
      return 'Nama pengguna maksimal 30 karakter';
    }

    // Cek karakter yang diizinkan (huruf, angka, underscore, titik, spasi)
    if (!RegExp(r'^[a-zA-Z0-9._\s]+$').hasMatch(value.trim())) {
      return 'Nama pengguna hanya boleh berisi huruf, angka, titik, underscore, dan spasi';
    }

    return null;
  }

  // Validator untuk email
  static String? validateEmail(String? value, {bool required = true}) {
    if (!required && (value == null || value.trim().isEmpty)) {
      return null;
    }

    if (value == null || value.trim().isEmpty) {
      return 'Email tidak boleh kosong';
    }

    // Regex pattern untuk validasi email yang lebih ketat
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(value.trim())) {
      return 'Format email tidak valid';
    }

    return null;
  }

  // Validator untuk nomor telepon
  static String? validatePhone(String? value, {bool required = false}) {
    if (!required && (value == null || value.trim().isEmpty)) {
      return null;
    }

    if (required && (value == null || value.trim().isEmpty)) {
      return 'Nomor telepon tidak boleh kosong';
    }

    if (value != null && value.isNotEmpty) {
      // Hapus semua karakter selain angka untuk pengecekan
      final numbersOnly = value.replaceAll(RegExp(r'[^0-9]'), '');

      if (numbersOnly.length < 10) {
        return 'Nomor telepon minimal 10 digit';
      }

      if (numbersOnly.length > 15) {
        return 'Nomor telepon maksimal 15 digit';
      }

      // Cek format nomor telepon Indonesia
      if (!RegExp(r'^(\+?62|0)[0-9\s\-()]+$').hasMatch(value.trim())) {
        return 'Format nomor telepon tidak valid';
      }
    }

    return null;
  }

  // Validator untuk password
  static String? validatePassword(String? value, {bool required = true}) {
    if (!required && (value == null || value.isEmpty)) {
      return null;
    }

    if (value == null || value.isEmpty) {
      return 'Password tidak boleh kosong';
    }

    if (value.length < 6) {
      return 'Password minimal 6 karakter';
    }

    if (value.length > 128) {
      return 'Password maksimal 128 karakter';
    }

    // Cek apakah mengandung minimal satu huruf
    if (!RegExp(r'[a-zA-Z]').hasMatch(value)) {
      return 'Password harus mengandung minimal satu huruf';
    }

    // Cek apakah mengandung minimal satu angka
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Password harus mengandung minimal satu angka';
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

  // Helper method untuk format nomor telepon
  static String formatPhoneNumber(String phone) {
    // Hapus semua karakter selain angka dan +
    String cleaned = phone.replaceAll(RegExp(r'[^0-9+]'), '');

    // Jika dimulai dengan 0, ganti dengan +62
    if (cleaned.startsWith('0')) {
      cleaned = '+62' + cleaned.substring(1);
    }

    // Jika dimulai dengan 62, tambahkan +
    if (cleaned.startsWith('62') && !cleaned.startsWith('+62')) {
      cleaned = '+' + cleaned;
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
}