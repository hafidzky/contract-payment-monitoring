import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../data/providers/contract_provider.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/constants/app_colors.dart';
import 'widgets/document_list.dart';
import 'widgets/log_list.dart';

class ContractDetailPage extends StatefulWidget {
  final Map<String, String> contractData;
  const ContractDetailPage({super.key, required this.contractData});

  @override
  State<ContractDetailPage> createState() => _ContractDetailPageState();
}

class _ContractDetailPageState extends State<ContractDetailPage> {
  int activeTab = 0;
  List<dynamic> _termins = [];
  List<bool> _paidStatesBefore = [];
  late Map<String, dynamic> _currentContractData;
  bool _isLoading = false;
  late TextEditingController _nameController;
  late TextEditingController _typeController;

  // ─── HELPERS ──────────────────────────────────────────────────

  bool _parseBool(dynamic value) {
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true';
    if (value is int) return value == 1;
    return false;
  }

  String _formatRibuan(String digits) {
    if (digits.isEmpty) return '0';
    final n = int.tryParse(digits) ?? 0;
    return n.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
  }

  double _parseAmountToDouble(String raw) {
    String clean = raw
        .replaceAll('Rp', '')
        .replaceAll(' ', '')
        .replaceAll('.', '')
        .replaceAll(',', '')
        .trim();
    return double.tryParse(clean) ?? 0;
  }

  DateTime get _contractEndDate {
    try {
      String timeline = _currentContractData['timeline'] ?? '';
      if (timeline.contains(' - ')) {
        return DateFormat('d-M-yyyy')
            .parse(timeline.split(' - ')[1].trim());
      }
    } catch (_) {}
    return DateTime(2035);
  }

  double get _totalNilaiKontrak =>
      _parseAmountToDouble(_currentContractData['nilai']?.toString() ?? '0');

  String get _contractId => _currentContractData['id']?.toString() ?? widget.contractData['id']?.toString() ?? '';

  // ─── LIFECYCLE ────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _currentContractData = Map<String, dynamic>.from(widget.contractData);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchDataFromDatabase();
    });
    _loadTermins();
    _nameController = TextEditingController(text: _currentContractData['name'] ?? '');
    _typeController = TextEditingController(text: _currentContractData['type'] ?? '');
  }

  // ─── PULL FROM DATABASE ───────────────────────────────────────
  Future<void> _fetchDataFromDatabase() async {
    setState(() => _isLoading = true);
    try {
      // 1. Tarik data segar dari Laravel
      await context.read<ContractProvider>().fetchContracts();
      
      if (!mounted) return;
      final provider = context.read<ContractProvider>();

      // Mengganti firstWhere dengan indexWhere untuk menghindari error 'null comparison'
      final index = provider.allContracts.indexWhere((c) => c['id'].toString() == _contractId);

      if (index != -1) {
        // BONGKAR BUNGKUSAN JSON DARI PROVIDER
        final String rawString = provider.allContracts[index]['raw_json']?.toString() ?? '{}';
        final Map<String, dynamic> rawApiData = jsonDecode(rawString);

        setState(() {
          // --- PROSES TRANSLASI DARI LARAVEL KE UI FLUTTER ---

          // A. Terjemahkan Info Vendor (Deklarasikan sebagai Map secara eksplisit)
          final Map<String, dynamic> vendor = rawApiData['vendor'] ?? {};
          _currentContractData['name'] = vendor['name']?.toString() ?? 'Vendor Tidak Diketahui';
          _currentContractData['type'] = vendor['category']?.toString() ?? '-';

          // B. Terjemahkan Nilai & Status
          _currentContractData['nilai'] = rawApiData['total_value']?.toString() ?? '0';
          final String dbStatus = rawApiData['status']?.toString().toLowerCase() ?? '';
          _currentContractData['status'] = dbStatus == 'active' ? 'Active' : 'Finished';

          // C. Terjemahkan Tanggal (Beri jaminan bahwa ini adalah String, bukan Null)
          try {
            final String rawStart = rawApiData['start_date']?.toString() ?? '';
            final String rawEnd = rawApiData['end_date']?.toString() ?? '';

            final start = DateFormat('yyyy-MM-dd').parse(rawStart);
            final end = DateFormat('yyyy-MM-dd').parse(rawEnd);
            final fmt = DateFormat('d-M-yyyy');
            _currentContractData['timeline'] = '${fmt.format(start)} - ${fmt.format(end)}';
          } catch (_) {
            _currentContractData['timeline'] = '-';
          }

          // D. Terjemahkan Termin
          final List<dynamic> payments = rawApiData['payments'] ?? [];
          final translatedTermins = payments.map((p) {
            String formattedDate = '-';
            try {
              final d = DateFormat('yyyy-MM-dd').parse(p['due_date']?.toString() ?? '');
              formattedDate = DateFormat('dd MMM yyyy').format(d);
            } catch (_) {}
            return {
              'title': p['description'] != null && p['description'].toString() != '-' ? p['description'].toString() : 'Termin ${p['termin_number'] ?? 1}',
              'amount': p['target_amount']?.toString() ?? '0',
              'date': formattedDate,
              'is_paid': p['status'] == 'paid' || p['status'] == 'lunas',
              'notes': p['description']?.toString() ?? '',
            };
          }).toList();

          _currentContractData['termin_data'] = jsonEncode(translatedTermins);
          _loadTermins();
          _nameController.text = _currentContractData['name'] ?? '';
          _typeController.text = _currentContractData['type'] ?? '';
        });
      }
    } catch (e) {
      debugPrint('Error pulling data from database: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _loadTermins() {
    try {
      _termins = jsonDecode(_currentContractData['termin_data'] ?? '[]');
      for (var t in _termins) {
        t['is_paid'] = _parseBool(t['is_paid']);
      }
    } catch (_) {
      _termins = [];
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _typeController.dispose();
    super.dispose();
  }

  // ─── STATUS LOGIC ─────────────────────────────────────────────

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Active':   return Colors.green;
      case 'Finished': return Colors.blue;
      case 'Warning':  return Colors.orange;
      default:         return Colors.grey;
    }
  }

  Map<String, dynamic> _calculateTerminStatus(Map<String, dynamic> termin) {
    if (_parseBool(termin['is_paid'])) {
      return {
        'color':  Colors.green,
        'icon':   Icons.check_circle,
        'text':   'Terbayar',
        'active': true,
      };
    }
    try {
      final terminDate =
          DateFormat('dd MMM yyyy').parse(termin['date'] ?? '');
      final today = DateTime(
          DateTime.now().year, DateTime.now().month, DateTime.now().day);
      final diff = terminDate.difference(today).inDays;

      if (diff < 0) {
        return {
          'color':  Colors.red,
          'icon':   Icons.cancel,
          'text':   'Terlewat ${diff.abs()} Hari',
          'active': true,
        };
      } else if (diff <= 7) {
        return {
          'color':  Colors.orange,
          'icon':   Icons.warning,
          'text':   'Mendekati ($diff Hari)',
          'active': true,
        };
      } else if (diff <= 30) {
        return {
          'color':  Colors.green,
          'icon':   Icons.check_circle,
          'text':   'Aman ($diff Hari)',
          'active': true,
        };
      } else {
        return {
          'color':  Colors.grey,
          'icon':   Icons.schedule,
          'text':   'Menunggu',
          'active': false,
        };
      }
    } catch (_) {
      return {
        'color':  Colors.grey,
        'icon':   Icons.schedule,
        'text':   'Jadwal',
        'active': false,
      };
    }
  }

  // ─── DATE PICKER ──────────────────────────────────────────────

  Future<void> _selectTerminDate(
      int index, StateSetter setDialogState) async {
    DateTime contractStart = DateTime.now();
    try {
      final timeline = _currentContractData['timeline'] ?? '';
      if (timeline.contains(' - ')) {
        contractStart =
            DateFormat('d-M-yyyy').parse(timeline.split(' - ')[0].trim());
      }
    } catch (_) {
      contractStart = DateTime(2020);
    }

    DateTime initial = DateTime.now();
    try {
      initial = DateFormat('dd MMM yyyy').parse(_termins[index]['date']);
      if (initial.isBefore(contractStart)) initial = contractStart;
      if (initial.isAfter(_contractEndDate)) initial = _contractEndDate;
    } catch (_) {
      initial = contractStart;
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: contractStart,
      lastDate: _contractEndDate,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
            colorScheme:
                const ColorScheme.light(primary: AppColors.primary)),
        child: child!,
      ),
    );

    if (picked != null) {
      setDialogState(() {
        _termins[index]['date'] =
            DateFormat('dd MMM yyyy').format(picked);
      });
      setState(() {});
    }
  }

  // ─── EDIT DIALOG ──────────────────────────────────────────────

  void _showFullEditDialog() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile    = screenWidth < 600;

    _paidStatesBefore =
        _termins.map<bool>((t) => _parseBool(t['is_paid'])).toList();

    // Controller nominal per termin — dibuat fresh setiap dialog dibuka
    final nominalControllers = List.generate(_termins.length, (i) {
      final raw    = _termins[i]['amount']?.toString() ?? '0';
      final digits = raw
          .replaceAll('Rp', '')
          .replaceAll('.', '')
          .replaceAll(',', '')
          .replaceAll(' ', '')
          .trim();
      final val    = int.tryParse(digits) ?? 0;
      final fmt    = _formatRibuan(val.toString());
      final ctrl   = TextEditingController(text: fmt);
      ctrl.selection = TextSelection.collapsed(offset: fmt.length);
      return ctrl;
    });

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          // ── Hitung total & balance di dalam StatefulBuilder
          //    agar selalu ikut update saat setDialogState dipanggil
          double totalTermin = 0;
          for (var t in _termins) {
            totalTermin +=
                _parseAmountToDouble(t['amount']?.toString() ?? '0');
          }
          final isBalanced =
              (_totalNilaiKontrak - totalTermin).abs() < 100;

          return AlertDialog(
            insetPadding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 24),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            title: const Text(
              'Edit Informasi Kontrak',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                  fontSize: 22),
            ),
            content: SizedBox(
              width: isMobile ? screenWidth : 650,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // ── Informasi Utama
                    const Text('INFORMASI UTAMA',
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: Colors.grey,
                            fontSize: 12,
                            letterSpacing: 1.2)),
                    const SizedBox(height: 16),

                    _buildTextField(
                      controller: _nameController,
                      label: 'Nama Vendor',
                      icon: Icons.business,
                  onChanged: (v) => setState(
                      () => _currentContractData['name'] = v),
                    ),
                    const SizedBox(height: 16),

                    _buildTextField(
                      controller: _typeController,
                      label: 'Kategori',
                      icon: Icons.category,
                  onChanged: (v) => setState(
                      () => _currentContractData['type'] = v),
                    ),
                    const SizedBox(height: 32),

                    // ── Detail Termin Header
                    const Text('DETAIL TERMIN & PEMBAYARAN',
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: Colors.grey,
                            fontSize: 12,
                            letterSpacing: 1.2)),
                    const SizedBox(height: 10),

                    // ── Summary Balance — langsung pakai variabel
                    //    dari StatefulBuilder, bukan Builder terpisah
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isBalanced
                            ? Colors.green.shade50
                            : Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isBalanced
                              ? Colors.green.shade200
                              : Colors.orange.shade200,
                        ),
                      ),
                      child: Row(children: [
                        Icon(
                          isBalanced
                              ? Icons.check_circle_outline
                              : Icons.info_outline,
                          size: 16,
                          color: isBalanced
                              ? Colors.green.shade700
                              : Colors.orange.shade700,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            isBalanced
                                ? 'Total termin sesuai nilai kontrak'
                                : 'Total: ${CurrencyFormatter.toFullRupiah(totalTermin)} '
                                    '/ ${CurrencyFormatter.toFullRupiah(_totalNilaiKontrak)}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isBalanced
                                  ? Colors.green.shade700
                                  : Colors.orange.shade700,
                            ),
                          ),
                        ),
                      ]),
                    ),

                    const SizedBox(height: 8),
                    const Divider(),
                    const SizedBox(height: 12),

                    // ── List Termin
                    ...List.generate(_termins.length, (i) {
                      // Hitung sisa yang boleh untuk termin ini
                      double otherTotal = _termins
                          .asMap()
                          .entries
                          .where((e) => e.key != i)
                          .fold(
                            0.0,
                            (sum, e) => sum +
                                _parseAmountToDouble(
                                    e.value['amount']?.toString() ?? '0'),
                          );
                      final maxAllowed  = _totalNilaiKontrak - otherTotal;
                      final currentVal  = _parseAmountToDouble(
                          _termins[i]['amount']?.toString() ?? '0');
                      final isOverLimit = currentVal > maxAllowed + 1;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFF),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isOverLimit
                                ? Colors.red.shade200
                                : Colors.blue.shade100,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [

                            // Judul + Checkbox Lunas
                            Row(children: [
                              Expanded(
                                child: _buildTextField(
                                  label: 'Judul Termin',
                                  initialValue: _termins[i]['title'],
                                  onChanged: (v) => setState(
                                      () => _termins[i]['title'] = v),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(children: [
                                const Text('LUNAS',
                                    style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey)),
                                Checkbox(
                                  value: _parseBool(
                                      _termins[i]['is_paid']),
                                  activeColor: Colors.green,
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(4)),
                                  onChanged: (val) {
                                    setDialogState(() {
                                      _termins[i]['is_paid'] =
                                          val == true;
                                      if (val == true) {
                                        _termins[i]['paid_date'] =
                                            DateFormat('dd MMM yyyy')
                                                .format(DateTime.now());
                                      } else {
                                        _termins[i].remove('paid_date');
                                      }
                                    });
                                    setState(() {});
                                  },
                                ),
                              ]),
                            ]),
                            const SizedBox(height: 16),

                            // Nominal
                            _buildNominalField(
                              index:          i,
                              controller:     nominalControllers[i],
                              maxAllowed:     maxAllowed,
                              isOverLimit:    isOverLimit,
                              setDialogState: setDialogState,
                            ),
                            const SizedBox(height: 12),

                            // Tanggal
                            SizedBox(
                              width: double.infinity,
                              child: _buildDateButton(
                                dateText: _termins[i]['date'],
                                onTap: () => _selectTerminDate(
                                    i, setDialogState),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            actionsPadding:
                const EdgeInsets.fromLTRB(24, 0, 24, 24),
            actions: [
              Row(
                children: [
                  // Tombol Batal
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        // Reset semua perubahan ke kondisi awal
                        _loadTermins();
                        _nameController.text =
                        _currentContractData['name'] ?? '';
                        _typeController.text =
                        _currentContractData['type'] ?? '';
                        setState(() {});
                        Navigator.pop(ctx);
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      child: const Text(
                        'Batal',
                        style: TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                            fontSize: 15),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Tombol Simpan
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () => _saveChanges(ctx),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(
                            vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Simpan Perubahan',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    ).then((_) {
      for (final c in nominalControllers) {
        c.dispose();
      }
    });
  }

  // ─── SAVE ─────────────────────────────────────────────────────

  void _saveChanges(BuildContext dialogCtx) {
    double totalTermin = 0;
    for (var t in _termins) {
      totalTermin +=
          _parseAmountToDouble(t['amount']?.toString() ?? '0');
    }

    if ((_totalNilaiKontrak - totalTermin).abs() > 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Total nominal (${CurrencyFormatter.toFullRupiah(totalTermin)}) '
            'tidak sesuai nilai kontrak '
            '(${CurrencyFormatter.toFullRupiah(_totalNilaiKontrak)})',
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    final provider =
        Provider.of<ContractProvider>(context, listen: false);
    final updateJson = jsonEncode(_termins);
    final index = provider.allContracts
        .indexWhere((c) => c['id']?.toString() == _contractId);

    if (index != -1) {
      _currentContractData['name']        = _nameController.text;
      _currentContractData['type']        = _typeController.text;
      _currentContractData['termin_data'] = updateJson;
      
      widget.contractData['name']        = _nameController.text;
      widget.contractData['type']        = _typeController.text;
      widget.contractData['termin_data'] = updateJson;

      provider.updateContractTermin(index, updateJson);
      provider.validateAndFinishContract(index);
      provider.addLog(
          _contractId, 'Informasi kontrak diperbarui', 'edit');

      for (int ti = 0; ti < _termins.length; ti++) {
        final wasPaid = ti < _paidStatesBefore.length
            ? _paidStatesBefore[ti]
            : false;
        final isPaidNow = _parseBool(_termins[ti]['is_paid']);

        if (!wasPaid && isPaidNow) {
          provider.addLog(
            _contractId,
            'Pembayaran "${_termins[ti]['title']}" ditandai lunas',
            'payment',
          );
        } else if (wasPaid && !isPaidNow) {
          provider.addLog(
            _contractId,
            'Pembayaran "${_termins[ti]['title']}" dibatalkan lunas',
            'edit',
          );
        }
      }

      setState(() => _termins = jsonDecode(updateJson));
    }
    Navigator.pop(dialogCtx);
  }

  // ─── FORM WIDGETS ─────────────────────────────────────────────

  Widget _buildTextField({
    String? label,
    TextEditingController? controller,
    String? initialValue,
    IconData? icon,
    Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller ??
          (initialValue != null
              ? TextEditingController(text: initialValue)
              : null),
      onChanged: onChanged,
      style: const TextStyle(
          fontSize: 14, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            const TextStyle(color: Colors.grey, fontSize: 13),
        prefixIcon: icon != null
            ? Icon(icon, size: 20, color: AppColors.primary)
            : null,
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade200)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(
                color: AppColors.primary, width: 1.5)),
      ),
    );
  }

  Widget _buildNominalField({
    required int index,
    required TextEditingController controller,
    required double maxAllowed,
    required bool isOverLimit,
    required StateSetter setDialogState,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            _RibuanFormatter(),
          ],
          style: const TextStyle(
              fontSize: 14, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            labelText: 'Nominal Pembayaran',
            labelStyle:
                const TextStyle(color: Colors.grey, fontSize: 13),
            prefixText: 'Rp ',
            prefixIcon: const Icon(Icons.payments_outlined,
                size: 20, color: AppColors.primary),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 12),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                    color: isOverLimit
                        ? Colors.red
                        : Colors.grey.shade300)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                    color: isOverLimit
                        ? Colors.red.shade300
                        : Colors.grey.shade200)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                    color: isOverLimit ? Colors.red : AppColors.primary,
                    width: 1.5)),
          ),
          onChanged: (val) {
            final digits   = val.replaceAll('.', '');
            final inputVal = double.tryParse(digits) ?? 0;

            // Hitung otherTotal secara manual agar akurat
            double otherTotal = 0;
            for (int j = 0; j < _termins.length; j++) {
              if (j != index) {
                otherTotal += _parseAmountToDouble(
                    _termins[j]['amount']?.toString() ?? '0');
              }
            }
            final max = _totalNilaiKontrak - otherTotal;

            if (inputVal > max && max >= 0) {
              // Cap ke nilai maksimal
              final cappedDigits = max.toInt().toString();
              final formatted    = _formatRibuan(cappedDigits);
              controller.value = TextEditingValue(
                text: formatted,
                selection:
                    TextSelection.collapsed(offset: formatted.length),
              );
              setDialogState(() {
                _termins[index]['amount'] =
                    'Rp ${_formatRibuan(cappedDigits)}';
              });
            } else {
              setDialogState(() {
                _termins[index]['amount'] =
                    'Rp ${_formatRibuan(digits)}';
              });
            }
            setState(() {});
          },
        ),

        // Warning inline jika over limit
        if (isOverLimit)
          Padding(
            padding: const EdgeInsets.only(top: 5, left: 4),
            child: Row(children: [
              Icon(Icons.error_outline,
                  size: 13, color: Colors.red.shade600),
              const SizedBox(width: 4),
              Text(
                'Maks: Rp ${_formatRibuan(maxAllowed.toInt().toString())}',
                style: TextStyle(
                    fontSize: 11, color: Colors.red.shade600),
              ),
            ]),
          ),
      ],
    );
  }

  Widget _buildDateButton({
    required String dateText,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.calendar_month,
                size: 18, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              dateText,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }

  // ─── BUILD ────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop   = screenWidth > 1100;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Detail Kontrak: ${_currentContractData['id'] ?? '-'}',
          style: const TextStyle(
              fontWeight: FontWeight.bold, fontSize: 16),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primary,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          vertical:   isDesktop ? 40 : 16,
          horizontal: isDesktop ? screenWidth * 0.1 : 16,
        ),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1000),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: const Color(0xFFD1D9E6), width: 2),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              if (_isLoading)
                const LinearProgressIndicator(color: AppColors.primary),
                _buildHeader(),
                const Divider(height: 1, thickness: 1),
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Milestone Timeline',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppColors.primary),
                      ),
                      const SizedBox(height: 20),
                      _buildTimeline(),
                      const SizedBox(height: 40),
                      _buildTabs(),
                      const SizedBox(height: 24),
                      _buildTabContent(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── HEADER ───────────────────────────────────────────────────

  Widget _buildHeader() {
    String rawStatus     = _currentContractData['status'] ?? 'Unknown';
    String displayStatus = rawStatus;
    Color  statusColor   = _getStatusColor(rawStatus);

    if (rawStatus == 'Active') {
      final hasIssue = _termins.any((t) {
        final s = _calculateTerminStatus(t);
        return s['color'] == Colors.orange ||
               s['color'] == Colors.red;
      });
      if (hasIssue) {
        displayStatus = 'WARNING';
        statusColor   = Colors.orange;
      }
    }

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                _currentContractData['name'] ?? 'Vendor Tidak Diketahui',
                  style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary),
                ),
                Text(
                _currentContractData['type'] ?? 'Kategori Umum',
                  style: const TextStyle(
                      color: Colors.grey, fontSize: 14),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 32,
                  runSpacing: 16,
                  children: [
                    _infoLabel(
                      'NILAI KONTRAK',
                      CurrencyFormatter.toFullRupiah(
                        _currentContractData['nilai']?.toString() ?? '0'),
                    ),
                    _infoLabel(
                      'TIMELINE',
                    _currentContractData['timeline'] ?? '-',
                      isRed: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              IconButton(
                onPressed: _showFullEditDialog,
                icon: const Icon(Icons.edit_note,
                    color: AppColors.primary, size: 28),
                tooltip: 'Ubah Data Kontrak',
              ),
              const SizedBox(height: 4),
              _statusBadge(displayStatus, statusColor),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
            color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _infoLabel(String label, String val, {bool isRed = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 10,
                color: Colors.grey,
                fontWeight: FontWeight.bold)),
        Text(val,
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isRed ? Colors.red : Colors.black87)),
      ],
    );
  }

  // ─── TIMELINE ─────────────────────────────────────────────────

  Widget _buildTimeline() {
    final count   = _termins.isNotEmpty ? _termins.length : 4;
    final widgets = <Widget>[];

    for (int i = 0; i < count; i++) {
      final termin = Map<String, dynamic>.from(_termins[i]);
      final status = _calculateTerminStatus(termin);
      widgets.add(_timelineNode(
          'T${i + 1}', status['icon'], status['color'], status['active']));
      if (i < count - 1) {
        widgets.add(_timelineLine(status['color'] == Colors.green));
      }
    }

    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: widgets),
      ),
    );
  }

  Widget _timelineLine(bool isPaid) => Container(
        width: 60,
        height: 2,
        color: isPaid ? Colors.green : Colors.grey.shade300,
        margin: const EdgeInsets.only(bottom: 14),
      );

  Widget _timelineNode(
      String label, IconData icon, Color col, bool active) {
    return Column(children: [
      Icon(icon, size: 18, color: col),
      const SizedBox(height: 4),
      Text(label,
          style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: col)),
    ]);
  }

  // ─── TABS ─────────────────────────────────────────────────────

  Widget _buildTabs() {
    return Row(children: [
      _tabItem('Jadwal', 0),
      const SizedBox(width: 32),
      _tabItem('Dokumen', 1),
      const SizedBox(width: 32),
      _tabItem('Log', 2),
    ]);
  }

  Widget _tabItem(String label, int index) {
    final isActive = activeTab == index;
    int? count;

    if (index == 1) {
      count = context
          .watch<ContractProvider>()
          .getDocumentsForContract(_contractId)
          .length;
    } else if (index == 2) {
      count = context
          .watch<ContractProvider>()
          .getLogsForContract(_contractId)
          .length;
    }

    return GestureDetector(
      onTap: () => setState(() => activeTab = index),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Text(label,
                  style: TextStyle(
                      fontWeight:
                          isActive ? FontWeight.bold : FontWeight.w500,
                      color: isActive ? AppColors.primary : Colors.grey,
                      fontSize: 15)),
              if (count != null && count > 0) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.primary
                        : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('$count',
                      style: TextStyle(
                          fontSize: 10,
                          color: isActive
                              ? Colors.white
                              : Colors.grey.shade600,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ]),
            const SizedBox(height: 4),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 3,
              width: isActive ? 24 : 0,
              color: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (activeTab) {
      case 0:  return _buildTerminList();
      case 1:  return DocumentListWidget(contractId: _contractId);
      case 2:  return LogListWidget(contractId: _contractId);
      default: return _buildTerminList();
    }
  }

  // ─── TERMIN LIST ──────────────────────────────────────────────

  Widget _buildTerminList() {
    if (_termins.isEmpty) {
      return Column(children: [
        _terminRow(
            'Termin 1', 'Rp 0', 'Belum Diatur', Colors.grey, 'Unknown', ''),
      ]);
    }

    return Column(
      children: List.generate(_termins.length, (i) {
        final termin = _termins[i];
        final status = _calculateTerminStatus(termin);
        return Column(children: [
          _terminRow(
            termin['title'] ?? 'Termin',
            termin['amount'] ?? '-',
            termin['date'] ?? '-',
            status['color'],
            status['text'],
            termin['notes']?.toString() ?? '',
          ),
          if (i < _termins.length - 1) const Divider(),
        ]);
      }),
    );
  }

  Widget _terminRow(
    String title,
    String val,
    String date,
    Color col,
    String statusText,
    String notes,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(children: [
        Icon(Icons.payment, color: col, size: 24),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 10,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(date,
                      style: const TextStyle(
                          fontSize: 12, color: Colors.grey)),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                        color: col.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4)),
                    child: Text(statusText,
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: col)),
                  ),
                ],
              ),
              if (notes.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(children: [
                    Icon(Icons.notes,
                        size: 12, color: Colors.grey.shade400),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        notes,
                        style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                            fontStyle: FontStyle.italic),
                      ),
                    ),
                  ]),
                ),
            ],
          ),
        ),
        Text(
          CurrencyFormatter.toFullRupiah(val),
          style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: AppColors.primary),
        ),
      ]),
    );
  }
}

// ─── RIBUAN FORMATTER ─────────────────────────────────────────
class _RibuanFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll('.', '');
    if (digits.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }
    final n         = int.tryParse(digits) ?? 0;
    final formatted = n.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}