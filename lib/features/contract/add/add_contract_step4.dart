import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/contract_document.dart';
import '../../../data/providers/vendor_provider.dart';
import '../../../data/providers/contract_provider.dart';
import '../widgets/step_indicator.dart';

class AddContractReviewPage extends StatefulWidget {
  final Vendor selectedVendor;
  final Map<String, dynamic> step2Data;
  final List<Map<String, dynamic>> terminList;
  final List<ContractDocument> uploadedDocs;

  const AddContractReviewPage({
    super.key,
    required this.selectedVendor,
    required this.step2Data,
    required this.terminList,
    required this.uploadedDocs,
  });

  @override
  State<AddContractReviewPage> createState() => _AddContractReviewPageState();
}

class _AddContractReviewPageState extends State<AddContractReviewPage> {
  bool _isLoading = false;

  String get vendorName => widget.selectedVendor.name;
  String get noKontrak => widget.step2Data['no_kontrak'] ?? '';
  String get namaPekerjaan => widget.step2Data['nama_pekerjaan'] ?? '';
  double get totalNilaiKontrak => widget.step2Data['nilai_kontrak'] ?? 0.0;
  String get startDate => widget.step2Data['tgl_mulai'] ?? '';
  String get endDate => widget.step2Data['tgl_selesai'] ?? '';

  Future<void> _simpanKontrak(BuildContext context) async {
    setState(() => _isLoading = true);

    // Mesin pengubah '1-5-2026' menjadi '2026-05-01'
    String formatTanggalKeDB(String tglLokal) {
      try {
        final p = tglLokal.split('-');
        if (p.length == 3) {
          return '${p[2]}-${p[1].padLeft(2, '0')}-${p[0].padLeft(2, '0')}';
        }
      } catch (_) {}
      return tglLokal; // Kembalikan asli jika gagal
    }

    // 2. TAMBAHKAN MESIN PENGHITUNG HARI INI
    int hitungDurasi(String start, String end) {
      try {
        final tglStart = DateTime.parse(formatTanggalKeDB(start));
        final tglEnd = DateTime.parse(formatTanggalKeDB(end));
        // Hitung selisih hari antara tanggal selesai dan tanggal mulai
        final durasi = tglEnd.difference(tglStart).inDays;
        return durasi > 0 ? durasi : 0; // Pastikan tidak minus
      } catch (_) {
        return 0;
      }
    }

    final contractPayload = {
      "vendor_id": widget.selectedVendor.id,
      "contract_number": noKontrak,
      "title": namaPekerjaan,
      "total_value": totalNilaiKontrak.toInt(),
      // GUNAKAN MESIN PENGUBAH TANGGAL DI SINI
      "start_date": formatTanggalKeDB(startDate),
      "duration_days": hitungDurasi(startDate, endDate),
      "end_date": formatTanggalKeDB(endDate),
      "termins": widget.terminList.map((termin) {
        return {
          // AMBIL DARI db_date YANG KITA BUAT DI LAYAR 3 TADI
          "due_date": termin['db_date'] ?? formatTanggalKeDB(termin['date'] ?? ''),
          // AMBIL DARI 'nominal' (ANGKA MURNI), BUKAN 'amount_raw' YANG KOSONG
          "target_amount": termin['nominal'] != null ? double.tryParse(termin['nominal'].toString())?.toInt() ?? 0 : 0,
          "description": termin['notes'] ?? "-",
        };
      }).toList()
    };

    final provider = Provider.of<ContractProvider>(context, listen: false);
    final isSuccess = await provider.addContract(contractPayload);

    if (mounted) setState(() => _isLoading = false);

    if (isSuccess) {
      if (widget.uploadedDocs.isNotEmpty) {
        provider.addDocuments(noKontrak, widget.uploadedDocs);
      }
      // Refresh data terbaru agar list UI ter-refresh otomatis
      await provider.fetchContracts();
      provider.addLog(noKontrak, 'Kontrak dibuat', 'create');
      
      if (context.mounted) {
        _showSuccessDialog(context);
      }
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal menyimpan kontrak. Periksa inputan kembali.'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check_circle, size: 60, color: Colors.green.shade600),
            ),
            const SizedBox(height: 20),
            const Text('Kontrak Berhasil Disimpan!',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Kontrak telah terdaftar dalam sistem monitoring.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                ),
                onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
                child: const Text('Kembali ke Dashboard',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildTopBar(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 400),
                          child: StepIndicator(current: 4),
                        ),
                      ),
                      const SizedBox(height: 32),
                      const Text('Review Kontrak',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary)),
                      const SizedBox(height: 4),
                      const Text('Periksa kembali sebelum menyimpan.',
                        style: TextStyle(color: Colors.grey, fontSize: 13)),
                      const SizedBox(height: 24),

                      _buildInfoCard(),
                      const SizedBox(height: 16),
                      _buildTerminCard(),

                      if (widget.uploadedDocs.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _buildDocsPreviewCard(),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
          _buildBottomBar(context),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
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
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(vendorName,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
                    color: AppColors.primary),
                  overflow: TextOverflow.ellipsis),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.check_circle, size: 14, color: Colors.green.shade700),
                  const SizedBox(width: 4),
                  Text('Siap Simpan',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold,
                      color: Colors.green.shade700)),
                ]),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          _reviewRow('No. Kontrak',     noKontrak),
          _reviewRow('Nama Pekerjaan', namaPekerjaan),
          _reviewRow('Nilai Kontrak',   CurrencyFormatter.toFullRupiah(totalNilaiKontrak)),
          _reviewRow('Tanggal Mulai',   startDate),
          _reviewRow('Tanggal Selesai', endDate),
          _reviewRow('Jumlah Termin',   '${widget.terminList.length}x pembayaran'),
          if (widget.uploadedDocs.isNotEmpty)
            _reviewRow('Dokumen', '${widget.uploadedDocs.length} file terlampir'),
        ],
      ),
    );
  }

  Widget _reviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(label,
              style: const TextStyle(fontSize: 13, color: Colors.grey))),
          Expanded(
            child: Text(value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                color: Colors.black87))),
        ],
      ),
    );
  }

  Widget _buildTerminCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Jadwal Termin',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary)),
          const SizedBox(height: 12),
          ...widget.terminList.asMap().entries.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(children: [
                      Container(
                        width: 24, height: 24,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Center(
                          child: Text('${e.key + 1}',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold,
                              color: AppColors.primary)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(e.value['date']?.toString() ?? '-',
                        style: const TextStyle(fontSize: 13, color: Colors.black87)),
                    ]),
                    Text(e.value['amount']?.toString() ?? '-',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold,
                        color: Colors.black87)),
                  ],
                ),
                // ← Notes
                if ((e.value['notes']?.toString() ?? '').isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6, left: 34),
                    child: Row(
                      children: [
                        Icon(Icons.notes, size: 12, color: Colors.grey.shade400),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            e.value['notes'].toString(),
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade600,
                              fontStyle: FontStyle.italic),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  // ✅ BARU: Preview dokumen di halaman review
  Widget _buildDocsPreviewCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Dokumen Terlampir',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('${widget.uploadedDocs.length}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold,
                    color: AppColors.primary)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...widget.uploadedDocs.map((doc) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Icon(
                  doc.type == 'PDF' ? Icons.picture_as_pdf
                    : (doc.type == 'JPG' || doc.type == 'PNG' || doc.type == 'JPEG')
                        ? Icons.image
                        : Icons.insert_drive_file,
                  size: 18,
                  color: doc.type == 'PDF' ? Colors.red : AppColors.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(doc.name,
                    style: const TextStyle(fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                ),
                Text('${doc.type} • ${doc.size}',
                  style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 10, offset: const Offset(0, -4))],
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                  child: const Text('Kembali', style: TextStyle(color: Colors.grey)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : () => _simpanKontrak(context),
                  icon: _isLoading 
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.save_outlined, color: Colors.white, size: 18),
                  label: Text(_isLoading ? 'Menyimpan...' : 'Simpan Kontrak',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
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