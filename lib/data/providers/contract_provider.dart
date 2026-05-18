import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/utils/contract_helper.dart';
import '../models/contract_log.dart';
import '../models/contract_document.dart';

class ContractProvider with ChangeNotifier {
  final List<Map<String, String>> _allContracts = [];
  static const String _storageKey = 'contracts_data';
  final List<dynamic> _contracts = [];

  final Map<String, List<ContractLog>> _contractLogs = {};
  final Map<String, List<ContractDocument>> _contractDocuments = {};

  List<Map<String, String>> get allContracts => _allContracts;
  int get totalContracts => _allContracts.length;
  int get activeContracts =>
      _allContracts.where((c) => c['status'] == 'Active').length;
  int get warningContracts {
    return _allContracts.where((contract) {
      return ContractHelper.isContractWarning(contract['termin_data']);
    }).length;
  }

  bool _isLoading = false;
  List<dynamic> get contracts => _contracts;
  bool get isLoading => _isLoading;

  // LOAD dari SharedPreferences saat app start
  Future<void> loadContracts() async {
    _isLoading = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final String? jsonStr = prefs.getString(_storageKey);
    if (jsonStr != null) {
      final List<dynamic> decoded = jsonDecode(jsonStr);
      _allContracts.clear();
      _allContracts.addAll(
        decoded
            .map((e) => Map<String, String>.from(
                (e as Map).map((k, v) => MapEntry(k.toString(), v?.toString() ?? ''))))
            .toList(),
      );
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchContracts() async {
    _isLoading = true;
    notifyListeners();

    try {
      final url = Uri.parse('http://127.0.0.1:8000/api/v1/contracts');
      final response = await http.get(
        url,
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final List<dynamic> rawData = responseData['data'] ?? [];

        _contracts.clear();

        for (var item in rawData) {
          // 1. Ambil relasi vendor
          final vendor = item['vendor'] ?? {};

          // 2. Terjemahkan Timeline
          String timelineStr = '-';
          try {
            final start = DateFormat('yyyy-MM-dd').parse(item['start_date']?.toString() ?? '');
            final end = DateFormat('yyyy-MM-dd').parse(item['end_date']?.toString() ?? '');
            timelineStr = '${DateFormat('d-M-yyyy').format(start)} - ${DateFormat('d-M-yyyy').format(end)}';
          } catch (_) {}

          // SEMUA VALUE DI BAWAH INI SEKARANG DIJAMIN STRING (Aman untuk UI)
          _contracts.add({
            'id': item['id']?.toString() ?? '',
            'name': vendor['name']?.toString() ?? 'Vendor Tidak Diketahui',
            'nilai': item['total_value']?.toString() ?? '0',
            'timeline': timelineStr,
            'status': item['status']?.toString() == 'active' ? 'Active' : 'Finished',
            'termin_data': jsonEncode(item['payments'] ?? []),
            
            // --- INI PENYELUNDUPNYA ---
            'raw_json': jsonEncode(item),
          });
        }
      } else {
        debugPrint('Gagal tarik data: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[ContractProvider] Fetch Error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // SAVE ke SharedPreferences
  Future<void> _saveContracts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(_allContracts));
  }

  Future<bool> createContract(Map<String, dynamic> contractData) async {
    try {
      final url = Uri.parse('http://127.0.0.1:8000/api/v1/contracts');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(contractData), // contractData ini bola salju dari Layar 1-4
      );

      if (response.statusCode == 201) {
        // Berhasil masuk MySQL!
        return true;
      } else {
        debugPrint('Server menolak: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Gagal POST kontrak: $e');
      return false;
    }
  }

  // MESIN UTAMA UNTUK KIRIM KONTRAK DAN TERMIN KEMBAR KE LARAVEL
  Future<bool> addContract(Map<String, dynamic> payload) async {
    _isLoading = true;
    notifyListeners();

    try {
      final url = Uri.parse('http://127.0.0.1:8000/api/v1/contracts');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(payload), // Mengubah Map Flutter menjadi JSON murni
      );

      if (response.statusCode == 201) {
        debugPrint('Kontrak Sukses Disimpan di MySQL');
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        debugPrint('Laravel Menolak Data (Status ${response.statusCode}): ${response.body}');
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('[ContractProvider] Error POST Kontrak: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void deleteContract(String contractId) {
    _contractLogs.remove(contractId);
    _contractDocuments.remove(contractId);
    _allContracts.removeWhere((c) => c['id'] == contractId);
    _saveContracts();
    notifyListeners();
  }

  void updateContractTermin(int index, String updatedTerminJson) {
    if (index >= 0 && index < _allContracts.length) {
      _allContracts[index]['termin_data'] = updatedTerminJson;
      _saveContracts();
      notifyListeners();
    }
  }

  void validateAndFinishContract(int index) {
    if (index < 0 || index >= _allContracts.length) return;
    try {
      String jsonStr = _allContracts[index]['termin_data'] ?? '[]';
      List<dynamic> termins = jsonDecode(jsonStr);
      bool allPaid = termins.every((t) => t['is_paid'] == true);
      if (allPaid && termins.isNotEmpty) {
        _allContracts[index]['status'] = 'Finished';
      } else {
        _allContracts[index]['status'] = 'Active';
      }
      _saveContracts();
      notifyListeners();
    } catch (e) {
      debugPrint("Error validasi status: $e");
    }
  }

  // ==================== LOG METHODS ====================

  List<ContractLog> getLogsForContract(String contractId) {
    return _contractLogs[contractId] ?? [];
  }

  void addLog(String contractId, String activity, String icon) {
    final now = DateTime.now();
    final timeStr =
        '${now.day}/${now.month}/${now.year} '
        '${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}';

    final log = ContractLog(activity: activity, time: timeStr, icon: icon);
    _contractLogs[contractId] = [log, ...(_contractLogs[contractId] ?? [])];
    notifyListeners();
  }

  // ==================== DOCUMENT METHODS ====================

  List<ContractDocument> getDocumentsForContract(String contractId) {
    return _contractDocuments[contractId] ?? [];
  }

  void addDocument(String contractId, ContractDocument doc) {
    _contractDocuments[contractId] = [
      ...(_contractDocuments[contractId] ?? []),
      doc,
    ];
    addLog(contractId, 'Dokumen "${doc.name}" diunggah', 'document');
    notifyListeners();
  }

  void addDocuments(String contractId, List<ContractDocument> docs) {
    for (final doc in docs) {
      _contractDocuments[contractId] = [
        ...(_contractDocuments[contractId] ?? []),
        doc,
      ];
    }
    if (docs.isNotEmpty) {
      addLog(contractId, '${docs.length} dokumen diunggah bersama kontrak', 'document');
    }
    notifyListeners();
  }

  void removeDocument(String contractId, int index) {
    final docs = List<ContractDocument>.from(_contractDocuments[contractId] ?? []);
    if (index >= 0 && index < docs.length) {
      final docName = docs[index].name;
      docs.removeAt(index);
      _contractDocuments[contractId] = docs;
      addLog(contractId, 'Dokumen "$docName" dihapus', 'edit');
      notifyListeners();
    }
  }
}