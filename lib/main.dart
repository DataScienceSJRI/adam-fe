import 'package:adam/service/navigation_service.dart';
import 'package:adam/service/notification_service.dart';
import 'package:adam/ui/screens/dashboard_wrapper.dart';
import 'package:adam/ui/screens/login_screen.dart';
import 'package:adam/ui/shared_widgets/shimmer.dart';
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
    print("OneSignal init failed: $e");
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
            return  Scaffold(
              body: Center(child: Shimmer.card()),
            );
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
