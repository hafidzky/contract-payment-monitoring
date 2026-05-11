import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/utils/contract_helper.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/providers/contract_provider.dart';
import '../../contract/contract_detail.dart';

class UrgencySection extends StatelessWidget {
  final bool isDesktop;
  const UrgencySection({super.key, required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ContractProvider>(context);
    List<Widget> urgentWidgets = [];

    for (var contract in provider.allContracts) {
      // Perbaikan: Hapus kata kunci 'final' agar variabel bisa diisi nilainya di dalam blok if-else
      String timeLabel = "";
      Color itemColor = Colors.grey;
      
      var urgents = ContractHelper.getUrgentTermins(contract['termin_data']);
      for (var u in urgents) {
        final cleanU = Map<String, dynamic>.from(u as Map);
        int daysLeft = cleanU['daysLeft'] ?? 0;

        if (daysLeft < 0) {
          // Sudah lewat jatuh tempo
          timeLabel = "TERLAMBAT ${daysLeft.abs()} HARI";
          itemColor = Colors.red.shade800;
        } else if (daysLeft == 0) {
          timeLabel = "JATUH TEMPO HARI INI";
          itemColor = AppColors.error;
        } else {
          timeLabel = "H-$daysLeft JATUH TEMPO";
          itemColor = daysLeft <= 7 ? AppColors.error : Colors.orange;
        }

        urgentWidgets.add(_urgencyItem(
          context,
          contract['name'] ?? "Vendor Tidak Diketahui",
          timeLabel,
          itemColor,
          contract,
        ));

        urgentWidgets.add(const SizedBox(height: 12));
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F5FF), 
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: const [
            Icon(Icons.error_outline, color: AppColors.error, size: 20),
            SizedBox(width: 8),
            Text(
              "Deadline Bulan Ini", 
              style: TextStyle(
                fontWeight: FontWeight.bold, 
                fontSize: 20, 
                color: AppColors.primary,
              ),
            ),
          ]),
          const SizedBox(height: 16),
          if (urgentWidgets.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  "Tidak ada pembayaran mendesak saat ini.",
                  style: TextStyle(
                    color: Colors.black54, 
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            )
          else
            Column(children: urgentWidgets),
        ],
      ),
    );
  }

  Widget _urgencyItem(BuildContext context, String vendor, String time, Color color, Map<String, dynamic> contractData) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.05), 
            blurRadius: 10, 
            offset: const Offset(0, 4),
          )
        ],
        border: Border(left: BorderSide(color: color, width: 6)),
      ),
      child: isDesktop
          ? Row(children: [
              Expanded(child: _urgencyText(vendor, time, color)),
              const SizedBox(width: 12),
              _urgencyButton(context, contractData),
            ])
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start, 
              children: [
                _urgencyText(vendor, time, color),
                const SizedBox(height: 12),
                _urgencyButton(context, contractData),
              ],
            ),
    );
  }

  Widget _urgencyText(String vendor, String time, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start, 
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15), 
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
          ),
          child: Text(
            time.toUpperCase(), 
            style: TextStyle(
              color: color, 
              fontSize: 11, 
              fontWeight: FontWeight.w800, 
              letterSpacing: 1.2,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          vendor, 
          style: const TextStyle(
            fontWeight: FontWeight.w900, 
            fontSize: 20, 
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 4),
        Row(children: [
          Icon(Icons.info_outline, size: 14, color: Colors.blueGrey.shade400),
          const SizedBox(width: 6),
          Text(
            "Tindakan diperlukan sebelum batas waktu",
            style: TextStyle(
              fontSize: 13, 
              color: Colors.blueGrey.shade600, 
              fontWeight: FontWeight.w500,
            ),
          ),
        ]),
      ],
    );
  }

  Widget _urgencyButton(BuildContext context, Map<String, dynamic> contractData) {
    return SizedBox(
      width: isDesktop ? 140 : double.infinity,
      child: ElevatedButton(
        onPressed: () {
          final data = contractData.map((k, v) => MapEntry(k, v?.toString() ?? ''));
          Navigator.push(
            context, 
            MaterialPageRoute(
              builder: (_) => ContractDetailPage(
                contractData: Map<String, String>.from(data),
              ),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary, 
          foregroundColor: Colors.white,
          elevation: 0, 
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: const Text(
          "Lihat Detail", 
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}