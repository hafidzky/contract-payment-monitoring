import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'contract_detail.dart';
import '../../data/providers/contract_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/contract_helper.dart';

class ContractValuePage extends StatelessWidget {
  const ContractValuePage({super.key});

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isDesktop = screenWidth > 1100;

    return Consumer<ContractProvider>(
      builder: (context, provider, child) {
        final allContracts = provider.allContracts;

        // ── Hitung total finansial dari semua kontrak
        double totalNilaiAktif = 0;
        double totalSisaSeluruhKontrak = 0;

        for (var c in allContracts) {
          final double nilaiTotal =
              CurrencyFormatter.parseToDouble(c['nilai'] ?? '0');
          final double paidAmount =
              ContractHelper.calculatePaidAmount(c['termin_data']);

          final String status = c['status'] ?? 'Active';
          if (status == 'Active' || status == 'Warning') {
            totalNilaiAktif += nilaiTotal;
          }

          totalSisaSeluruhKontrak += (nilaiTotal - paidAmount);
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF8F9FF),
          appBar: AppBar(
            title: const Text(
              'Rincian Nilai Kontrak',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          body: Column(
            children: [
              _buildFinancialHeader(
                totalNilaiAktif,
                totalSisaSeluruhKontrak,
                allContracts.length,
              ),
              Expanded(
                child: allContracts.isEmpty
                    ? const Center(
                        child: Text('Belum ada data kontrak.'),
                      )
                    : isDesktop
                        ? GridView.builder(
                            padding: const EdgeInsets.all(24),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 20,
                              mainAxisSpacing: 20,
                              childAspectRatio: 3.2,
                            ),
                            itemCount: allContracts.length,
                            itemBuilder: (context, index) =>
                                _buildValueCard(context, allContracts[index]),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                            itemCount: allContracts.length,
                            itemBuilder: (context, index) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _buildValueCard(
                                  context, allContracts[index]),
                            ),
                          ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Header total finansial
  Widget _buildFinancialHeader(
      double totalAktif, double totalSisa, int count) {
    return Container(
      width: double.infinity,
      color: AppColors.primary,
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Total Nilai Aktif
          const Text(
            'Total Nilai Kontrak Aktif',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 2),
          FittedBox(
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

          // Total Sisa Komitmen
          const Text(
            'Total Sisa Komitmen',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 2),
          FittedBox(
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

  // ── Card per kontrak
  Widget _buildValueCard(BuildContext context, Map<String, String> data) {
    final double totalValue =
        CurrencyFormatter.parseToDouble(data['nilai'] ?? '0');
    final double paidAmount =
        ContractHelper.calculatePaidAmount(data['termin_data']);
    final double paidPercent =
        totalValue > 0 ? (paidAmount / totalValue).clamp(0.0, 1.0) : 0.0;
    final double remainingAmount = totalValue - paidAmount;

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
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ContractDetailPage(contractData: data),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // ── Baris atas: nama vendor + total nilai
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data['name'] ?? 'Vendor Tidak Diketahui',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: AppColors.primary,
                            ),
                          ),
                          Text(
                            data['type'] ?? 'General',
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          data['nilai'] ?? 'Rp 0',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                            color: Colors.green,
                          ),
                        ),
                        const Text(
                          'Total Value',
                          style: TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Progress bar
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
                    Text(
                      '${(paidPercent * 100).toInt()}%',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // ── Terbayar & Sisa Komitmen
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _subValueInfo(
                      'TERBAYAR',
                      CurrencyFormatter.toFullRupiah(paidAmount),
                    ),
                    _subValueInfo(
                      'SISA KOMITMEN',
                      CurrencyFormatter.toFullRupiah(remainingAmount),
                      isBold: true,
                    ),
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
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.grey,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}