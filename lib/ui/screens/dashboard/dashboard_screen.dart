import 'package:adam/bloc/dashboard/dashboard_bloc.dart';
import 'package:adam/data/models/dashboard_model.dart';
import 'package:adam/data/repositories/dashboard_repository.dart';
import 'package:adam/ui/screens/preference/preference_screen.dart';
import 'package:adam/ui/screens/recipes/recipes_screen.dart';
import 'package:adam/ui/utils/shimmer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:package_info_plus/package_info_plus.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => DashboardScreenState();
}

class DashboardScreenState extends State<DashboardScreen> {
  final DashboardRepository _dashboardRepository = DashboardRepository();
  String _version = "";

  Future<void> _loadVersion() async {
    print("================== LOAD VERSION =========");
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      print("${packageInfo.version}+${packageInfo.buildNumber}");
      _version = packageInfo.version;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          DashboardBloc(repository: _dashboardRepository)
            ..add(GetDashboardEvent()),

      child: Scaffold(
        backgroundColor: const Color(0xFFF4F7F5),

        appBar: AppBar(
          backgroundColor: const Color(0xFFF4F7F5),
          elevation: 0,
          centerTitle: false,
          automaticallyImplyLeading: false,

          title: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome Back 👋',
                style: TextStyle(
                  color: Color(0xFF6B7280),
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),

              SizedBox(height: 2),
            ],
          ),

          actions: [
            Container(
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.food_bank_outlined,
                  color: Color(0xFF0F5132),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RecipesScreen()),
                  );
                },
              ),

            ),
            Container(
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.dark_mode,
                  color: Color(0xFF0F5132),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PreferenceScreen()),
                  );
                },
              ),

            ),
          ],
        ),

        body: BlocBuilder<DashboardBloc, DashboardState>(
          builder: (context, state) {
            if (state is DashboardLoading) {
              return Shimmer.list();
            }

            if (state is DashboardFailure) {
              return Center(child: Text(state.message));
            }

            if (state is DashboardLoaded) {
              final DashboardModel dashboard = state.dashboardData;

              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    Padding(
                      padding: EdgeInsetsGeometry.only(left: 12, bottom: 8),
                      child: Text(
                        'Version $_version',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),

                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0F5132), Color(0xFF1B7A4B)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),

                        borderRadius: BorderRadius.circular(24),
                      ),

                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [
                          const Text(
                            'Today Overview',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),

                          const SizedBox(height: 8),

                          Text(
                            dashboard.date ?? '',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 18),

                          Row(
                            children: [
                              Expanded(
                                child: _buildOverviewTile(
                                  'Score',
                                  dashboard.bloodSugarControlScore
                                          ?.toStringAsFixed(1) ??
                                      '--',
                                  Icons.favorite,
                                ),
                              ),

                              const SizedBox(width: 12),

                              Expanded(
                                child: _buildOverviewTile(
                                  'Calories',
                                  '${dashboard.nutrition.carbsG?.toInt() ?? 0}',
                                  Icons.local_fire_department,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 22),

                    _buildBloodSugarCard(dashboard),

                    const SizedBox(height: 18),
                    _buildGlycemicLoadCard(dashboard.glycemicLoad ?? 0),

                    const SizedBox(height: 18),

                    _buildTodayNutritionCard(dashboard),
                  ],
                ),
              );
            }

            return const SizedBox();
          },
        ),
      ),
    );
  }

  Widget _buildOverviewTile(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),

      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(18),
      ),

      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),

            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              shape: BoxShape.circle,
            ),

            child: Icon(icon, color: Colors.white, size: 18),
          ),

          const SizedBox(width: 10),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Text(
                title,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),

              const SizedBox(height: 2),

              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGlycemicLoadCard(double gl) {
    Color badgeColor;
    String status;

    if (gl <= 10) {
      badgeColor = Colors.green;
      status = "Low";
    } else if (gl <= 200) {
      badgeColor = Colors.orange;
      status = "Moderate";
    } else {
      badgeColor = Colors.red;
      status = "High";
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: Color(0xFFEAF9F3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.water_drop_outlined,
                  color: Color(0xFF0F5132),
                ),
              ),

              const SizedBox(width: 12),

              const Expanded(
                child: Text(
                  "Glycemic Load",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: badgeColor.withOpacity(.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: badgeColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          Center(
            child: Column(
              children: [
                Text(
                  gl.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 46,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F5132),
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  "Today's Glycemic Load",
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              minHeight: 10,
              value: (gl / 200).clamp(0.0, 1.0),
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation(badgeColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBloodSugarCard(DashboardModel dashboard) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,

            children: [
              const Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: Color(0xFFE8F5E9),

                    child: Icon(
                      Icons.monitor_heart_outlined,
                      color: Color(0xFF0F5132),
                      size: 20,
                    ),
                  ),

                  SizedBox(width: 12),

                  Text(
                    'Blood Sugar Score',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                  ),
                ],
              ),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),

                decoration: BoxDecoration(
                  color: const Color(0xFFE8F0FE),
                  borderRadius: BorderRadius.circular(10),
                ),

                child: const Text(
                  'HbA1c',
                  style: TextStyle(
                    color: Color(0xFF1A73E8),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          Center(
            child: Column(
              children: [
                Text(
                  dashboard.bloodSugarControlScore?.toStringAsFixed(1) ?? '--',

                  style: const TextStyle(
                    fontSize: 44,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F5132),
                  ),
                ),

                const SizedBox(height: 6),

                const Text(
                  'Current Health Score',
                  style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayNutritionCard(DashboardModel dashboard) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          const Row(
            children: [
              Icon(Icons.restaurant_menu, color: Color(0xFF0F5132)),

              SizedBox(width: 8),

              Text(
                "Today's Nutrition",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),

          const SizedBox(height: 22),

          _buildMacroProgressBar(
            'Carbs',
            '${dashboard.nutrition.carbsG}g',
            (dashboard.nutrition.carbsG ?? 0) / 150,
            const Color(0xFF1A73E8),
          ),

          _buildMacroProgressBar(
            'Protein',
            '${dashboard.nutrition.proteinG}g',
            (dashboard.nutrition.proteinG ?? 0) / 60,
            const Color(0xFF16A34A),
          ),

          _buildMacroProgressBar(
            'Fibre',
            '${dashboard.nutrition.fibreG}g',
            (dashboard.nutrition.fibreG ?? 0) / 30,
            const Color(0xFFF59E0B),
          ),

          _buildMacroProgressBar(
            'Fat',
            '${dashboard.nutrition.fatG}g',
            (dashboard.nutrition.fatG ?? 0) / 55,
            const Color(0xFFD946EF),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroProgressBar(
    String title,
    String ratio,
    double progress,
    Color progressColor,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),

      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,

            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF374151),
                  fontWeight: FontWeight.w600,
                ),
              ),

              Text(
                ratio,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF111827),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          ClipRRect(
            borderRadius: BorderRadius.circular(20),

            child: LinearProgressIndicator(
              value: progress > 1 ? 1 : progress,
              minHeight: 10,
              backgroundColor: const Color(0xFFE5E7EB),

              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            ),
          ),
        ],
      ),
    );
  }
}
