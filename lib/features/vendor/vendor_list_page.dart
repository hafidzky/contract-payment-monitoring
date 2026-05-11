import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/providers/vendor_provider.dart';
import '../../core/constants/app_colors.dart';

class VendorListPage extends StatefulWidget {
  const VendorListPage({super.key});

  @override
  State<VendorListPage> createState() => _VendorListPageState();
}

class _VendorListPageState extends State<VendorListPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
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
              onPressed: () => _showVendorDialog(),
              child: const Icon(Icons.add, color: Colors.white),
            ),
      body: Consumer<VendorProvider>(
        builder: (context, provider, _) {
          final filtered = provider.vendors.where((v) {
            final q = _searchQuery.toLowerCase();
            return q.isEmpty
                || v.name.toLowerCase().contains(q)
                || v.category.toLowerCase().contains(q);
          }).toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 80),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── Header ───────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Vendor Yang Terdaftar',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        Text(
                          '${provider.vendors.length} vendor terdaftar',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                    if (isDesktop)
                      IntrinsicWidth(
                        child: ElevatedButton.icon(
                          onPressed: () => _showVendorDialog(),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Tambah Vendor'),
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

                // ─── Search Bar ───────────────────────────────────
                TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: 'Cari nama, ID, atau kategori vendor...',
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // ─── List / Empty State ───────────────────────────
                if (provider.vendors.isEmpty)
                  _buildEmptyState(isSearch: false)
                else if (filtered.isEmpty)
                  _buildEmptyState(isSearch: true)
                else
                  ...filtered.asMap().entries.map((e) {
                    final index = provider.vendors.indexOf(e.value);
                    return _buildVendorCard(e.value, index, isDesktop);
                  }),
              ],
            ),
          );
        },
      ),
    );
  }

  // ─── Vendor Card ──────────────────────────────────────────────
  Widget _buildVendorCard(Vendor vendor, int index, bool isDesktop) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.business,
                color: AppColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vendor.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    vendor.category,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),

            // Menu
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: Colors.grey.shade400),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
              itemBuilder: (_) => <PopupMenuEntry<String>>[
                PopupMenuItem<String>(
                  value: 'edit',
                  child: Row(children: [
                    Icon(Icons.edit_outlined,
                      size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 10),
                    const Text('Edit', style: TextStyle(fontSize: 13)),
                  ]),
                ),
                const PopupMenuDivider(),
                PopupMenuItem<String>(
                  value: 'delete',
                  child: Row(children: [
                    Icon(Icons.delete_outline,
                      size: 16, color: Colors.red.shade400),
                    const SizedBox(width: 10),
                    Text('Hapus',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.red.shade400,
                      )),
                  ]),
                ),
              ],
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    _showVendorDialog(vendor: vendor, index: index);
                    break;
                  case 'delete':
                    _showDeleteDialog(vendor, index);
                    break;
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  // ─── Add / Edit Dialog ────────────────────────────────────────
  void _showVendorDialog({Vendor? vendor, int? index}) {
    final isEdit = vendor != null;
    final nameCtrl = TextEditingController(text: vendor?.name ?? '');
    final formKey = GlobalKey<FormState>();

    final List<String> categoryOptions = [
      'Konstruksi & Sipil',
      'Pengadaan Alat Berat',
      'Pengadaan Barang',
      'Logistik & Transportasi',
      'Jasa Konsultansi',
      'Teknologi Informasi',
      'Pemeliharaan & Perawatan',
      'Keamanan & Keselamatan',
    ];

    String selectedCategory = categoryOptions.contains(vendor?.category)
        ? vendor!.category
        : categoryOptions.first;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 20, vertical: 40),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.business,
                          color: AppColors.primary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        isEdit ? 'Edit Vendor' : 'Tambah Vendor Baru',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ]),
                    const SizedBox(height: 24),

                    // Nama
                    _label('Nama Vendor'),
                    TextFormField(
                      controller: nameCtrl,
                      decoration: _inputDeco(
                        'Masukkan nama vendor',
                        Icons.business_outlined,
                      ),
                      validator: (v) => v == null || v.isEmpty
                          ? 'Nama wajib diisi'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    // Kategori
                    _label('Kategori'),
                    DropdownButtonFormField<String>(
                      initialValue: selectedCategory,
                      decoration: _inputDeco(null, Icons.work_outline),
                      items: categoryOptions
                          .map((c) => DropdownMenuItem(
                                value: c,
                                child: Text(c),
                              ))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) {
                          setDialogState(() => selectedCategory = v);
                        }
                      },
                    ),
                    const SizedBox(height: 24),

                    // Actions
                    Row(children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                            side: BorderSide(color: Colors.grey.shade300),
                          ),
                          child: const Text('Batal',
                            style: TextStyle(color: Colors.grey)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            if (!formKey.currentState!.validate()) return;

                            final provider = Provider.of<VendorProvider>(
                              context, listen: false);

                            if (isEdit && index != null) {
                              await provider.updateVendor(
                                index,
                                Vendor(
                                  name:     nameCtrl.text.trim(),
                                  category: selectedCategory,
                                ),
                              );
                            } else {
                              await provider.addVendor(
                                Vendor(
                                  name:     nameCtrl.text.trim(),
                                  category: selectedCategory,
                                ),
                              );
                            }

                            if (ctx.mounted) Navigator.pop(ctx);
                            _showSnackbar(
                              isEdit
                                  ? 'Vendor berhasil diperbarui'
                                  : 'Vendor baru berhasil ditambahkan',
                              Colors.green,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                            elevation: 0,
                          ),
                          child: Text(
                            isEdit ? 'Simpan' : 'Tambah',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ]),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Delete Dialog ────────────────────────────────────────────
  void _showDeleteDialog(Vendor vendor, int index) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.delete_outline,
                    color: Colors.red.shade600, size: 28),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Hapus Vendor',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Hapus "${vendor.name}" dari daftar vendor?',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 110,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                        child: const Text('Batal',
                          style: TextStyle(color: Colors.grey)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 110,
                      child: ElevatedButton(
                        onPressed: () async {
                          final provider = Provider.of<VendorProvider>(
                            context, listen: false);
                          await provider.deleteVendor(index);
                          if (ctx.mounted) Navigator.pop(ctx);
                          _showSnackbar(
                            '${vendor.name} dihapus',
                            Colors.red,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Hapus',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
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

  // ─── Helpers ──────────────────────────────────────────────────
  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 13,
        color: Colors.black87,
      ),
    ),
  );

  InputDecoration _inputDeco(String? hint, IconData? icon) => InputDecoration(
    hintText: hint,
    prefixIcon: icon != null
        ? Icon(icon, size: 20, color: Colors.grey)
        : null,
    filled: true,
    fillColor: const Color(0xFFF8F9FF),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  );

  void _showSnackbar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10)),
      duration: const Duration(seconds: 2),
    ));
  }

  Widget _buildEmptyState({required bool isSearch}) => Center(
    child: Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.business_outlined,
              size: 48,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isSearch
                ? 'Vendor tidak ditemukan'
                : 'Belum ada vendor terdaftar',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (!isSearch) ...[
            const SizedBox(height: 8),
            Text(
              'Tekan tombol + untuk menambahkan vendor baru',
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 13,
              ),
            ),
          ],
        ],
      ),
    ),
  );
}