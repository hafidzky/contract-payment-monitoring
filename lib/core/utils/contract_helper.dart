import 'dart:convert';
import 'package:intl/intl.dart';

class ContractHelper {
  // 1. Fungsi Mandiri untuk Parsing (Bisa dipakai untuk math)
  static double parseToDouble(String value) {
    String clean = value.toLowerCase().replaceAll('rp', '').replaceAll('idr', '').trim();
    String numbersOnly = clean.replaceAll('.', '');
    double amount = double.tryParse(numbersOnly.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0.0;

    if (clean.contains('juta')) {
      amount *= 1000000;
    } else if (clean.contains('miliar') || clean.contains('m')) {
      amount *= 1000000000;
    }
    return amount;
  }

  // 2. Fungsi Mandiri untuk Hitung Pembayaran (Logika Manual + Tanggal)
  static double calculatePaidAmount(String? terminJson) {
    // Validasi awal data kosong
    if (terminJson == null || terminJson.isEmpty || terminJson == '[]') return 0.0;

    try {
      List<dynamic> termins = jsonDecode(terminJson);
      double paid = 0;
      DateTime now = DateTime.now();
      DateTime today = DateTime(now.year, now.month, now.day);

      for (var t in termins) {
        bool isManualPaid = t['is_paid'] == true;
        bool isOverdue = false;

        // Cek jatuh tempo berdasarkan tanggal
        try {
          DateTime terminDate = DateFormat('dd MMM yyyy').parse(t['date']);
          isOverdue = terminDate.isBefore(today);
        } catch (_) {
          // Jika format tanggal salah, biarkan isOverdue tetap false
        }

        // Jika lunas manual atau sudah jatuh tempo, tambahkan ke total bayar
        if (isManualPaid || isOverdue) {
          paid += parseToDouble(t['amount'] ?? '0');
        }
      }
      return paid; // Pindah ke dalam blok try agar variabel 'paid' terbaca
    } catch (e) {
      return 0.0;
    }
  }

  // fungsi untuk mengecek apakah sebuah kontrak masuk kategori "Mendesak" atau tidak
  static List<Map<String, dynamic>> getUrgentTermins(String? terminJson) {
    if (terminJson == null || terminJson.isEmpty || terminJson == '[]') return [];

    List<Map<String, dynamic>> urgentList = [];
    try {
      List<dynamic> termins = jsonDecode(terminJson);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      for (var t in termins) {
        // Skip yang sudah dibayar
        final rawIsPaid = t['is_paid'];
        final isPaid = rawIsPaid == true
            || rawIsPaid == 1
            || rawIsPaid?.toString().toLowerCase() == 'true'
            || rawIsPaid?.toString() == '1'
            || t['status']?.toString() == 'Terbayar';
        if (isPaid) continue;

        DateTime? terminDate;
        try {
          terminDate = DateFormat('dd MMM yyyy').parse(t['date']);
        } catch (_) {
          try {
            terminDate = DateFormat('d-M-yyyy').parse(t['date']);
          } catch (_) {}
        }

        if (terminDate == null) continue;

        // Tampilkan hanya yang ada di bulan & tahun yang sama dengan sekarang
        if (terminDate.month == now.month && terminDate.year == now.year) {
          final daysDiff = terminDate.difference(today).inDays;
          urgentList.add({
            "daysLeft": daysDiff,   // bisa negatif jika sudah lewat hari ini
            "date": t['date'],
            "amount": t['amount'],
          });
        }
      }

      // Urutkan dari yang paling dekat jatuh tempo
      urgentList.sort((a, b) => (a['daysLeft'] as int).compareTo(b['daysLeft'] as int));

    } catch (_) {}
    return urgentList;
  }

  // warning nambah data
  static bool isContractWarning(String? terminJson) {
    if (terminJson == null || terminJson.isEmpty) return false;
    try {
      List<dynamic> termins = jsonDecode(terminJson);
      DateTime today = DateTime.now();
      DateTime todayOnly = DateTime(today.year, today.month, today.day);

      for (var t in termins) {
        if (t['is_paid'] != true) {
          try {
            String dateStr = t['date'];
            DateTime? terminDate;

            // Coba format 1: "dd MMM yyyy" (05 May 2026)
            try {
              terminDate = DateFormat('dd MMM yyyy').parse(dateStr);
            } catch (_) {
              // Coba format 2: "d-M-yyyy" (5-5-2026)
              try {
                terminDate = DateFormat('d-M-yyyy').parse(dateStr);
              } catch (_) {
                terminDate = null;
              }
            }

            if (terminDate != null) {
              int diffDays = terminDate.difference(todayOnly).inDays;
              if (diffDays <= 15) return true; 
            }
          } catch (_) {}
        }
      }
    } catch (_) {}
    return false;
  }

  static Map<String, int> getTerminSummary(String? terminJson) {
    int total = 0;
    int paid = 0;
    if (terminJson == null || terminJson.isEmpty || terminJson == '[]') {
      return {'total': 0, 'paid': 0};
    }
    try {
      final List<dynamic> termins = jsonDecode(terminJson);
      total = termins.length;
      for (var t in termins) {
        final rawIsPaid = t['is_paid'];
        final isPaid = rawIsPaid == true
            || rawIsPaid == 1
            || rawIsPaid?.toString().toLowerCase() == 'true'
            || t['status']?.toString() == 'Terbayar';
        if (isPaid) paid++;
      }
    } catch (_) {}
    return {'total': total, 'paid': paid};
  }
}