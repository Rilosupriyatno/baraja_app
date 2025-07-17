class PaymentMethodUtils {
  static String getBankName(String? method) {
    switch (method?.toLowerCase()) {
      case 'bca':
        return 'BCA';
      case 'bni':
        return 'BNI';
      case 'bri':
        return 'BRI';
      case 'mandiri':
        return 'Mandiri';
      case 'permata':
        return 'Permata';
      case 'cimb':
        return 'CIMB Niaga';
      default:
        return method?.toUpperCase() ?? 'Virtual Account';
    }
  }

  static String getPaymentMethodName(String? method) {
    switch (method?.toLowerCase()) {
      case 'bank_transfer':
        return 'Transfer Bank';
      case 'gopay':
        return 'GoPay';
      case 'shopeepay':
        return 'ShopeePay';
      case 'dana':
        return 'DANA';
      case 'ovo':
        return 'OVO';
      case 'qris':
        return 'QRIS';
      case 'cash':
        return 'Cash';
      case 'bca_va':
      case 'bni_va':
      case 'bri_va':
      case 'mandiri_va':
      case 'permata_va':
      case 'cimb_va':
        return 'Virtual Account';
      default:
        return method ?? 'Tidak diketahui';
    }
  }
}