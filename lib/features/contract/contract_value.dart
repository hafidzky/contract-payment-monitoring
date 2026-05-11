import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:convert';

import 'contract_detail.dart';
import '../../data/providers/contract_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';

class ContractValuePage extends StatelessWidget {
  const ContractValuePage({super.key});

  // --- 1. MESIN PINTAR: MENGUBAH TEKS KE ANGKA ASLI ---
  double _parseNilaiKeAngka(String nilaiStr) {
    try {
      // Membersihkan simbol mata wang dan jarak
      String clean = nilaiStr.toLowerCase().replaceAll('rp', '').replaceAll('idr', '').trim();
      
      // Menghapus titik ribuan agar boleh di-parse sebagai double
      String numbersOnly = clean.replaceAll('.', '');
      double basis = double.tryParse(numbersOnly) ?? 0.0;
      
      // Logika untuk menangani unit Juta atau Miliar
      if (clean.contains('juta')) return basis * 1000000;
      if (clean.contains('m') || clean.contains('miliar')) return basis * 1000000000;
      
      return basis;
    } catch (e) {
      return 0.0;
    }
  }

  // --- 2. HITUNG REALISASI BERDASARKAN TERMIN (SINKRON DENGAN FITUR EDIT) ---
  Map<String, double> _calculateRealProgress(String? terminJson, double totalValue) {
    if (terminJson == null || terminJson.isEmpty || terminJson == '[]') {
      return {"paid": 0.0, "percent": 0.0};
    }

    try {
      List<dynamic> termins = jsonDecode(terminJson);
      double paidAmount = 0;
      DateTime now = DateTime.now();
      DateTime today = DateTime(now.year, now.month, now.day);

      for (var t in termins) {
        // PRIORITAS 1: Semak jika sudah ditanda Lunas secara manual
        bool isManualPaid = t['is_paid'] == true;
        if (isManualPaid) {
          paidAmount += _parseNilaiKeAngka(t['amount'] ?? '0');
        } else {
          // PRIORITAS 2: Semak automatik berdasarkan tarikh jatuh tempo
          try {
            DateTime terminDate = DateFormat('dd MMM yyyy').parse(t['date']);
            if (terminDate.isBefore(today)) {
              paidAmount += _parseNilaiKeAngka(t['amount'] ?? '0');
            }
          } catch (_) {}
        }
      }

      double percent = totalValue > 0 ? (paidAmount / totalValue) : 0.0;
      
      // Memastikan peratusan tidak melebihi 100%
      if (percent > 1.0) percent = 1.0;
      
      return {"paid": paidAmount, "percent": percent};
    } catch (e) {
      return {"paid": 0.0, "percent": 0.0};
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isDesktop = screenWidth > 1100;

    return Consumer<ContractProvider>(
      builder: (context, provider, child) {
        final allContracts = provider.allContracts;

        // --- HITUNG TOTAL SISA KOMITMEN & TOTAL AKTIF ---
        double totalSisaSeluruhKontrak = 0;
        double totalNilaiAktif = 0;

        for (var c in allContracts) {
          double nilaiTotal = _parseNilaiKeAngka(c['nilai'] ?? '0');
          
          // Tambahkan ke Total Aktif jika statusnya berjalan (Active / Warning)
          String status = c['status'] ?? 'Active';
          if (status == 'Active' || status == 'Warning') {
            totalNilaiAktif += nilaiTotal;
          }

          var progress = _calculateRealProgress(c['termin_data'], nilaiTotal);
          // Baki = Nilai Total - Jumlah yang telah dibayar
          totalSisaSeluruhKontrak += (nilaiTotal - progress['paid']!);
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF8F9FF),
          appBar: AppBar(
            title: const Text("Rincian Nilai Kontrak", style: TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0, 
          ),
          body: Column(
            children: [
              _buildFinancialHeader(totalNilaiAktif, totalSisaSeluruhKontrak, allContracts.length),
              
            Expanded(
              child: allContracts.isEmpty
                  ? const Center(child: Text("Belum ada data kontrak."))
                  : isDesktop
                      // ── DESKTOP: GridView 2 kolom ──
                      ? GridView.builder(
                          padding: const EdgeInsets.all(24),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 20,
                            mainAxisSpacing: 20,
                            childAspectRatio: 3.2,
                          ),
                          itemCount: allContracts.length,
                          itemBuilder: (context, index) =>
                              _buildValueCard(context, allContracts[index]),
                        )
                      // ── MOBILE: ListView biasa ──
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                          itemCount: allContracts.length,
                          itemBuilder: (context, index) =>
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _buildValueCard(context, allContracts[index]),
                              ),
                        ),
            ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFinancialHeader(double totalAktif, double totalSisa, int count) {
    return Container(
      width: double.infinity,
      color: AppColors.primary,
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nilai Aktif
          const Text('Total Nilai Kontrak Aktif',
            style: TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 2),
          FittedBox(                          // ← agar teks besar menyesuaikan lebar layar
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              CurrencyFormatter.toFullRupiah(totalAktif),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Sisa Komitmen
          const Text('Total Sisa Komitmen',
            style: TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 2),
          FittedBox(                          // ← sama
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              CurrencyFormatter.toFullRupiah(totalSisa),
              style: const TextStyle(
                color: Colors.orangeAccent,
                fontSize: 26,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 12),

          Text(
            'Berdasarkan $count Kontrak Terdaftar',
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 11,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildValueCard(BuildContext context, Map<String, String> data) {
    double totalValueRaw = _parseNilaiKeAngka(data['nilai'] ?? '0');
    
    // HITUNG PROGRES BERDASARKAN DATA TERMIN (FLAG IS_PAID + TARIKH)
    var progressData = _calculateRealProgress(data['termin_data'], totalValueRaw);
    
    double paidAmount = progressData["paid"]!;
    double paidPercent = progressData["percent"]!;
    double remainingAmount = totalValueRaw - paidAmount;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300, width: 1.5),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ContractDetailPage(contractData: data))),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(data['name'] ?? 'Vendor Tidak Diketahui',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary)),
                          Text(data['type'] ?? 'General', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(data['nilai'] ?? 'Rp 0',
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.green)),
                        const Text("Total Value", style: TextStyle(fontSize: 13, color: Colors.grey)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: paidPercent,
                          backgroundColor: Colors.grey.shade100,
                          color: AppColors.primary,
                          minHeight: 8,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text("${(paidPercent * 100).toInt()}%",
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _subValueInfo("TERBAYAR", CurrencyFormatter.toFullRupiah(paidAmount)),
                    _subValueInfo("SISA KOMITMEN", CurrencyFormatter.toFullRupiah(remainingAmount), isBold: true),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _subValueInfo(String label, String value, {bool isBold = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: isBold ? FontWeight.bold : FontWeight.w500, color: Colors.black87)),
      ],
    );
  }
}