import 'package:equatable/equatable.dart';

class PaymentEntity extends Equatable {
  final String id;
  final int termNumber;      // Termin ke-berapa (1, 2, 3...)
  final double nominal;      // Jumlah yang harus dibayar
  final DateTime dueDate;    // Tanggal Jatuh Tempo
  final String status;       // 'scheduled', 'pending', 'approved', 'paid'
  final String? proofPath;   // Path file bukti bayar (jika ada)

  const PaymentEntity({
    required this.id,
    required this.termNumber,
    required this.nominal,
    required this.dueDate,
    required this.status,
    this.proofPath,
  });

  @override
  List<Object?> get props => [id, termNumber, nominal, dueDate, status, proofPath];
}