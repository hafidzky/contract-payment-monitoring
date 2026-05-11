import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'trend_chart.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/providers/contract_provider.dart';

class ProgressSection extends StatefulWidget {
  const ProgressSection({super.key});

  @override
  State<ProgressSection> createState() => _ProgressSectionState();
}

class _ProgressSectionState extends State<ProgressSection> {
  late DateTime _selectedMonth;

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  }

  void _previousMonth() => setState(() {
    _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
  });

  void _nextMonth() {
    final now = DateTime.now();
    if (_selectedMonth.isBefore(DateTime(now.year, now.month))) {
      setState(() {
        _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
      });
    }
  }

  DateTime? _parseDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;
    final formats = [
      DateFormat('dd MMM yyyy', 'en_US'),
      DateFormat('dd MMM yyyy'),
      DateFormat('d MMM yyyy'),
      DateFormat('dd MMMM yyyy'),
      DateFormat('d MMMM yyyy'),
    ];
    for (final fmt in formats) {
      try { return fmt.parse(dateStr); } catch (_) {}
    }
    try { return DateFormat('d-M-yyyy').parse(dateStr); } catch (_) {}
    return null;
  }

  List<double> _buildChartData(List<Map<String, dynamic>> paidTermins, double totalTarget) {
    if (totalTarget == 0) return List.filled(7, 0.0);

    final daysInMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0).day;
    final now = DateTime.now();
    final isCurrentMonth = _selectedMonth.year == now.year && _selectedMonth.month == now.month;
    final lastDay = isCurrentMonth ? now.day : daysInMonth;

    Map<int, double> dailyAccumulation = {};
    double running = 0;

    final sorted = List<Map<String, dynamic>>.from(paidTermins)
      ..sort((a, b) {
        final dateA = _parseDate(a['paid_date']?.toString());
        final dateB = _parseDate(b['paid_date']?.toString());
        if (dateA == null) return 1;
        if (dateB == null) return -1;
        return dateA.compareTo(dateB);
      });

    for (var termin in sorted) {
      final paidDate = _parseDate(termin['paid_date']?.toString());
      if (paidDate != null &&
          paidDate.month == _selectedMonth.month &&
          paidDate.year == _selectedMonth.year) {
        final cleanAmount = (termin['amount']?.toString() ?? '0')
          .replaceAll('Rp', '').replaceAll('.', '').replaceAll(',', '').trim();
        running += double.tryParse(cleanAmount) ?? 0;
        dailyAccumulation[paidDate.day] = running;
      }
    }

    return List.generate(7, (i) {
      final dayPoint = ((lastDay / 6) * i).round().clamp(1, lastDay);
      double accumulated = 0;
      for (int d = 1; d <= dayPoint; d++) {
        if (dailyAccumulation.containsKey(d)) {
          accumulated = dailyAccumulation[d]!;
        }
      }
      return (accumulated / totalTarget * 100).clamp(0.0, 100.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ContractProvider>(context);

    // Semua local variable — tidak ada state field yang di-accumulate
    double totalTarget = 0;
    double totalRealisasi = 0;
    int terminTerbayar = 0;
    int terminBulanIni = 0;
    List<Map<String, dynamic>> paidTermins = [];
    List<Map<String, dynamic>> allTerminsBulanIni = []; // ← local, bukan field

    final now = DateTime.now();
    final monthName = DateFormat('MMMM yyyy').format(_selectedMonth);
    final isCurrentMonth = _selectedMonth.year == now.year && _selectedMonth.month == now.month;

    for (var contract in provider.allContracts) {
      if (contract['termin_data'] == null) continue;
      try {
        final List<dynamic> termins = jsonDecode(contract['termin_data'].toString());
        for (var t in termins) {
          final termin = Map<String, dynamic>.from(t as Map);
          final date = _parseDate(termin['date']?.toString());

          if (date != null &&
              date.month == _selectedMonth.month &&
              date.year == _selectedMonth.year) {
            final cleanAmount = (termin['amount']?.toString() ?? '0')
              .replaceAll('Rp', '').replaceAll('.', '').replaceAll(',', '').trim();
            final value = double.tryParse(cleanAmount) ?? 0;
            totalTarget += value;
            terminBulanIni++;

            // Tambah ke local list dengan info kontrak
            allTerminsBulanIni.add({
              ...termin,
              'contract_name': contract['name'] ?? '-',
              'contract_id': contract['id'] ?? '-',
            });

            final rawIsPaid = termin['is_paid'];
            final isPaid = rawIsPaid == true || rawIsPaid == 1
              || rawIsPaid?.toString().toLowerCase() == 'true'
              || rawIsPaid?.toString() == '1'
              || termin['status']?.toString() == 'Terbayar';

            if (isPaid) {
              totalRealisasi += value;
              terminTerbayar++;
              paidTermins.add(termin);
            }
          }
        }
      } catch (e) {
        debugPrint("Error: $e");
      }
    }

    final percentage = totalTarget > 0
        ? (totalRealisasi / totalTarget).clamp(0.0, 1.0)
        : 0.0;
    final pct = percentage * 100;
    final chartData = _buildChartData(paidTermins, totalTarget);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header + filter bulan
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Realisasi Pembayaran",
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
              Row(children: [
                IconButton(
                  onPressed: _previousMonth,
                  icon: const Icon(Icons.chevron_left),
                  color: AppColors.primary,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 4),
                Text(monthName,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary)),
                const SizedBox(width: 4),
                IconButton(
                  onPressed: isCurrentMonth ? null : _nextMonth,
                  icon: const Icon(Icons.chevron_right),
                  color: isCurrentMonth ? Colors.grey.shade300 : AppColors.primary,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ]),
            ],
          ),
          const SizedBox(height: 16),

          // Persentase + icon
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text("${pct.toStringAsFixed(1)}%",
                style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: AppColors.primary)),
              Icon(percentage >= 1.0 ? Icons.check_circle : Icons.trending_up,
                color: Colors.teal.shade400, size: 32),
            ],
          ),

          const SizedBox(height: 4),
          TrendChart(data: chartData, color: Colors.teal.shade400),
          const SizedBox(height: 12),

          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: percentage, minHeight: 10,
              backgroundColor: const Color(0xFFF0F0F0),
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),

          // Target/Realisasi + badge termin (sejajar)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  "Target: ${CurrencyFormatter.toFullRupiah(totalTarget)} / Realisasi: ${CurrencyFormatter.toFullRupiah(totalRealisasi)}",
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
              const SizedBox(width: 8),
              _terminBadge(terminTerbayar, terminBulanIni, allTerminsBulanIni),
            ],
          ),
        ],
      ),
    );
  }

  Widget _terminBadge(int paid, int total, List<Map<String, dynamic>> termins) {
    final color = total == 0 ? Colors.grey
        : paid == total ? Colors.green
        : paid > 0 ? Colors.orange
        : Colors.grey;

    return GestureDetector(
      onTap: total == 0 ? null : () => _showTerminSheet(termins),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              total == 0 ? "Tidak ada termin" : "$paid dari $total termin terbayar",
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
            ),
            if (total > 0) ...[
              const SizedBox(width: 4),
              Icon(Icons.keyboard_arrow_down, size: 14, color: color),
            ],
          ],
        ),
      ),
    );
  }

  void _showTerminSheet(List<Map<String, dynamic>> termins) {
    final monthName = DateFormat('MMMM yyyy').format(_selectedMonth);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Termin Bulan Ini",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,
                            color: AppColors.primary)),
                        Text(monthName,
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text("${termins.length} termin",
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold,
                          color: AppColors.primary)),
                    ),
                  ],
                ),
              ),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  itemCount: termins.length,
                  itemBuilder: (_, i) {
                    final t = termins[i];
                    final rawIsPaid = t['is_paid'];
                    final isPaid = rawIsPaid == true || rawIsPaid == 1
                      || rawIsPaid?.toString().toLowerCase() == 'true'
                      || t['status']?.toString() == 'Terbayar';
                    final color = isPaid ? Colors.green : Colors.orange;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: color.withValues(alpha: 0.3)),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 6, offset: const Offset(0, 2))],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              isPaid ? Icons.check_circle : Icons.schedule,
                              color: color, size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(t['contract_name'] ?? '-',
                                  style: const TextStyle(fontWeight: FontWeight.bold,
                                    fontSize: 13, color: AppColors.primary)),
                                const SizedBox(height: 2),
                                Text(t['title'] ?? 'Termin',
                                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(t['amount'] ?? '-',
                                style: const TextStyle(fontSize: 13,
                                  fontWeight: FontWeight.w700, color: Colors.black87)),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(isPaid ? 'Terbayar' : 'Belum Bayar',
                                  style: TextStyle(fontSize: 10,
                                    fontWeight: FontWeight.bold, color: color)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}