import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/contract_document.dart';
import '../../../data/providers/contract_provider.dart';
import '../widgets/step_indicator.dart';

class AddContractReviewPage extends StatelessWidget {
  final String vendorName;
  final String noKontrak;
  final String namaPekerjaan;
  final double totalNilaiKontrak;
  final String startDate;
  final String endDate;
  final List<Map<String, dynamic>> terminList;
  final List<ContractDocument> uploadedDocs; 

  const AddContractReviewPage({
    super.key,
    required this.vendorName,
    required this.noKontrak,
    required this.namaPekerjaan,
    required this.totalNilaiKontrak,
    required this.startDate,
    required this.endDate,
    required this.terminList,
    required this.uploadedDocs, // ✅ BARU
  });

  void _simpanKontrak(BuildContext context) {
    // Buat ID kontrak
    final contractId = noKontrak.isNotEmpty
        ? noKontrak
        : 'CNT-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';

    final data = {
      'name':        vendorName,
      'id':          contractId,
      'status':      'Active',
      'type':        namaPekerjaan,
      'nilai':       CurrencyFormatter.toFullRupiah(totalNilaiKontrak),
      'timeline':    '$startDate - $endDate',
      'termin_data': jsonEncode(terminList),
    };

    final provider = Provider.of<ContractProvider>(context, listen: false);

    // Simpan kontrak
    provider.addContract(data);

    // ✅ Simpan dokumen yang diupload di step 2
    if (uploadedDocs.isNotEmpty) {
      provider.addDocuments(contractId, uploadedDocs);
    }

    // ✅ Log pertama: kontrak dibuat
    provider.addLog(contractId, 'Kontrak dibuat', 'create');

    _showSuccessDialog(context);
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

                      // ✅ BARU: tampilkan dokumen yang akan diupload (jika ada)
                      if (uploadedDocs.isNotEmpty) ...[
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
          _reviewRow('Jumlah Termin',   '${terminList.length}x pembayaran'),
          if (uploadedDocs.isNotEmpty)
            _reviewRow('Dokumen', '${uploadedDocs.length} file terlampir'),
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
          ...terminList.asMap().entries.map((e) => Padding(
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
                child: Text('${uploadedDocs.length}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold,
                    color: AppColors.primary)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...uploadedDocs.map((doc) => Padding(
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
                  onPressed: () => _simpanKontrak(context),
                  icon: const Icon(Icons.save_outlined, color: Colors.white, size: 18),
                  label: const Text('Simpan Kontrak',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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