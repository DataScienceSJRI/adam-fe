import 'package:adam/ui/screens/activity/activity_log_screen.dart';
import 'package:adam/ui/screens/dashboard/dashboard_screen.dart';
import 'package:adam/ui/screens/log_meal/diet_recall_screen.dart';
import 'package:adam/ui/screens/meal_plan/plan_meal_screen.dart';
import 'package:adam/ui/screens/profile/profile_screen.dart';
import 'package:adam/ui/utils/bottom_nav_bar.dart';
import 'package:flutter/material.dart';


class MainScreenWrapper extends StatefulWidget {
  const MainScreenWrapper({super.key});

  @override
  State<MainScreenWrapper> createState() => _MainScreenWrapperState();
}

class _MainScreenWrapperState extends State<MainScreenWrapper> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const DashboardScreen(),
    const MealPlanScreen(),
    const DietRecallScreen(),
    const ActivityLogScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),

      // THIS WILL REBUILD SCREEN EACH TAB CHANGE
      body: _pages[_currentIndex],

      bottomNavigationBar: SafeArea(
        top: false,
        child: BottomNavBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
        ),
      ),
    );
  }
}
