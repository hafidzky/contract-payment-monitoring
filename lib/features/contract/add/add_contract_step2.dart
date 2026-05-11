import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;

import '../../../core/constants/app_colors.dart';
import '../../../data/models/contract_document.dart';
import 'add_contract_step3.dart';
import '../widgets/step_indicator.dart';

class AddContractDetailPage extends StatefulWidget {
  final String vendorName;
  const AddContractDetailPage({super.key, required this.vendorName});

  @override
  State<AddContractDetailPage> createState() => _AddContractDetailPageState();
}

class _AddContractDetailPageState extends State<AddContractDetailPage> {
  final _formKey = GlobalKey<FormState>();
  final _noKontrakCtrl = TextEditingController();
  final _nilaiCtrl = TextEditingController();
  final List<ContractDocument> _uploadedDocs = [];
  final _namaPekerjaanCtrl = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;
  bool _showDateError = false;

  @override
  void dispose() {
    _noKontrakCtrl.dispose();
    _nilaiCtrl.dispose();
    _namaPekerjaanCtrl.dispose();
    super.dispose();
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.day}-${date.month}-${date.year}';
  }

  String _displayDate(DateTime? date) {
    if (date == null) return 'Pilih tanggal';
    return DateFormat('dd MMM yyyy').format(date);
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
            colorScheme:
                const ColorScheme.light(primary: AppColors.primary)),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  Future<void> _pickEndDate() async {
    final firstAllowed = _startDate != null
        ? _startDate!.add(const Duration(days: 1))
        : DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate != null && _endDate!.isAfter(firstAllowed)
          ? _endDate!
          : firstAllowed,
      firstDate: firstAllowed,
      lastDate: DateTime(2100),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
            colorScheme:
                const ColorScheme.light(primary: AppColors.primary)),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _endDate = picked);
  }
 
  Future<void> _pickDocument() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx', 'xlsx'],
      allowMultiple: true,
      withData: true, 
    );

    if (result != null && result.files.isNotEmpty) {
      for (final file in result.files) {
        final sizeInBytes = file.size;
        
        final sizeStr = sizeInBytes > 1024 * 1024
            ? '${(sizeInBytes / (1024 * 1024)).toStringAsFixed(1)} MB'
            : '${(sizeInBytes / 1024).toStringAsFixed(0)} KB';

        final ext = p.extension(file.name).replaceAll('.', '').toUpperCase();

        setState(() {
          _uploadedDocs.add(ContractDocument(
            name: file.name,
            path: file.path ?? 'web-file-${file.name}', 
            size: sizeStr,
            type: ext,
          ));
        });
      }
    }
  }

  void _onNext() {
    if (!_formKey.currentState!.validate()) return;
    if (_startDate == null || _endDate == null) {
      setState(() => _showDateError = true); 
      return;
    }
    setState(() => _showDateError = false);
    
    final rawNilai = _nilaiCtrl.text.replaceAll('.', '');
    final totalNilai = double.tryParse(rawNilai) ?? 0.0;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddContractTerminPage(
          vendorName: widget.vendorName,
          noKontrak: _noKontrakCtrl.text.trim(),
          namaPekerjaan: _namaPekerjaanCtrl.text.trim(), 
          totalNilaiKontrak: totalNilai,
          startDate: _formatDate(_startDate),
          endDate: _formatDate(_endDate),
          uploadedDocs: _uploadedDocs, 
        ),
      ),
    );
  }

  // Icon dinamis berdasarkan tipe file
  IconData _docIcon(String type) {
    switch (type) {
      case 'PDF':
        return Icons.picture_as_pdf;
      case 'JPG':
      case 'JPEG':
      case 'PNG':
        return Icons.image;
      case 'DOC':
      case 'DOCX':
        return Icons.description;
      case 'XLSX':
        return Icons.table_chart;
      default:
        return Icons.insert_drive_file;
    }
  }

  // Warna dinamis berdasarkan tipe file
  Color _docColor(String type) {
    switch (type) {
      case 'PDF':
        return Colors.red;
      case 'JPG':
      case 'JPEG':
      case 'PNG':
        return Colors.green;
      case 'DOC':
      case 'DOCX':
        return Colors.blue;
      case 'XLSX':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            _buildTopBar(),
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
                            child: StepIndicator(current: 2),
                          ),
                        ),
                        const SizedBox(height: 32),
                        const Text('Detail Kontrak',
                            style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary)),
                        const SizedBox(height: 4),
                        const Text('Lengkapi informasi dasar kontrak.',
                            style: TextStyle(color: Colors.grey, fontSize: 13)),
                        const SizedBox(height: 24),
                        
                        // ===== Form card =====
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2))
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // No Kontrak
                              _buildLabel('No. Kontrak'),
                              TextFormField(
                                controller: _noKontrakCtrl,
                                decoration:
                                    _inputDecoration('CT-2024-XXX', Icons.tag),
                                validator: (v) =>
                                    v == null || v.isEmpty ? 'Wajib diisi' : null,
                              ),
                              const SizedBox(height: 16),
                              
                              // Nama Pekerjaan
                              _buildLabel('Nama Pekerjaan'),
                              TextFormField(
                                controller: _namaPekerjaanCtrl,
                                decoration: _inputDecoration(
                                  'Contoh: Pembangunan Dermaga Utara',
                                  Icons.work_outline,
                                ),
                                validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
                              ),
                              const SizedBox(height: 16),
                              
                              // Nilai Kontrak
                              _buildLabel('Nilai Kontrak'),
                              TextFormField(
                                controller: _nilaiCtrl,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  _CurrencyFormatter(),
                                ],
                                decoration:
                                    _inputDecoration('0', null, prefix: 'Rp '),
                                validator: (v) {
                                  if (v == null || v.isEmpty) return 'Wajib diisi';
                                  final num =
                                      double.tryParse(v.replaceAll('.', '')) ?? 0;
                                  if (num <= 0) return 'Nilai harus lebih dari 0';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              
                              // Tanggal
                              _buildLabel('Periode Kontrak'),
                              Row(
                                children: [
                                  Expanded(
                                      child: _buildDatePicker(
                                    label: 'Tgl Mulai',
                                    value: _displayDate(_startDate),
                                    onTap: _pickStartDate,
                                    hasValue: _startDate != null,
                                  )),
                                  const SizedBox(width: 12),
                                  Expanded(
                                      child: _buildDatePicker(
                                    label: 'Tgl Selesai',
                                    value: _displayDate(_endDate),
                                    onTap:
                                        _startDate == null ? null : _pickEndDate,
                                    hasValue: _endDate != null,
                                    disabled: _startDate == null,
                                  )),
                                ],
                              ),

                              if (_showDateError && (_startDate == null || _endDate == null)) ...[
                                const SizedBox(height: 6),
                                Text(
                                  _startDate == null
                                      ? '* Pilih tanggal mulai terlebih dahulu'
                                      : '* Pilih tanggal selesai terlebih dahulu',
                                  style: const TextStyle(fontSize: 11, color: Colors.red),
                                ),
                              ],
                              
                              // Section Upload Dokumen
                              const SizedBox(height: 24),
                              const Divider(height: 1),
                              const SizedBox(height: 20),
                              _buildLabel('Dokumen Kontrak (Opsional)'),
                              const Text(
                                'Upload dokumen terkait seperti SPK, lampiran teknis, dll.',
                                style: TextStyle(color: Colors.grey, fontSize: 12),
                              ),
                              const SizedBox(height: 12),
                              
                              // Tombol upload
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: _pickDocument,
                                  icon: const Icon(Icons.upload_file, size: 18),
                                  label: const Text('Pilih File'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.primary,
                                    side: BorderSide(
                                        color: AppColors.primary
                                            .withValues(alpha: 0.5)),
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10)),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 13),
                                  ),
                                ),
                              ),
                              
                              // Hint format yang diterima
                              const SizedBox(height: 8),
                              const Text(
                                'Format: PDF, JPG, PNG, DOC, DOCX, XLSX',
                                style:
                                    TextStyle(fontSize: 11, color: Colors.grey),
                              ),
                              
                              // List dokumen yang sudah diupload
                              if (_uploadedDocs.isNotEmpty) ...[
                                const SizedBox(height: 16),
                                Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8F9FF),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                        color: Colors.grey.shade200),
                                  ),
                                  child: Column(
                                    children:
                                        List.generate(_uploadedDocs.length, (i) {
                                      final doc = _uploadedDocs[i];
                                      return Column(
                                        children: [
                                          ListTile(
                                            leading: Container(
                                              width: 36,
                                              height: 36,
                                              decoration: BoxDecoration(
                                                color: _docColor(doc.type)
                                                    .withValues(alpha: 0.1),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Icon(
                                                _docIcon(doc.type),
                                                color: _docColor(doc.type),
                                                size: 18,
                                              ),
                                            ),
                                            title: Text(
                                              doc.name,
                                              style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            subtitle: Text(
                                              '${doc.type} • ${doc.size}',
                                              style: const TextStyle(
                                                  fontSize: 11),
                                            ),
                                            trailing: IconButton(
                                              icon: const Icon(Icons.close,
                                                  size: 18, color: Colors.grey),
                                              onPressed: () =>
                                                  setState(() =>
                                                      _uploadedDocs.removeAt(i)),
                                            ),
                                            dense: true,
                                          ),
                                          if (i < _uploadedDocs.length - 1)
                                            const Divider(height: 1,
                                                indent: 16, endIndent: 16),
                                        ],
                                      );
                                    }),
                                  ),
                                ),
                                // Summary badge
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(Icons.check_circle,
                                        size: 14,
                                        color: Colors.green.shade600),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${_uploadedDocs.length} file siap diunggah',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.green.shade600,
                                          fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                              ],
                              // =========================================
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            _buildBottomBar(),
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
        bottom: 12,
        left: 16,
        right: 16,
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
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text,
          style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: Colors.black87)),
    );
  }

  InputDecoration _inputDecoration(String? hint, IconData? icon,
      {String? prefix}) {
    return InputDecoration(
      hintText: hint,
      prefixText: prefix,
      prefixIcon:
          icon != null ? Icon(icon, size: 20, color: Colors.grey) : null,
      filled: true,
      fillColor: const Color(0xFFF8F9FF),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _buildDatePicker({
    required String label,
    required String value,
    required VoidCallback? onTap,
    required bool hasValue,
    bool disabled = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
            decoration: BoxDecoration(
              color: disabled
                  ? Colors.grey.shade100
                  : const Color(0xFFF8F9FF),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: (_showDateError && !hasValue)
                  ? Colors.red 
                  : hasValue
                      ? AppColors.primary.withValues(alpha: 0.4)
                      : Colors.grey.shade300,
                width: (_showDateError && !hasValue) ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today,
                    size: 16,
                    color: disabled
                        ? Colors.grey.shade400
                        : AppColors.primary),
                const SizedBox(width: 8),
                Text(value,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: hasValue
                          ? FontWeight.w600
                          : FontWeight.normal,
                      color: disabled
                          ? Colors.grey.shade400
                          : hasValue
                              ? AppColors.primary
                              : Colors.grey,
                    )),
              ],
            ),
          ),
        ),
      ],
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
              offset: const Offset(0, -4))
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
                        borderRadius: BorderRadius.circular(12)),
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
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Selanjutnya',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold, 
                          fontSize: 15
                        )
                      ),
                      SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward, 
                        color: Colors.white, 
                        size: 18
                      ),
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

// Formatter currency (tidak berubah)
class _CurrencyFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue;
    final intVal =
        int.tryParse(newValue.text.replaceAll('.', ''));
    if (intVal == null) return oldValue;
    final formatted = NumberFormat.currency(
            locale: 'id_ID', symbol: '', decimalDigits: 0)
        .format(intVal);
    return TextEditingValue(
      text: formatted,
      selection:
          TextSelection.collapsed(offset: formatted.length),
    );
  }
}