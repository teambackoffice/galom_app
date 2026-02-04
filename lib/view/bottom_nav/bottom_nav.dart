import 'package:flutter/material.dart';

class ModernBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final Color? selectedItemColor;
  final Color? unselectedItemColor;
  final Color? backgroundColor;

  const ModernBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.selectedItemColor,
    this.unselectedItemColor,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(0, 0, 6, 16),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: backgroundColor ?? Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            _buildNavItem(0, Icons.check_circle, 'Attendance'),
            _buildNavItem(1, Icons.business_center_rounded, 'Sales'),
            _buildNavItem(2, Icons.add_task, 'Tasks'),
            _buildNavItem(3, Icons.receipt, 'Invoice'),
            _buildNavItem(4, Icons.person_outline, 'Profile'),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = currentIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? (selectedItemColor ?? const Color(0xFF667EEA)).withOpacity(
                    0.1,
                  )
                : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected
                    ? (selectedItemColor ?? const Color(0xFF667EEA))
                    : (unselectedItemColor ?? Colors.grey[600]),
                size: 24,
              ),
              if (isSelected) ...[
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.fade,
                    softWrap: false,
                    style: TextStyle(
                      color: selectedItemColor ?? const Color(0xFF667EEA),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
