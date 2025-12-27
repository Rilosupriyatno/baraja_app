/// App Configuration for Discount Settings
/// 
/// Change this value to enable/disable discount prices globally.
/// - true: Use discounted prices (if available)
/// - false: Use original prices only
/// 
/// After changing, rebuild and deploy to production.

class AppConfig {
  /// Toggle untuk mengaktifkan/menonaktifkan harga diskon
  /// 
  /// Set ke `true` untuk menampilkan harga diskon
  /// Set ke `false` untuk selalu menggunakan harga asli
  static const bool useDiscountPrice = false;  // ✅ DISABLED - tampilkan harga asli
}
