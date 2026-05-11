import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart'; 

class StepIndicator extends StatelessWidget {
  final int current;

  const StepIndicator({super.key, required this.current});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(4, (index) {
        final step = index + 1;
        final isActive = step <= current;
        return Expanded(
          child: Row(
            children: [
              // Lingkaran Step
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: isActive ? AppColors.primary : Colors.grey.shade200,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: isActive && step < current
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : Text(
                          '$step',
                          style: TextStyle(
                            color: isActive ? Colors.white : Colors.grey.shade500,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                ),
              ),
              // Garis Penghubung
              if (step < 4)
                Expanded(
                  child: Container(
                    height: 2,
                    color: isActive ? AppColors.primary : Colors.grey.shade200,
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }
}