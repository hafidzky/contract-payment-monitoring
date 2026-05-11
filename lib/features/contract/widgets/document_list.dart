import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:open_file/open_file.dart';
import 'package:file_picker/file_picker.dart';
import '../../../data/providers/contract_provider.dart';
import '../../../data/models/contract_document.dart';
import '../../../core/constants/app_colors.dart';

class DocumentListWidget extends StatelessWidget {
  final String contractId;
  const DocumentListWidget({super.key, required this.contractId});

  Future<void> _openDocument(BuildContext context, ContractDocument doc) async {
    final result = await OpenFile.open(doc.path);
    if (result.type != ResultType.done && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tidak bisa membuka file: ${result.message}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // Fungsi untuk memilih file dan menambahkannya ke provider
  Future<void> _pickAndAddDocument(BuildContext context) async {
    FilePickerResult? result = await FilePicker.pickFiles();

    if (result != null && context.mounted) {
      PlatformFile file = result.files.first;
      
      final newDoc = ContractDocument(
        name: file.name,
        path: file.path ?? '',
        type: file.extension?.toUpperCase() ?? 'FILE',
        size: '${(file.size / 1024).toStringAsFixed(1)} KB',
      );

      // Sinkronisasi: Menggunakan method 'addDocument' sesuai file provider terbaru
      context.read<ContractProvider>().addDocument(contractId, newDoc);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Mengambil daftar dokumen dari provider
    final docs = context.watch<ContractProvider>().getDocumentsForContract(contractId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header dengan tombol Tambah Dokumen di sebelah kanan[cite: 5]
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Daftar Dokumen",
              style: TextStyle(
                fontSize: 16, 
                fontWeight: FontWeight.bold, 
                color: AppColors.primary
              ),
            ),
            TextButton.icon(
              onPressed: () => _pickAndAddDocument(context),
              icon: const Icon(Icons.add_circle_outline, size: 20),
              label: const Text("Tambah Dokumen"),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                textStyle: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (docs.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.folder_open, size: 48, color: Colors.grey.shade300),
                  const SizedBox(height: 12),
                  Text('Belum ada dokumen', style: TextStyle(color: Colors.grey.shade400)),
                  const SizedBox(height: 4),
                  Text('Klik "Tambah Dokumen" untuk mengunggah berkas',
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
                ],
              ),
            ),
          )
        else
          ...List.generate(docs.length, (i) {
            final doc = docs[i];
            return Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: _docLeadingIcon(doc.type),
                  title: Text(doc.name,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text('${doc.type} • ${doc.size}',
                      style: const TextStyle(fontSize: 12)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.open_in_new, size: 20, color: AppColors.primary),
                        tooltip: 'Buka file',
                        onPressed: () => _openDocument(context, doc),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                        tooltip: 'Hapus dokumen',
                        onPressed: () {
                          // Menggunakan method 'removeDocument' sesuai file provider terbaru
                          context.read<ContractProvider>().removeDocument(contractId, i);
                        },
                      ),
                    ],
                  ),
                ),
                if (i < docs.length - 1) const Divider(),
              ],
            );
          }),
      ],
    );
  }

  Widget _docLeadingIcon(String type) {
    IconData icon;
    Color color;
    switch (type) {
      case 'PDF': icon = Icons.picture_as_pdf; color = Colors.red; break;
      case 'JPG':
      case 'JPEG':
      case 'PNG': icon = Icons.image; color = Colors.green; break;
      case 'DOC':
      case 'DOCX': icon = Icons.description; color = Colors.blue; break;
      case 'XLSX': icon = Icons.table_chart; color = Colors.teal; break;
      default: icon = Icons.insert_drive_file; color = Colors.grey;
    }
    return Container(
      width: 40, height: 40,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
}