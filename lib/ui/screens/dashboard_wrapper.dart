// import 'package:adam/ui/screens/plan_meal_screen.dart';
// import 'package:adam/ui/screens/profile_screen.dart';
// import 'package:flutter/material.dart';
// import '../shared_widgets/bottom_nav_bar.dart';
// import 'activity_log_screen.dart';
// import 'dashboard_screen.dart';
// import 'diet_recall_screen.dart';
// import 'recipes_screen.dart';
//
// class MainScreenWrapper extends StatefulWidget {
//   const MainScreenWrapper({super.key});
//
//   @override
//   State<MainScreenWrapper> createState() => _MainScreenWrapperState();
// }
//
// class _MainScreenWrapperState extends State<MainScreenWrapper> {
//   int _currentIndex = 0;
//
//   // Ordered strictly to map directly to your navigation items
//   final List<Widget> _pages = [
//     const DashboardScreen(),
//     const MealPlanScreen(),
//     const DietRecallScreen(),
//     const ActivityLogScreen(),
//     const ProfileScreen(),
//   ];
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF8F9FA),
//       // IndexedStack preserves screen state scrolling positions when switching tabs
//       body: IndexedStack(index: _currentIndex, children: _pages),
//       // Wrapped in a SafeArea so modern home-indicator gestures don't clip your custom floating deck
//       bottomNavigationBar: SafeArea(
//         top: false,
//         child: BottomNavBar(
//           currentIndex: _currentIndex,
//           onTap: (index) {
//             setState(() {
//               _currentIndex = index;
//             });
//           },
//         ),
//       ),
//     );
//   }
// }
import 'package:adam/ui/screens/activity_log_screen.dart';
import 'package:adam/ui/screens/dashboard_screen.dart';
import 'package:adam/ui/screens/diet_recall_screen.dart';
import 'package:adam/ui/screens/plan_meal_screen.dart';
import 'package:adam/ui/screens/profile_screen.dart';
import 'package:flutter/material.dart';

import '../shared_widgets/bottom_nav_bar.dart';

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
