import 'package:intl/intl.dart';

class CurrencyFormatter {
  static String toFullRupiah(dynamic value) {
    if (value == null) return "Rp 0";

    double amount = 0;
    if (value is String) {
      String clean = value.toLowerCase().replaceAll('rp', '').replaceAll('idr', '').trim();
      String cleanAmount = clean.replaceAll(RegExp(r'[^0-9]'), ''); 
      amount = double.tryParse(cleanAmount) ?? 0.0;

      if (clean.contains('juta')) {
        amount *= 1000000;
      } else if (clean.contains('miliar') || clean.contains('m')) {
        amount *= 1000000000;
      }
    } else {
      amount = value.toDouble();
    }

    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(amount);
  }

  static String toShort(dynamic value) {
    double num = 0;
    if (value is double) {
      num = value;
    } else {
      String clean = value.toString()
        .replaceAll('Rp', '').replaceAll('.', '')
        .replaceAll(',', '').trim();
      num = double.tryParse(clean) ?? 0;
    }

    if (num >= 1000000000000) {
      return "Rp ${(num / 1000000000000).toStringAsFixed(1)} T";  // Triliun
    } else if (num >= 1000000000) {
      return "Rp ${(num / 1000000000).toStringAsFixed(1)} M";  // Miliar
    } else if (num >= 1000000) {
      return "Rp ${(num / 1000000).toStringAsFixed(1)} Jt";  // juta
    } else {
      return "Rp ${num.toStringAsFixed(0)}";
    }
  }
}