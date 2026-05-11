import 'package:equatable/equatable.dart';
import '../../data/models/payment.dart';

class ContractEntity extends Equatable {
  final String id;
  final String vendorName;
  final String projectName;
  final double totalValue;
  final DateTime startDate;
  final DateTime endDate;
  final List<PaymentEntity> payments; 

  const ContractEntity({
    required this.id,
    required this.vendorName,
    required this.projectName,
    required this.totalValue,
    required this.startDate,
    required this.endDate,
    required this.payments,
  });

  @override
  List<Object?> get props => [
        id,
        vendorName,
        projectName,
        totalValue,
        startDate,
        endDate,
        payments,
      ];
}