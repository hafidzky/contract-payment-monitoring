// Lokasi: lib/pages/contract/widgets/log_list_widget.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/providers/contract_provider.dart';
import '../../core/constants/app_colors.dart';

class LogListWidget extends StatelessWidget {
  final String contractId; // Butuh ID untuk mencari data di provider

  const LogListWidget({super.key, required this.contractId});

  @override
  Widget build(BuildContext context) {
    // Membaca data langsung dari provider berdasarkan contractId
    final logs = context.watch<ContractProvider>().getLogsForContract(contractId);

    if (logs.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.history, size: 48, color: Colors.grey.shade300),
              const SizedBox(height: 12),
              Text('Belum ada aktivitas', style: TextStyle(color: Colors.grey.shade400)),
            ],
          ),
        ),
      );
    }

    return Column(
      children: List.generate(logs.length, (i) {
        final log = logs[i];
        final iconData = _logIcon(log.icon);
        final iconColor = _logColor(log.icon);
        return Column(
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                radius: 18,
                backgroundColor: iconColor.withValues(alpha: 0.12),
                child: Icon(iconData, size: 16, color: iconColor),
              ),
              title: Text(log.activity,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              trailing: Text(log.time,
                  style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ),
            if (i < logs.length - 1) const Divider(),
          ],
        );
      }),
    );
  }

  // Fungsi helper ikut dipindahkan ke sini
  IconData _logIcon(String type) {
    switch (type) {
      case 'payment': return Icons.payments;
      case 'document': return Icons.attach_file;
      case 'create': return Icons.add_circle;
      default: return Icons.edit;
    }
  }

  Color _logColor(String type) {
    switch (type) {
      case 'payment': return Colors.green;
      case 'document': return Colors.blue;
      case 'create': return AppColors.primary;
      default: return Colors.orange;
    }
  }
}