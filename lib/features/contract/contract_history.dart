import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'contract_detail.dart';
import '../../core/constants/app_colors.dart';
import '../../data/providers/contract_provider.dart';
import '../../core/utils/contract_helper.dart';
import '../../core/utils/currency_formatter.dart';

class ContractHistoryPage extends StatefulWidget {
  final String filterStatus;
  const ContractHistoryPage({super.key, this.filterStatus = "All"});

  @override
  State<ContractHistoryPage> createState() => _ContractHistoryPageState();
}

class _ContractHistoryPageState extends State<ContractHistoryPage> {
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = "";

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isDesktop = screenWidth > 800;
    final provider = Provider.of<ContractProvider>(context);

    List<Map<String, String>> baseList = [];
    if (widget.filterStatus == "Warning") {
      baseList = provider.allContracts.where((c) =>
        ContractHelper.isContractWarning(c['termin_data'])).toList();
    } else if (widget.filterStatus == "Active") {
      baseList = provider.allContracts.where((c) => c['status'] == 'Active').toList();
    } else if (widget.filterStatus == "Finished") {
      baseList = provider.allContracts.where((c) => c['status'] == 'Finished').toList();
    } else {
      baseList = provider.allContracts;
    }

    final displayedVendors = baseList.where((vendor) {
      final name = (vendor['name'] ?? '').toLowerCase();
      final id = (vendor['id'] ?? '').toLowerCase();
      final query = searchQuery.toLowerCase();
      return name.contains(query) || id.contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F8),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          widget.filterStatus == "All" ? "Semua Kontrak" : "Kontrak: ${widget.filterStatus}",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          // Summary bar
          if (displayedVendors.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              color: const Color(0xFFF0F2F8),
              child: Row(
                children: [
                  Text(
                    "${displayedVendors.length} kontrak ditemukan",
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: displayedVendors.isEmpty
                ? _buildEmptyState()
                : isDesktop
                    ? _buildDesktopList(context, displayedVendors)
                    : _buildMobileList(context, displayedVendors),
          ),
        ],
      ),
    );
  }

  // Desktop: list penuh lebar dengan info lebih lengkap
  Widget _buildDesktopList(BuildContext context, List<Map<String, String>> vendors) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      itemCount: vendors.length,
      itemBuilder: (context, index) => _buildDesktopCard(context, vendors[index]),
    );
  }

  // Mobile: list compact
  Widget _buildMobileList(BuildContext context, List<Map<String, String>> vendors) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: vendors.length,
      itemBuilder: (context, index) => _buildMobileCard(context, vendors[index]),
    );
  }

  Widget _buildDesktopCard(BuildContext context, Map<String, String> vendor) {
    final statusInfo = _getStatusInfo(vendor);
    final terminSummary = ContractHelper.getTerminSummary(vendor['termin_data']);
    final nilaiKontrak = CurrencyFormatter.toFullRupiah(vendor['nilai']);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))
        ],
      ),
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => ContractDetailPage(contractData: vendor))),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              // Icon status
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: statusInfo['color'].withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.description_outlined, color: statusInfo['color'], size: 22),
              ),
              const SizedBox(width: 16),

              // Info utama
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(vendor['name'] ?? '-',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary)),
                    const SizedBox(height: 4),
                    Text("ID: ${vendor['id'] ?? '-'}  •  ${vendor['type'] ?? '-'}",
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                    const SizedBox(height: 8),
                    _statusBadge(statusInfo),
                  ],
                ),
              ),

              // Nilai kontrak
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text("Nilai Kontrak",
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    Text(nilaiKontrak,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.primary)), // ← 14 → 18, bold → w900
                  ],
                ),
              ),

              // Progress termin
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text("Termin Terbayar",
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 6),
                    _terminProgress(terminSummary),
                  ],
                ),
              ),

              // Timeline
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text("Timeline",
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    Text(vendor['timeline'] ?? '-',
                      textAlign: TextAlign.center,  
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
                  ],
                ),
              ),

              const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileCard(BuildContext context, Map<String, String> vendor) {
    final statusInfo = _getStatusInfo(vendor);
    final terminSummary = ContractHelper.getTerminSummary(vendor['termin_data']);
    final nilaiKontrak = CurrencyFormatter.toFullRupiah(vendor['nilai']);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))
        ],
      ),
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => ContractDetailPage(contractData: vendor))),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Baris atas: icon + nama + badge
              Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: statusInfo['color'].withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.description_outlined, color: statusInfo['color'], size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(vendor['name'] ?? '-',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primary)),
                        Text("ID: ${vendor['id'] ?? '-'}  •  ${vendor['type'] ?? '-'}",
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                      ],
                    ),
                  ),
                  _statusBadge(statusInfo),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),

              // Baris bawah: nilai + termin progress
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Nilai Kontrak",
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                    const SizedBox(height: 2),
                    Text(nilaiKontrak,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.primary)), 
                  ],
                ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text("Termin",
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                      const SizedBox(height: 2),
                      _terminProgress(terminSummary),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusBadge(Map<String, dynamic> statusInfo) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: statusInfo['color'].withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: statusInfo['color'].withValues(alpha: 0.3)),
      ),
      child: Text(
        statusInfo['label'].toUpperCase(),
        style: TextStyle(color: statusInfo['color'], fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _terminProgress(Map<String, int> summary) {
    final total = summary['total'] ?? 0;
    final paid = summary['paid'] ?? 0;
    final color = total == 0 ? Colors.grey
        : paid == total ? Colors.green
        : paid > 0 ? Colors.orange
        : Colors.grey;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          total == 0 ? "-" : "$paid/$total",
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color),
        ),
        if (total > 0) ...[
          const SizedBox(width: 6),
          SizedBox(
            width: 40,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: total > 0 ? paid / total : 0,
                minHeight: 6,
                backgroundColor: Colors.grey.shade200,
                color: color,
              ),
            ),
          ),
        ]
      ],
    );
  }

  Map<String, dynamic> _getStatusInfo(Map<String, String> vendor) {
    if (ContractHelper.isContractWarning(vendor['termin_data'])) {
      return {'color': Colors.orange, 'label': 'Warning'};
    }
    switch (vendor['status']) {
      case 'Active': return {'color': Colors.green, 'label': 'Active'};
      case 'Finished': return {'color': Colors.blue, 'label': 'Finished'};
      default: return {'color': Colors.grey, 'label': vendor['status'] ?? 'Unknown'};
    }
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      color: Colors.white,
      child: TextField(
        controller: _searchController,
        onChanged: (v) => setState(() => searchQuery = v),
        decoration: InputDecoration(
          hintText: "Cari nama vendor atau ID kontrak...",
          prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 20),
          suffixIcon: searchQuery.isNotEmpty
              ? IconButton(icon: const Icon(Icons.close, size: 18), onPressed: () {
                  _searchController.clear();
                  setState(() => searchQuery = "");
                })
              : null,
          filled: true,
          fillColor: const Color(0xFFF0F2F5),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        ),
      ),
    );
  }

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
            child: Icon(Icons.folder_off_outlined, size: 48, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 16),
          Text("Tidak ada kontrak ditemukan",
            style: TextStyle(color: Colors.grey.shade500, fontSize: 15, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Text("Coba ubah filter atau kata kunci pencarian",
            style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
        ],
      ),
    );
  }
}