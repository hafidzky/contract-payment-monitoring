import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class ContractFilterRow extends StatelessWidget {
  final String selectedFilter;
  final List<Map<String, String>> allContracts;
  final Function(String) onFilterChanged;
  final String Function(Map<String, String>) getDisplayStatus;

  const ContractFilterRow({
    super.key,
    required this.selectedFilter,
    required this.allContracts,
    required this.onFilterChanged,
    required this.getDisplayStatus,
  });

  @override
  Widget build(BuildContext context) {
    final filters = [
      ('Semua',    AppColors.primary, allContracts.length),
      ('Active',   Colors.green,
        allContracts.where((c) => getDisplayStatus(c) == 'Active').length),
      ('Finished', Colors.blue,
        allContracts.where((c) => getDisplayStatus(c) == 'Finished').length),
      ('Warning',  Colors.orange,
        allContracts.where((c) => getDisplayStatus(c) == 'Warning').length),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((f) => _ContractFilterChip(
          label: f.$1,
          color: f.$2,
          count: f.$3,
          isSelected: selectedFilter == f.$1,
          onTap: () => onFilterChanged(f.$1),
        )).toList(),
      ),
    );
  }
}

class _ContractFilterChip extends StatelessWidget {
  final String label;
  final Color color;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;

  const _ContractFilterChip({
    required this.label,
    required this.color,
    required this.count,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300),
          boxShadow: isSelected
              ? [BoxShadow(color: color.withValues(alpha: 0.3),
                  blurRadius: 8, offset: const Offset(0, 3))]
              : [],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(label, style: TextStyle(
            fontSize: 12, fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : Colors.grey.shade600)),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.white.withValues(alpha: 0.25)
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text('$count', style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : Colors.grey.shade500)),
          ),
        ]),
      ),
    );
  }
}