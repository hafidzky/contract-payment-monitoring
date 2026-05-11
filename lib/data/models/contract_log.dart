// lib/models/contract_log.dart

class ContractLog {
  final String activity;
  final String time;
  final String icon; // 'edit', 'payment', 'document', 'create'

  ContractLog({
    required this.activity,
    required this.time,
    required this.icon,
  });

  Map<String, dynamic> toMap() => {
    'activity': activity,
    'time': time,
    'icon': icon,
  };

  factory ContractLog.fromMap(Map<String, dynamic> map) => ContractLog(
    activity: map['activity'] ?? '',
    time: map['time'] ?? '',
    icon: map['icon'] ?? 'edit',
  );
}