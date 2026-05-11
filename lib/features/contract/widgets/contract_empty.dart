import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class ContractEmptyState extends StatelessWidget {
  const ContractEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 60),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.folder_off_outlined,
                size: 48, color: Colors.grey.shade400),
            ),
            const SizedBox(height: 16),
            Text(
              'Tidak ada kontrak ditemukan',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Coba ubah filter atau kata kunci pencarian',
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ContractPagination extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  const ContractPagination({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            color: currentPage > 1 ? AppColors.primary : Colors.grey,
            onPressed: currentPage > 1 ? onPrevious : null,
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Halaman $currentPage dari $totalPages',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            color: currentPage < totalPages
                ? AppColors.primary
                : Colors.grey,
            onPressed: currentPage < totalPages ? onNext : null,
          ),
        ],
      ),
    );
  }
}