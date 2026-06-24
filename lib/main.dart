// import 'package:adam/service/navigation_service.dart';
// import 'package:adam/service/notification_service.dart';
// import 'package:adam/ui/screens/dashboard/dashboard_wrapper.dart';
// import 'package:adam/ui/screens/login/login_screen.dart';
// import 'package:adam/ui/utils/shimmer.dart';
// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
//
// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await Supabase.initialize(
//     url: 'https://mwiaqjjribxrywpmlkik.supabase.co',
//     anonKey: 'sb_publishable_1BcKckF5lgmxYZbwBrgaPg__IarRmUl',
//   );
//   try {
//     await NotificationService().init();
//   } catch (e) {
//     print("OneSignal init failed: $e");
//   }
//   runApp(const MyApp());
// }
//
// class MyApp extends StatelessWidget {
//   const MyApp({super.key});
//
//   Future<bool> isLoggedIn() async {
//     final prefs = await SharedPreferences.getInstance();
//
//     final token = prefs.getString('access_token');
//
//     return token != null && token.isNotEmpty;
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       navigatorKey: NavigationService.navigatorKey,
//
//       debugShowCheckedModeBanner: false,
//
//       title: 'ADAM Study',
//
//       theme: ThemeData(
//         colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
//       ),
//
//       home: FutureBuilder<bool>(
//         future: isLoggedIn(),
//
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return Scaffold(body: Center(child: Shimmer.card()));
//           }
//
//           if (snapshot.data == true) {
//             return const MainScreenWrapper();
//           }
//
//           return const LoginScreen();
//         },
//       ),
//     );
//   }
// }
import 'package:adam/service/navigation_service.dart';
import 'package:adam/service/notification_service.dart';
import 'package:adam/service/token_manager.dart';
import 'package:adam/ui/screens/dashboard/dashboard_wrapper.dart';
import 'package:adam/ui/screens/login/login_screen.dart';
import 'package:adam/ui/utils/shimmer.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://mwiaqjjribxrywpmlkik.supabase.co',
    anonKey: 'sb_publishable_1BcKckF5lgmxYZbwBrgaPg__IarRmUl',
  );

  try {
    await NotificationService().init();
  } catch (e) {
    debugPrint("OneSignal init failed: $e");
  }

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final TokenManager _tokenManager = TokenManager();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed) {
      debugPrint("📱 App resumed");

      try {
        final token = await _tokenManager.getValidAccessToken();

        if (token == null || token.isEmpty) {
          debugPrint("❌ Unable to refresh token. Logging out.");

          final prefs = await SharedPreferences.getInstance();

          await prefs.clear();

          NavigationService.navigatorKey.currentState?.pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          );
        } else {
          debugPrint("✅ Token valid");
        }
      } catch (e) {
        debugPrint("🚨 Error while validating token: $e");
      }
    }
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();

    final token = prefs.getString('access_token');

    return token != null && token.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: NavigationService.navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'ADAM Study',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: FutureBuilder<bool>(
        future: isLoggedIn(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Scaffold(body: Center(child: Shimmer.card()));
          }

          if (snapshot.data == true) {
            return const MainScreenWrapper();
          }

          return const LoginScreen();
        },
      ),
    );
  }
}
