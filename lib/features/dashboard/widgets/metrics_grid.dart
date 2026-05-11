import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/contract_helper.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/providers/contract_provider.dart';
import '../../contract/contract_history.dart';
import '../../contract/contract_value.dart';

class MetricsGrid extends StatelessWidget {
  final bool isDesktop;
  final bool isMedium; 
  const MetricsGrid({super.key, required this.isDesktop, this.isMedium = false});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ContractProvider>(context);
    
    double totalSisa = 0;
    double totalNilai = 0;
    int warningCount = 0;

    // Hitung data kontrak dari provider
    for (var contract in provider.allContracts) {
      double nilaiTotal = ContractHelper.parseToDouble(contract['nilai'] ?? '0');
      double sudahDibayar = ContractHelper.calculatePaidAmount(contract['termin_data']);
      
      totalNilai += nilaiTotal;
      totalSisa += (nilaiTotal - sudahDibayar);
     
      if (ContractHelper.isContractWarning(contract['termin_data'])) {
        warningCount++;
      }
    }

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: isDesktop ? 4 : 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: isDesktop ? 1.8 : isMedium ? 1.6 : 1.6,
      children: [
        _metricCard(
          context, 
          "Total Contracts", 
          provider.totalContracts.toString(), 
          Icons.folder_open, 
          AppColors.primary,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ContractHistoryPage(filterStatus: "All")))
        ),
        _metricCard(
          context, 
          "Active", 
          provider.activeContracts.toString(), 
          Icons.check_circle, 
          Colors.teal,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ContractHistoryPage(filterStatus: "Active")))
        ),
        _metricCard(
          context, 
          "Warning", 
          warningCount.toString(), 
          Icons.warning, 
          AppColors.error,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ContractHistoryPage(filterStatus: "Warning")))
        ),
        // Kartu Total Nilai: Sekarang Web & Mobile sama-sama diringkas (Rp 1.2 M)
        _metricCard(
          context, 
          "Total Nilai", 
          CurrencyFormatter.toShort(totalNilai), 
          Icons.payments, 
          AppColors.primary,
          isGradient: true,
          subtitle: "Sisa: ${CurrencyFormatter.toShort(totalSisa)}",  
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ContractValuePage()))
        ),
      ],
    );
  }

  Widget _metricCard(
    BuildContext context, 
    String label, 
    String value, 
    IconData icon, 
    Color color,
    {bool isGradient = false, String? subtitle, VoidCallback? onTap}
  ) {
    // Deteksi kecil layar untuk penyesuaian ukuran icon dan font secara internal
    final bool isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 20 : 12,
            vertical: isDesktop ? 16 : 10,
          ),
          decoration: BoxDecoration(
            color: isGradient ? null : Colors.white,
            gradient: isGradient ? const LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [Color(0xFF002753), Color(0xFF134684)],
            ) : null,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04), 
                blurRadius: 12, 
                offset: const Offset(0, 4)
              )
            ],
            border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon, 
                color: isGradient ? Colors.white : color, 
                size: isDesktop ? 28 : (isSmallScreen ? 18 : 22)
              ),
              SizedBox(height: isSmallScreen ? 4 : 6),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label, 
                      maxLines: 1, 
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isGradient ? Colors.white70 : Colors.black54,
                        fontSize: isDesktop ? 14 : (isSmallScreen ? 10 : 13),
                        fontWeight: FontWeight.w600
                      )
                    ),
                    const SizedBox(height: 2),
                    // FittedBox memastikan angka tidak terpotong (menjadi ...)
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          value,
                          style: TextStyle(
                            color: isGradient ? Colors.white : Colors.black87,
                            fontSize: isDesktop ? 32 : (isSmallScreen ? 22 : 28),  
                            fontWeight: FontWeight.bold, 
                            height: 1
                          )
                        ),
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle, 
                        maxLines: 1, 
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isGradient ? Colors.white60 : Colors.black38,
                          fontSize: isDesktop ? 13 : (isSmallScreen ? 9 : 11),
                          fontWeight: FontWeight.w500
                        )
                      ),
                    ]
                  ],
                )
              ),
            ],
          ),
        ),
      ),
    );
  }
}