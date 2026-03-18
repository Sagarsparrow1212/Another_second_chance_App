class Formatters {
  static String formatPhoneNumber(String phone) {
    // Remove all non-numeric characters
    final digits = phone.replaceAll(RegExp(r'\D'), '');

    // US format: (XXX) XXX-XXXX
    if (digits.length == 10) {
      return '(${digits.substring(0, 3)}) ${digits.substring(3, 6)}-${digits.substring(6, 10)}';
    }
    // US format with country code: +1 (XXX) XXX-XXXX
    else if (digits.length == 11 && digits.startsWith('1')) {
      return '+1 (${digits.substring(1, 4)}) ${digits.substring(4, 7)}-${digits.substring(7, 11)}';
    }

    // Return original if it doesn't match standard US lengths
    return phone;
  }
}
