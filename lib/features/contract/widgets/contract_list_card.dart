import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/contract_helper.dart';
import '../../../data/providers/contract_provider.dart';
import '../contract_detail.dart';

class ContractCard extends StatelessWidget {
  final Map<String, String> contract;
  final ContractProvider provider;
  final VoidCallback onDelete;

  const ContractCard({
    super.key,
    required this.contract,
    required this.provider,
    required this.onDelete,
  });

  String get _displayStatus {
    if (ContractHelper.isContractWarning(contract['termin_data'])) return 'Warning';
    return contract['status'] ?? 'Active';
  }

  Color get _statusColor {
    switch (_displayStatus) {
      case 'Active':   return Colors.green;
      case 'Finished': return Colors.blue;
      case 'Warning':  return Colors.orange;
      default:         return Colors.grey;
    }
  }

  IconData get _statusIcon {
    switch (_displayStatus) {
      case 'Active':   return Icons.check_circle_outline;
      case 'Finished': return Icons.task_alt;
      case 'Warning':  return Icons.warning_amber_rounded;
      default:         return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(
          color: Colors.black.withValues(alpha: 0.03),
          blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => ContractDetailPage(contractData: contract))),
        borderRadius: BorderRadius.circular(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 8, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.description_outlined,
                      color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(contract['name'] ?? '-',
                          style: const TextStyle(fontWeight: FontWeight.bold,
                            fontSize: 15, color: AppColors.primary)),
                        const SizedBox(height: 2),
                        Text('${contract['id'] ?? '-'} • ${contract['type'] ?? '-'}',
                          style: TextStyle(fontSize: 12,
                            color: Colors.grey.shade500)),
                      ],
                    ),
                  ),
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    _StatusBadge(
                      status: _displayStatus,
                      color: _statusColor,
                      icon: _statusIcon,
                    ),
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert,
                        size: 20, color: Colors.grey.shade400),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                      elevation: 3,
                      onSelected: (value) {
                        if (value == 'detail') {
                          Navigator.push(context, MaterialPageRoute(
                            builder: (_) =>
                              ContractDetailPage(contractData: contract)));
                        } else if (value == 'delete') {
                          onDelete();
                        }
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          value: 'detail',
                          child: Row(children: [
                            Icon(Icons.visibility_outlined,
                              size: 16, color: AppColors.primary),
                            const SizedBox(width: 10),
                            const Text('Lihat Detail',
                              style: TextStyle(fontSize: 13)),
                          ]),
                        ),
                        const PopupMenuDivider(),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(children: [
                            Icon(Icons.delete_outline,
                              size: 16, color: Colors.red.shade400),
                            const SizedBox(width: 10),
                            Text('Hapus Kontrak',
                              style: TextStyle(fontSize: 13,
                                color: Colors.red.shade400)),
                          ]),
                        ),
                      ],
                    ),
                  ]),
                ],
              ),
            ),
            Divider(height: 1, color: Colors.grey.shade100),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
                child: Row(
                  children: [                      // ← hapus mainAxisSize: min
                    Expanded(                      // ← bungkus dengan Expanded
                      child: _BottomInfoItem(
                        icon: Icons.account_balance_wallet_outlined,
                        iconBg: Colors.green.shade50,
                        iconColor: Colors.green.shade600,
                        label: 'Nilai Kontrak',
                        value: contract['nilai'] ?? '-',
                      ),
                    ),
                    Container(
                      width: 1, height: 32,
                      color: Colors.grey.shade200,
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    Expanded(                      // ← bungkus dengan Expanded
                      child: _BottomInfoItem(
                        icon: Icons.calendar_today_outlined,
                        iconBg: Colors.blue.shade50,
                        iconColor: Colors.blue.shade600,
                        label: 'Timeline',
                        value: contract['timeline'] ?? '-',
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  final Color color;
  final IconData icon;

  const _StatusBadge({
    required this.status,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Text(status, style: TextStyle(fontSize: 11,
          fontWeight: FontWeight.bold, color: color)),
      ]),
    );
  }
}

class _BottomInfoItem extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final String value;

  const _BottomInfoItem({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 14, color: iconColor),
        ),
        const SizedBox(width: 8),
        Flexible(                          // ← ganti Column biasa dengan Flexible
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label,
                style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
              Text(value,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                overflow: TextOverflow.ellipsis,  // ← potong jika terlalu panjang
                maxLines: 1,
              ),
            ],
          ),
        ),
      ],
    );
  }
}