import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/contract_helper.dart';
import '../../data/providers/contract_provider.dart';
import 'widgets/contract_card.dart';
import 'widgets/contract_filter.dart';
import 'widgets/contract_empty.dart';

class ContractListPage extends StatefulWidget {
  const ContractListPage({super.key});

  @override
  State<ContractListPage> createState() => _ContractListPageState();
}

class _ContractListPageState extends State<ContractListPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery    = '';
  String _selectedFilter = 'Semua';
  int _currentPage       = 1;
  static const int _itemsPerPage = 10;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _getDisplayStatus(Map<String, String> contract) {
    if (ContractHelper.isContractWarning(contract['termin_data'])) return 'Warning';
    return contract['status'] ?? 'Active';
  }

  List<Map<String, String>> _applyFilter(List<Map<String, String>> all) {
    return all.where((contract) {
      final matchesStatus = _selectedFilter == 'Semua'
          || _getDisplayStatus(contract) == _selectedFilter;
      final q = _searchQuery.toLowerCase();
      final matchesSearch = q.isEmpty
          || (contract['name'] ?? '').toLowerCase().contains(q)
          || (contract['id'] ?? '').toLowerCase().contains(q);
      return matchesStatus && matchesSearch;
    }).toList();
  }

  void _confirmDelete(BuildContext context,
      ContractProvider provider, Map<String, String> contract) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.shade50, shape: BoxShape.circle),
            child: Icon(Icons.delete_outline,
              color: Colors.red.shade600, size: 20),
          ),
          const SizedBox(width: 12),
          const Text('Hapus Kontrak',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Anda yakin ingin menghapus kontrak ini?',
              style: TextStyle(color: Colors.grey.shade700, fontSize: 14)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(children: [
                Icon(Icons.description_outlined,
                  size: 16, color: Colors.grey.shade500),
                const SizedBox(width: 8),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(contract['name'] ?? '-',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13)),
                    Text(contract['id'] ?? '-',
                      style: TextStyle(fontSize: 11,
                        color: Colors.grey.shade500)),
                  ],
                )),
              ]),
            ),
            const SizedBox(height: 8),
            Text('Tindakan ini tidak dapat dibatalkan.',
              style: TextStyle(color: Colors.red.shade400, fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal',
              style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            onPressed: () {
              provider.deleteContract(contract['id'] ?? '');
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(
                  'Kontrak ${contract['name']} berhasil dihapus'),
                backgroundColor: Colors.red.shade600,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
                margin: const EdgeInsets.all(16),
              ));
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: isDesktop
        ? null
        : FloatingActionButton(
            backgroundColor: AppColors.primary,
            onPressed: () => Navigator.pushNamed(context, '/add-contract'),
            child: const Icon(Icons.add, color: Colors.white),
        ),
        
      body: Consumer<ContractProvider>(
        builder: (context, provider, _) {
          final filtered = _applyFilter(provider.allContracts);
          final reversed = filtered.reversed.toList();

          final totalPages =
            (reversed.length / _itemsPerPage).ceil();
          if (_currentPage > totalPages && totalPages > 0) {
            _currentPage = totalPages;
          }
          final start = (_currentPage - 1) * _itemsPerPage;
          final end = (start + _itemsPerPage).clamp(0, reversed.length);
          final paginated = reversed.sublist(start, end);

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 80),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Kontrak Yang Terdaftar',
                          style: TextStyle(fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary)),
                        Text('${provider.allContracts.length} kontrak terdaftar',
                          style: TextStyle(fontSize: 13,
                            color: Colors.grey.shade500)),
                      ],
                    ),
                    if (isDesktop)
                      IntrinsicWidth(
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.pushNamed(
                            context, '/add-contract'),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Tambah Kontrak'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                            elevation: 0,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),

                // Search
                TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() {
                    _searchQuery = v;
                    _currentPage = 1;
                  }),
                  decoration: InputDecoration(
                    hintText: 'Cari nama vendor atau ID...',
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                                _currentPage = 1;
                              });
                            })
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 16),

                // ✅ Filter dari widget terpisah
                ContractFilterRow(
                  selectedFilter: _selectedFilter,
                  allContracts: provider.allContracts,
                  getDisplayStatus: _getDisplayStatus,
                  onFilterChanged: (f) => setState(() {
                    _selectedFilter = f;
                    _currentPage = 1;
                  }),
                ),
                const SizedBox(height: 16),

                // ✅ List dari widget terpisah
                if (reversed.isEmpty)
                  const ContractEmptyState()
                else ...[
                  ...paginated.map((contract) => ContractCard(
                    contract: contract,
                    provider: provider,
                    onDelete: () =>
                      _confirmDelete(context, provider, contract),
                  )),
                  if (totalPages > 1)
                    ContractPagination(
                      currentPage: _currentPage,
                      totalPages:  totalPages,
                      onPrevious:  () => setState(() => _currentPage--),
                      onNext:      () => setState(() => _currentPage++),
                    ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}