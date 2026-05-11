// lib/models/contract_document.dart

class ContractDocument {
  final String name;
  final String path;   // file path lokal (dari file_picker)
  final String size;   // e.g. "2.4 MB"
  final String type;   // 'PDF', 'IMG', 'DOC', dll

  ContractDocument({
    required this.name,
    required this.path,
    required this.size,
    required this.type,
  });

  Map<String, dynamic> toMap() => {
    'name': name,
    'path': path,
    'size': size,
    'type': type,
  };

  factory ContractDocument.fromMap(Map<String, dynamic> map) => ContractDocument(
    name: map['name'] ?? '',
    path: map['path'] ?? '',
    size: map['size'] ?? '',
    type: map['type'] ?? 'FILE',
  );
}