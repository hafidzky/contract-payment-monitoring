import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../data/providers/contract_provider.dart';
import '../contract/contract_detail.dart';

// Model alert
class _AlertItem {
  final String type;       // 'critical' | 'warning' | 'success' | 'info'
  final String title;
  final String message;
  final String time;
  final int priority;      // urutan tampil (kecil = atas)
  final Map<String, String>? contractData; // untuk navigasi ke detail

  const _AlertItem({
    required this.type,
    required this.title,
    required this.message,
    required this.time,
    required this.priority,
    this.contractData,
  });
}

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  String _filter = 'Semua'; 

  // Parse tanggal dari berbagai format
  DateTime? _parseDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;
    final formats = [
      DateFormat('dd MMM yyyy', 'en_US'),
      DateFormat('dd MMM yyyy'),
      DateFormat('d MMM yyyy'),
    ];
    for (final fmt in formats) {
      try { return fmt.parse(dateStr); } catch (_) {}
    }
    try { return DateFormat('d-M-yyyy').parse(dateStr); } catch (_) {}
    return null;
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '-';
    final date = _parseDate(dateStr);
    if (date == null) return dateStr;
    return DateFormat('dd MMM yyyy', 'en_US').format(date);
  }

  // Generate alert otomatis dari semua kontrak
  List<_AlertItem> _buildAlerts(List<Map<String, String>> contracts) {
    final List<_AlertItem> alerts = [];
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

    for (final contract in contracts) {
      final name = contract['name'] ?? 'Vendor';
      final id   = contract['id'] ?? '-';
      final terminJson = contract['termin_data'];
      if (terminJson == null) continue;

      try {
        final termins = jsonDecode(terminJson) as List<dynamic>;

        for (int i = 0; i < termins.length; i++) {
          final t       = Map<String, dynamic>.from(termins[i] as Map);
          final date    = _parseDate(t['date']?.toString());
          if (date == null) continue;

          final rawIsPaid = t['is_paid'];
          final isPaid = rawIsPaid == true
              || rawIsPaid == 1
              || rawIsPaid?.toString().toLowerCase() == 'true'
              || t['status']?.toString() == 'Terbayar';

          final diffDays = date.difference(today).inDays;
          final terminLabel = t['title'] ?? 'Termin ${i + 1}';
          final amount = t['amount'] ?? '-';

          if (isPaid) {
            // Alert sukses — sudah terbayar
            final paidDate = t['paid_date']?.toString();
            alerts.add(_AlertItem(
              type:         'success',
              title:        '$name — $terminLabel Terbayar',
              message:      '$terminLabel senilai $amount telah dikonfirmasi lunas.'
                  '${paidDate != null ? ' Dibayar: $paidDate.' : ''}',
              time:         _formatDate(paidDate),
              priority:     3,
              contractData: contract,
            ));
      } else if (diffDays < -7) {
        // OVERDUE — melewati masa peringatan (lebih dari 7 hari)
            alerts.add(_AlertItem(
              type:         'critical',
              title:        '$name — $terminLabel OVERDUE',
              message:      '$terminLabel senilai $amount telah melewati jatuh tempo '
                  'dan terlewat ${diffDays.abs()} hari (${t['date']}). Segera tindaklanjuti!',
              time: _formatDate(t['date']?.toString()),
              priority:     0,
              contractData: contract,
            ));
          } else if (diffDays < 0) {
            // WARNING — masa peringatan (1 s.d 7 hari setelah termin)
            alerts.add(_AlertItem(
              type:         'warning',
              title:        '$name — Peringatan Pembayaran',
              message:      '$terminLabel senilai $amount telah melewati jadwal termin '
                  '(${t['date']}). Tersisa ${7 - diffDays.abs()} hari sebelum status menjadi Overdue.',
              time: _formatDate(t['date']?.toString()),
              priority:     1,
              contractData: contract,
            ));
          } else if (diffDays <= 7) {
            // CRITICAL — 0-7 hari
            alerts.add(_AlertItem(
              type:         'critical',
              title:        '$name — H-$diffDays Jatuh Tempo',
              message:      '$terminLabel senilai $amount akan jatuh tempo '
                  '${diffDays == 0 ? "HARI INI" : "dalam $diffDays hari"} '
                  '(${t['date']}). Segera proses pembayaran.',
              time: _formatDate(t['date']?.toString()),
              priority:     1,
              contractData: contract,
            ));
          } else if (diffDays <= 15) {
            // WARNING — 8-15 hari
            alerts.add(_AlertItem(
              type:         'warning',
              title:        '$name — Mendekati Jatuh Tempo',
              message:      '$terminLabel senilai $amount akan jatuh tempo '
                  'dalam $diffDays hari (${t['date']}). Persiapkan pembayaran.',
              time: _formatDate(t['date']?.toString()),
              priority:     2,
              contractData: contract,
            ));
          }
        }

        // Alert kontrak baru (status Active, belum ada termin terbayar)
        final allUnpaid = termins.every((t) {
          final raw = t['is_paid'];
          return raw != true && raw != 1
              && raw?.toString().toLowerCase() != 'true'
              && t['status']?.toString() != 'Terbayar';
        });
        if (allUnpaid && contract['status'] == 'Active') {
          alerts.add(_AlertItem(
            type:         'info',
            title:        'Kontrak Aktif — $name',
            message:      'Kontrak #$id sedang berjalan. '
                '${termins.length} termin pembayaran terjadwal.',
            time:          _formatDate(contract['timeline']?.split(' - ').first),
            priority:     4,
            contractData: contract,
          ));
        }

      } catch (e) {
        debugPrint('Error build alert: $e');
      }
    }

    // Sort: priority kecil di atas, lalu alphabetical
    alerts.sort((a, b) => a.priority.compareTo(b.priority));
    return alerts;
  }

  List<_AlertItem> _applyFilter(List<_AlertItem> all) {
    switch (_filter) {
      case 'Kritis':  return all.where((a) => a.type == 'critical').toList();
      case 'Warning': return all.where((a) => a.type == 'warning').toList();
      case 'Info':    return all.where((a) => a.type == 'success' || a.type == 'info').toList();
      default:        return all;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ContractProvider>(context);
    final allAlerts     = _buildAlerts(provider.allContracts);
    final filtered      = _applyFilter(allAlerts);
    final criticalCount = allAlerts.where((a) => a.type == 'critical').length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          _buildFilterBar(allAlerts),  // ← filter chips dulu
          
          if (criticalCount > 0)       // ← banner di bawah chips
            Container(
              margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(children: [
                Icon(Icons.warning_rounded, size: 16, color: Colors.red.shade700),
                const SizedBox(width: 8),
                Text('$criticalCount alert kritis memerlukan perhatian segera',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                    color: Colors.red.shade700)),
              ]),
            ),

          Expanded(
            child: filtered.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) => _buildAlertCard(filtered[i]),
                  ),
          ),
        ],
      ),
    );
  }

  // --- FILTER BAR ---
  Widget _buildFilterBar(List<_AlertItem> all) {
    final criticalCount = all.where((a) => a.type == 'critical').length;
    final warningCount  = all.where((a) => a.type == 'warning').length;

    final filters = [
      ('Semua',   all.length,      AppColors.primary),
      ('Kritis',  criticalCount,   Colors.red),
      ('Warning', warningCount,    Colors.orange),
      ('Info',    all.length - criticalCount - warningCount, Colors.teal),
    ];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.map((f) {
            final isSelected = _filter == f.$1;
            return GestureDetector(
              onTap: () => setState(() => _filter = f.$1),
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? f.$3 : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? f.$3 : Colors.grey.shade300),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(f.$1,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : Colors.grey.shade600,
                    )),
                  if (f.$2 > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white.withValues(alpha: 0.3)
                            : f.$3.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('${f.$2}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : f.$3,
                        )),
                    ),
                  ],
                ]),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // --- ALERT CARD ---
  Widget _buildAlertCard(_AlertItem alert) {
    final config = _getTypeConfig(alert.type);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: config['borderColor'] as Color),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6, offset: const Offset(0, 2))
        ],
      ),
      child: InkWell(
        onTap: alert.contractData != null
            ? () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => ContractDetailPage(contractData: alert.contractData!)))
            : null,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: config['bgColor'] as Color,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(config['icon'] as IconData,
                  color: config['color'] as Color, size: 20),
              ),
              const SizedBox(width: 14),

              // Konten
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(alert.title,
                            style: const TextStyle(fontWeight: FontWeight.bold,
                              fontSize: 14, color: Colors.black87)),
                        ),
                        const SizedBox(width: 8),
                        Text(alert.time,
                          style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(alert.message,
                      style: const TextStyle(fontSize: 12, color: Colors.black54,
                        height: 1.4)),
                    if (alert.contractData != null) ...[
                      const SizedBox(height: 8),
                      Row(children: [
                        Text('Lihat Detail Kontrak',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold,
                            color: config['color'] as Color)),
                        const SizedBox(width: 4),
                        Icon(Icons.arrow_forward, size: 12,
                          color: config['color'] as Color),
                      ]),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Map<String, dynamic> _getTypeConfig(String type) {
    switch (type) {
      case 'critical':
        return {
          'icon':        Icons.warning_rounded,
          'color':       Colors.red.shade700,
          'bgColor':     Colors.red.shade50,
          'borderColor': Colors.red.shade100,
        };
      case 'warning':
        return {
          'icon':        Icons.access_time_rounded,
          'color':       Colors.orange.shade700,
          'bgColor':     Colors.orange.shade50,
          'borderColor': Colors.orange.shade100,
        };
      case 'success':
        return {
          'icon':        Icons.check_circle_rounded,
          'color':       Colors.teal.shade700,
          'bgColor':     Colors.teal.shade50,
          'borderColor': Colors.teal.shade100,
        };
      default: // info
        return {
          'icon':        Icons.info_rounded,
          'color':       Colors.blue.shade700,
          'bgColor':     Colors.blue.shade50,
          'borderColor': Colors.blue.shade100,
        };
    }
  }

  // --- EMPTY STATE ---
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.notifications_off_outlined,
              size: 48, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 16),
          Text('Tidak ada alert $_filter',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500,
              color: Colors.grey.shade500)),
          const SizedBox(height: 8),
          Text('Semua kontrak dalam kondisi baik.',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade400)),
        ],
      ),
    );
  }
}