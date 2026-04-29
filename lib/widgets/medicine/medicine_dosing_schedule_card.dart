import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class MedicineDosingScheduleCard extends StatelessWidget {
  final String label;
  final int amount;
  final IconData icon;

  const MedicineDosingScheduleCard({
    super.key,
    required this.label,
    required this.amount,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    bool isActive = amount > 0;
    Color primaryColor = const Color(0xFF1B5AEE);

    return Container(
      constraints: const BoxConstraints(minHeight: 110),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      decoration: BoxDecoration(
        color: isActive
            ? primaryColor.withOpacity(0.05)
            : CupertinoColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive
              ? primaryColor.withOpacity(0.2)
              : CupertinoColors.systemGrey5,
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: primaryColor, size: 22),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: Color.fromARGB(255, 118, 118, 118),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$amount pill',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              color: CupertinoColors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
