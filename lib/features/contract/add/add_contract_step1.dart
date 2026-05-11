import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/../core/constants/app_colors.dart';
import '/../data/providers/vendor_provider.dart';
import 'add_contract_step2.dart';
import '../widgets/step_indicator.dart';

class AddContractPage extends StatefulWidget {
  const AddContractPage({super.key});

  @override
  State<AddContractPage> createState() => _AddContractPageState();
}

class _AddContractPageState extends State<AddContractPage> {
  String? _selectedVendorName;
  String _searchQuery = '';
  bool _showError = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VendorProvider>().loadVendors();
    });
  }

  void _onNext() {
    if (_selectedVendorName == null) {
      setState(() => _showError = true);
      return;
    }
    setState(() => _showError = false);
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => AddContractDetailPage(vendorName: _selectedVendorName!),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildTopBar(),
          Expanded(
            child: Consumer<VendorProvider>(
              builder: (context, vendorProvider, _) {
                final filtered = vendorProvider.vendors.where((v) {
                  final q = _searchQuery.toLowerCase();
                  return q.isEmpty
                      || v.name.toLowerCase().contains(q);
                }).toList();

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 900),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Step indicator
                          Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 400),
                              child: StepIndicator(current: 1),
                            ),
                          ),
                          const SizedBox(height: 32),

                          const Text('Pilih Vendor',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text('Pilih mitra vendor pelaksana kontrak.',
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                          if (_showError) ...[
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(Icons.info_outline, size: 14, color: Colors.red.shade400),
                                const SizedBox(width: 4),
                                Text(
                                  'Silakan pilih vendor terlebih dahulu.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.red.shade400,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 20),

                          // Search bar
                          TextField(
                            onChanged: (v) => setState(() => _searchQuery = v),
                            decoration: InputDecoration(
                              hintText: 'Cari nama vendor atau ID...',
                              prefixIcon: const Icon(Icons.search, color: Colors.grey),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Empty state
                          if (filtered.isEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 40),
                              child: Center(
                                child: Column(
                                  children: [
                                    Icon(Icons.business_outlined,
                                      size: 48, color: Colors.grey.shade300),
                                    const SizedBox(height: 12),
                                    Text(
                                      vendorProvider.vendors.isEmpty
                                          ? 'Belum ada vendor terdaftar.\nTambahkan vendor di menu Manajemen Vendor.'
                                          : 'Vendor tidak ditemukan',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: Colors.grey.shade500),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            ...filtered.map((vendor) => _buildVendorCard(vendor)),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildVendorCard(Vendor vendor) {
    final isSelected = vendor.name == _selectedVendorName;

    return GestureDetector(
      onTap: () => setState(() {
        _selectedVendorName = vendor.name;
        _showError = false; 
      }),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? AppColors.primary
                    : AppColors.primary.withValues(alpha: 0.08),
              ),
              child: Icon(
                isSelected ? Icons.check : Icons.business,
                color: isSelected ? Colors.white : AppColors.primary,
                size: 18,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(vendor.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: isSelected ? AppColors.primary : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(vendor.category,
                    style: const TextStyle(
                      fontSize: 12, color: Colors.grey
                    )
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      color: AppColors.primary,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        bottom: 12, left: 16, right: 16,
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const Text('Kontrak Baru',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                  child: const Text('Kembali',
                    style: TextStyle(color: Colors.grey)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _onNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Selanjutnya',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward, color: Colors.white, size: 18),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}