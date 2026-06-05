import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F5132).withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Container(
          height: 66,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC), // Off-white soft channel inner track
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFE2E8F0),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildInnovativeItem(0, Icons.home_rounded, Icons.home_outlined, 'Home'),
              _buildInnovativeItem(1, Icons.calendar_today_rounded, Icons.calendar_today_outlined, 'Meals'),
              _buildInnovativeItem(2, Icons.add_circle_rounded, Icons.add_circle_outline_rounded, 'Log'),
              _buildInnovativeItem(3, Icons.fitness_center_rounded, Icons.fitness_center_outlined, 'Activity'),
              _buildInnovativeItem(4, Icons.widgets_rounded, Icons.widgets_outlined, 'More'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInnovativeItem(int index, IconData selectedIcon, IconData unselectedIcon, String label) {
    final bool isSelected = currentIndex == index;

    const Color activeGreen = Color(0xFF0F5132); // Core corporate branding identity
    const Color activeLabelColor = Color(0xFF1E293B);
    const Color inactiveGray = Color(0xFF64748B);

    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (!isSelected) {
            HapticFeedback.lightImpact(); // Soft micro-haptic tick feedback
            onTap(index);
          }
        },
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                // Animated Pill Backdrop Frame
                AnimatedContainer(
                  duration: const Duration(milliseconds: 320),
                  curve: Curves.fastLinearToSlowEaseIn,
                  width: isSelected ? 54 : 0,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF0F5132) : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: isSelected
                        ? [
                      BoxShadow(
                        color: activeGreen.withOpacity(0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      )
                    ]
                        : [],
                  ),
                ),

                // Icon Vector Layer
                AnimatedScale(
                  scale: isSelected ? 1.05 : 0.95,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    isSelected ? selectedIcon : unselectedIcon,
                    color: isSelected ? Colors.white : inactiveGray,
                    size: 22,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),

            // Dynamic text indicator matching structural parameters
            AnimatedCrossFade(
              firstChild: Text(
                label,
                style: const TextStyle(
                  color: activeLabelColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.1,
                ),
              ),
              secondChild: Text(
                label,
                style: const TextStyle(
                  color: inactiveGray,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.1,
                ),
              ),
              crossFadeState: isSelected ? CrossFadeState.showFirst : CrossFadeState.showSecond,
              duration: const Duration(milliseconds: 200),
            ),
          ],
        ),
      ),
    );
  }
}