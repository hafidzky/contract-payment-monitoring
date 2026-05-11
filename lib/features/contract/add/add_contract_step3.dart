import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/contract_document.dart';
import 'add_contract_step4.dart';
import '../widgets/step_indicator.dart';

class AddContractTerminPage extends StatefulWidget {
  final String vendorName;
  final String noKontrak;
  final String namaPekerjaan;
  final double totalNilaiKontrak;
  final String startDate;
  final String endDate;
  final List<ContractDocument> uploadedDocs;

  const AddContractTerminPage({
    super.key,
    required this.vendorName,
    required this.noKontrak,
    required this.namaPekerjaan,
    required this.totalNilaiKontrak,
    required this.startDate,
    required this.endDate,
    required this.uploadedDocs,
  });

  @override
  State<AddContractTerminPage> createState() => _AddContractTerminPageState();
}

class _AddContractTerminPageState extends State<AddContractTerminPage> {
  final List<Map<String, dynamic>> _termins = [];
  final Map<int, bool> _overLimitMap = {};
  final Set<int> _duplicateDateIndexes = {};
  
  // ← Throttle snackbar agar tidak berulang
  DateTime? _lastSnackbarTime;

  // Parse startDate dari step 2 (format: d-M-yyyy)
  DateTime get _contractStartDate {
    try {
      final parts = widget.startDate.split('-');
      return DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
    } catch (_) {
      return DateTime.now();
    }
  }

  DateTime get _contractEndDate {
    try {
      final parts = widget.endDate.split('-');
      return DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
    } catch (_) {
      return DateTime(2035);
    }
  }

  @override
  void initState() {
    super.initState();
    _addEmptyTermin();
  }

  void _addEmptyTermin() {
    setState(() {
      _termins.add({
        'title':       'Termin ${_termins.length + 1}',
        'nominal':     0.0,
        'dueDate':     _contractStartDate, 
        'notes':       '',
        'nominalCtrl': TextEditingController(),
        'notesCtrl':   TextEditingController(),
      });
    });
  }

  void _removeTermin(int index) {
    if (_termins.length > 1) {
      setState(() {
        (_termins[index]['nominalCtrl'] as TextEditingController).dispose();
        (_termins[index]['notesCtrl'] as TextEditingController).dispose();
        _termins.removeAt(index);
        for (int i = 0; i < _termins.length; i++) {
          _termins[i]['title'] = 'Termin ${i + 1}';
        }
      });
    }
  }

  double _calculateCurrentTotal() {
    double total = 0;
    for (var t in _termins) {
      total += (t['nominal'] as double);
    }
    return total;
  }

  bool _isDateAlreadyUsed(DateTime date, int currentIndex) {
    for (int i = 0; i < _termins.length; i++) {
      if (i == currentIndex) continue;
      final otherDate = _termins[i]['dueDate'] as DateTime;
      if (otherDate.year == date.year &&
          otherDate.month == date.month &&
          otherDate.day == date.day) {
        return true;
      }
    }
    return false;
  }

  // ← Throttle: hanya tampil snackbar max 1x per 2 detik
  void _showSnackbarOnce(String msg, Color color) {
    final now = DateTime.now();
    if (_lastSnackbarTime != null && now.difference(_lastSnackbarTime!).inSeconds < 2) return;
    _lastSnackbarTime = now;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  void dispose() {
    for (var t in _termins) {
      (t['nominalCtrl'] as TextEditingController).dispose();
      (t['notesCtrl'] as TextEditingController).dispose();
    }
    super.dispose();
  }

  void _handleNext() {
    setState(() => _duplicateDateIndexes.clear());

    // Cek duplikat tanggal
    bool hasDuplicate = false;
    for (int i = 0; i < _termins.length; i++) {
      for (int j = i + 1; j < _termins.length; j++) {
        final dateA = _termins[i]['dueDate'] as DateTime;
        final dateB = _termins[j]['dueDate'] as DateTime;
        if (dateA.year == dateB.year &&
            dateA.month == dateB.month &&
            dateA.day == dateB.day) {
          setState(() {
            _duplicateDateIndexes.add(i);
            _duplicateDateIndexes.add(j);
          });
          hasDuplicate = true;
        }
      }
    }
    if (hasDuplicate) return;

    // Cek total nominal
    final double currentTotal = _calculateCurrentTotal();
    if ((currentTotal - widget.totalNilaiKontrak).abs() > 0.1) {
      _showSnackbarOnce('Total termin belum sesuai nilai kontrak.', Colors.red);
      return;
    }

    final List<Map<String, dynamic>> finalTerminList = _termins.map((t) {
      return {
        'title':   t['title'].toString(),
        'nominal': (t['nominal'] as double).toString(),
        'date':    DateFormat('dd MMM yyyy').format(t['dueDate'] as DateTime),
        'amount':  CurrencyFormatter.toFullRupiah(t['nominal']),
        'notes':   t['notes'].toString(),
        'status':  'Menunggu Pembayaran',
        'is_paid': false,
      };
    }).toList();

    Navigator.push(
      context, 
      MaterialPageRoute(
        builder: (_) => AddContractReviewPage(
          vendorName:        widget.vendorName,
          noKontrak:         widget.noKontrak,
          namaPekerjaan:     widget.namaPekerjaan,
          totalNilaiKontrak: widget.totalNilaiKontrak,
          startDate:         widget.startDate,
          endDate:           widget.endDate,
          terminList:        finalTerminList,
          uploadedDocs:      widget.uploadedDocs,
        ),
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    final double currentTotal = _calculateCurrentTotal();
    final double remaining    = widget.totalNilaiKontrak - currentTotal;
    final bool   isBalanced   = remaining.abs() < 0.1;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
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
                          child: StepIndicator(current: 3),
                        ),
                      ),
                      const SizedBox(height: 32),
                      const Text('Jadwal Termin',
                        style: TextStyle(fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary)),
                      const SizedBox(height: 4),
                      const Text('Atur jadwal pembayaran kontrak secara manual.',
                        style: TextStyle(color: Colors.grey, fontSize: 13)),
                      const SizedBox(height: 20),

                      _buildSummaryCard(currentTotal, remaining, isBalanced),
                      const SizedBox(height: 20),

                      const Text('Detail Termin',
                        style: TextStyle(fontWeight: FontWeight.w600,
                          fontSize: 14, color: Colors.black87)),
                      const SizedBox(height: 12),

                      ...List.generate(_termins.length, (i) => _buildTerminCard(i)),

                      OutlinedButton.icon(
                        onPressed: _addEmptyTermin,
                        icon: const Icon(Icons.add_circle_outline, size: 18),
                        label: const Text('Tambah Termin'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          minimumSize: const Size(double.infinity, 48),
                          side: const BorderSide(color: AppColors.primary, width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ),
          ),
          _buildBottomBar(),
        ],
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
            style: TextStyle(color: Colors.white,
              fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(double currentTotal, double remaining, bool isBalanced) {
    // Status warna & label sisa
    final Color remainColor;
    final String remainLabel;
    final IconData remainIcon;

    if (isBalanced) {
      remainColor = Colors.greenAccent;
      remainLabel = 'Pas';
      remainIcon  = Icons.check_circle_outline;
    } else if (remaining > 0) {
      remainColor = Colors.orangeAccent;
      remainLabel = 'Kurang ${CurrencyFormatter.toFullRupiah(remaining)}';
      remainIcon  = Icons.info_outline;
    } else {
      remainColor = Colors.redAccent;
      remainLabel = 'Lebih ${CurrencyFormatter.toFullRupiah(remaining.abs())}';
      remainIcon  = Icons.warning_amber_outlined;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF002753), Color(0xFF134684)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(
          color: AppColors.primary.withValues(alpha: 0.3),
          blurRadius: 12, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Baris atas: total nilai + status sisa
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total Nilai Kontrak',
                    style: TextStyle(color: Colors.white70, fontSize: 11)),
                  const SizedBox(height: 2),
                  Text(
                    CurrencyFormatter.toFullRupiah(widget.totalNilaiKontrak),
                    style: const TextStyle(color: Colors.white,
                      fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              // ← Status inline di kanan atas
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: remainColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: remainColor.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(remainIcon, size: 13, color: remainColor),
                    const SizedBox(width: 5),
                    Text(remainLabel,
                      style: TextStyle(fontSize: 11,
                        fontWeight: FontWeight.bold, color: remainColor)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Baris bawah: terpakai & sisa angka
          Row(children: [
            _infoTile('Terpakai',
              CurrencyFormatter.toFullRupiah(currentTotal),
              Colors.white),
            const SizedBox(width: 24),
            _infoTile('Sisa',
              CurrencyFormatter.toFullRupiah(remaining.abs()),
              remainColor),
          ]),
        ],
      ),
    );
  }

  Widget _infoTile(String label, String value, Color valColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(color: valColor,
          fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }

  Widget _buildTerminCard(int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), // ← lebih compact
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                Container(
                  width: 26, height: 26,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(
                    child: Text('${index + 1}',
                      style: const TextStyle(fontWeight: FontWeight.bold,
                        fontSize: 12, color: AppColors.primary)),
                  ),
                ),
                const SizedBox(width: 8),
                Text(_termins[index]['title'] as String,
                  style: const TextStyle(fontWeight: FontWeight.bold,
                    fontSize: 14, color: AppColors.primary)),
              ]),
              if (_termins.length > 1)
                SizedBox(
                  width: 32, height: 32,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: Icon(Icons.delete_outline,
                      color: Colors.red.shade400, size: 18),
                    onPressed: () => _removeTermin(index),
                  ),
                ),
            ],
          ),
          const Divider(height: 14),

          // 2 kolom: Jatuh Tempo | Nominal
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Jatuh Tempo
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Jatuh Tempo',
                      style: TextStyle(fontSize: 11,
                        color: Colors.grey, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _termins[index]['dueDate'] as DateTime,
                          firstDate: _contractStartDate,
                          lastDate: _contractEndDate,
                          builder: (ctx, child) => Theme(
                            data: Theme.of(ctx).copyWith(
                              colorScheme: const ColorScheme.light(
                                primary: AppColors.primary)),
                            child: child!,
                          ),
                        );
                        if (picked != null) {
                          if (_isDateAlreadyUsed(picked, index)) {
                            if (!mounted) return;
                            // reset snackbar, pakai inline saja
                            return;
                          }
                          setState(() {
                            _termins[index]['dueDate'] = picked;
                            _duplicateDateIndexes.remove(index); // ← reset jika sudah ganti
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        decoration: BoxDecoration(
                          color: _duplicateDateIndexes.contains(index)
                              ? Colors.red.shade50
                              : const Color(0xFFF8F9FF),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _duplicateDateIndexes.contains(index)
                                ? Colors.red.shade400
                                : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: Row(children: [
                          Icon(Icons.calendar_today,
                            size: 14,
                            color: _duplicateDateIndexes.contains(index)
                                ? Colors.red
                                : AppColors.primary),
                          const SizedBox(width: 6),
                          Text(
                            DateFormat('dd MMM yyyy')
                              .format(_termins[index]['dueDate'] as DateTime),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _duplicateDateIndexes.contains(index)
                                  ? Colors.red
                                  : AppColors.primary,
                            ),
                          ),
                        ]),
                      ),
                    ),
                    // ← Warning inline duplikat tanggal
                    if (_duplicateDateIndexes.contains(index))
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, size: 12, color: Colors.red.shade600),
                            const SizedBox(width: 4),
                            Text(
                              'Tanggal sama dengan termin lain',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.red.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Nominal
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Nominal (Rp)',
                      style: TextStyle(fontSize: 11,
                        color: Colors.grey, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _termins[index]['nominalCtrl']
                          as TextEditingController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(fontSize: 13),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        _ThousandSeparatorFormatter(),
                      ],
                      decoration: InputDecoration(
                        hintText: '0',
                        prefixText: 'Rp ',
                        prefixStyle: const TextStyle(fontSize: 13),
                        isDense: true,
                        filled: true,
                        fillColor: (_overLimitMap[index] == true)
                            ? Colors.red.shade50
                            : const Color(0xFFF8F9FF),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: (_overLimitMap[index] == true)
                                ? Colors.red
                                : AppColors.primary,
                            width: 1.5),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 10),
                      ),
                      onChanged: (val) {
                        final clean = double.tryParse(val.replaceAll('.', '')) ?? 0.0;
                        final double otherTotal = _termins
                          .asMap().entries
                          .where((e) => e.key != index)
                          .fold(0.0, (sum, e) =>
                            sum + (e.value['nominal'] as double));
                        final double maxAllowed = widget.totalNilaiKontrak - otherTotal;

                        if (clean > maxAllowed && maxAllowed >= 0) {
                          final capped = maxAllowed;
                          final formatted = NumberFormat('#,###', 'id_ID')
                            .format(capped.toInt());
                          final ctrl = _termins[index]['nominalCtrl']
                            as TextEditingController;
                          ctrl.value = TextEditingValue(
                            text: formatted,
                            selection: TextSelection.collapsed(
                              offset: formatted.length),
                          );
                          setState(() {
                            _termins[index]['nominal'] = capped;
                            _overLimitMap[index] = true;
                          });
                        } else {
                          setState(() {
                            _termins[index]['nominal'] = clean;
                            _overLimitMap[index] = false;
                          });
                        }
                      },  
                    ),
                    if (_overLimitMap[index] == true)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, size: 12, color: Colors.orange.shade700),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                'Melebihi sisa nilai kontrak',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.orange.shade700,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Keterangan
          const Text('Keterangan (Opsional)',
            style: TextStyle(fontSize: 11,
              color: Colors.grey, fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          TextFormField(
            controller: _termins[index]['notesCtrl'] as TextEditingController,
            maxLines: 2,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Contoh: DP awal, pekerjaan fase 1, dll.',
              isDense: true,
              filled: true,
              fillColor: const Color(0xFFF8F9FF),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: AppColors.primary, width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 10),
            ),
            onChanged: (val) => _termins[index]['notes'] = val,
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
        boxShadow: [BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
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
                  onPressed: _handleNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text('Lanjut',
                    style: TextStyle(color: Colors.white,
                      fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThousandSeparatorFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue;
    final clean = newValue.text.replaceAll('.', '');
    final intVal = int.tryParse(clean);
    if (intVal == null) return oldValue;
    final formatted = NumberFormat('#,###', 'id_ID').format(intVal);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}