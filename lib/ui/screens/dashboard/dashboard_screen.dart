import 'package:adam/bloc/dashboard/dashboard_bloc.dart';
import 'package:adam/data/models/dashboard_model.dart';
import 'package:adam/data/repositories/dashboard_repository.dart';
import 'package:adam/ui/screens/preference/preference_screen.dart';
import 'package:adam/ui/screens/recipes/recipes_screen.dart';
import 'package:adam/ui/utils/dashboard_nutrient_ui.dart';
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
                  Icons.dashboard_customize,
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
                    // Container(
                    //   width: double.infinity,
                    //   padding: const EdgeInsets.all(20),
                    //
                    //   decoration: BoxDecoration(
                    //     gradient: const LinearGradient(
                    //       colors: [Color(0xFF0F5132), Color(0xFF1B7A4B)],
                    //       begin: Alignment.topLeft,
                    //       end: Alignment.bottomRight,
                    //     ),
                    //
                    //     borderRadius: BorderRadius.circular(24),
                    //   ),
                    //
                    //   child: Column(
                    //     crossAxisAlignment: CrossAxisAlignment.start,
                    //
                    //     children: [
                    //       const Text(
                    //         'Today Overview',
                    //         style: TextStyle(
                    //           color: Colors.white70,
                    //           fontSize: 14,
                    //           fontWeight: FontWeight.w500,
                    //         ),
                    //       ),
                    //
                    //       const SizedBox(height: 8),
                    //
                    //       Text(
                    //         dashboard.date ?? '',
                    //         style: const TextStyle(
                    //           color: Colors.white,
                    //           fontSize: 22,
                    //           fontWeight: FontWeight.bold,
                    //         ),
                    //       ),
                    //
                    //       const SizedBox(height: 18),
                    //
                    //       Row(
                    //         children: [
                    //           Expanded(
                    //             child: _buildOverviewTile(
                    //               'Score',
                    //               dashboard.bloodSugarControlScore
                    //                       ?.toStringAsFixed(1) ??
                    //                   '--',
                    //               Icons.favorite,
                    //             ),
                    //           ),
                    //
                    //           const SizedBox(width: 12),
                    //
                    //           Expanded(
                    //             child: _buildOverviewTile(
                    //               'Calories',
                    //               '${dashboard.getIntakeFor('Energy', 0.0).toStringAsFixed(0)} kcal',
                    //               Icons.local_fire_department,
                    //             ),
                    //           ),
                    //         ],
                    //       ),
                    //     ],
                    //   ),
                    // ),
                    _dashboardMainCard(dashboard),
                    const SizedBox(height: 14),
                    _buildCombinedMetricsCard(dashboard),
                    const SizedBox(height: 18),
                    MovingMetabolicEngineCard(dashboard: dashboard),
                    const SizedBox(height: 18),
                    _buildMealGlycemicLoadTimeline(dashboard),
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

  Widget _dashboardMainCard(DashboardModel dashboard) {
    final double requirement = dashboard.getRequirementFor(
      'Energy (kcal)',
      0.0,
    );
    final double intake = dashboard.getIntakeFor('Energy (kcal)', 0.0);
    final double delta = requirement - intake;
    final bool isSurplus = delta < 0;

    final String balanceLabel = isSurplus ? "ENERGY SURPLUS" : "ENERGY DEFICIT";
    final Color balanceColor = isSurplus
        ? const Color(0xFFFB923C)
        : const Color(0xFF4ADE80);
    final IconData balanceIcon = isSurplus
        ? Icons.bolt_rounded
        : Icons.eco_rounded;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F5132), Color(0xFF064E3B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F5132).withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'TODAY OVERVIEW',
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  dashboard.date ?? '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 45,
                width: 1,
                color: Colors.white24,
                margin: const EdgeInsets.symmetric(horizontal: 16),
              ),

              Expanded(
                flex: 6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      balanceLabel,
                      style: TextStyle(
                        color: balanceColor,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Icon(balanceIcon, size: 18, color: balanceColor),
                        const SizedBox(width: 4),
                        Text(
                          delta.abs().toStringAsFixed(0),
                          style: TextStyle(
                            color: isSurplus ? Colors.redAccent : Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Text(
                          'kcal',
                          style: TextStyle(
                            color: Colors.white60,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Target: ${requirement.toStringAsFixed(0)} kcal",
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white24,
                  size: 10,
                ),
                Text(
                  "Intake: ${intake.toStringAsFixed(0)} kcal",
                  style: TextStyle(
                    color: isSurplus ? const Color(0xFFFCA5A5) : Colors.white70,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCombinedMetricsCard(DashboardModel dashboard) {
    final double? weightKg = dashboard.weight['latest_weight']?.weightKg;
    final int? daysAgo = dashboard.weight['latest_weight']?.daysAgo;

    final String timeAgoText = daysAgo == 0
        ? "Logged Today"
        : (daysAgo == 1 ? "Logged Yesterday" : "Updated $daysAgo days ago");

    final meals = [
      {
        "name": "Breakfast",
        "icon": Icons.wb_twilight,
        "time": "Morning",
        "planned": dashboard.glByMeal['breakfast']?.planned,
        "actual": dashboard.glByMeal['breakfast']?.actual,
        "indicator": dashboard.glByMeal['breakfast']?.indicator,
      },
      {
        "name": "Lunch",
        "icon": Icons.wb_sunny_outlined,
        "time": "Noon",
        "planned": dashboard.glByMeal['lunch']?.planned,
        "actual": dashboard.glByMeal['lunch']?.actual,
        "indicator": dashboard.glByMeal['lunch']?.indicator,
      },
      {
        "name": "Dinner",
        "icon": Icons.dark_mode_outlined,
        "time": "Evening",
        "planned": dashboard.glByMeal['dinner']?.planned,
        "actual": dashboard.glByMeal['dinner']?.actual,
        "indicator": dashboard.glByMeal['dinner']?.indicator,
      },
      {
        "name": "Snacks",
        "icon": Icons.cookie_outlined,
        "time": "Anytime",
        "planned": dashboard.glByMeal['snacks']?.planned,
        "actual": dashboard.glByMeal['snacks']?.actual,
        "indicator": dashboard.glByMeal['snacks']?.indicator,
      },
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFE2E8F0),
                        width: 1,
                      ),
                    ),
                    child: const Icon(
                      Icons.scale_outlined,
                      color: Color(0xFF64748B),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "CURRENT BODY MASS",
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF94A3B8),
                          letterSpacing: 0.6,
                        ),
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            weightKg != null
                                ? weightKg.toStringAsFixed(1)
                                : '--',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF1E293B),
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(width: 2),
                          const Text(
                            'kg',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  timeAgoText,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12.0),
            child: Divider(color: Color(0xFFF1F5F9), thickness: 1.5),
          ),

          const Text(
            "Today's GL Overview",
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E293B),
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 12),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: meals.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              mainAxisExtent: 145,
            ),
            itemBuilder: (context, index) {
              final meal = meals[index];
              final double? plannedGl = meal['planned'] as double?;
              final double? actualGl = meal['actual'] as double?;
              final String? indicator = meal['indicator'] as String?;

              Color statusColor = const Color(0xFF94A3B8);
              Color cardBg = const Color(0xFFF8FAFC);
              IconData indicatorIcon = Icons.help_outline;

              if (indicator != null) {
                if (indicator.toLowerCase() == 'good') {
                  statusColor = const Color(0xFF10B981);
                  cardBg = const Color(0xFFF0FDF4);
                  indicatorIcon = Icons.check_circle_rounded;
                } else if (indicator.toLowerCase() == 'poor') {
                  statusColor = const Color(0xFFEF4444);
                  cardBg = const Color(0xFFFEF2F2);
                  indicatorIcon = Icons.error;
                }
              } else if (plannedGl != null) {
                statusColor = const Color(0xFF0F5132);
              }

              return Container(
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: indicator != null
                        ? statusColor.withOpacity(0.2)
                        : const Color(0xFFE2E8F0),
                    width: 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Icon(
                                  meal['icon'] as IconData,
                                  color: statusColor,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    meal['name'].toString(),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF1E293B),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 4),
                          if (indicator != null)
                            Icon(indicatorIcon, color: statusColor, size: 14)
                          else
                            Text(
                              meal['time'].toString(),
                              style: const TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                        ],
                      ),

                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "PLANNED",
                                  style: TextStyle(
                                    color: Color(0xFF94A3B8),
                                    fontSize: 8,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                const SizedBox(height: 1),
                                Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    Text(
                                      plannedGl?.toStringAsFixed(1) ?? '--',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: plannedGl != null
                                            ? const Color(0xFF475569)
                                            : const Color(0xFFCBD5E1),
                                      ),
                                    ),
                                    if (plannedGl != null) ...[
                                      const SizedBox(width: 1),
                                      const Text(
                                        'gl',
                                        style: TextStyle(
                                          fontSize: 8,
                                          color: Color(0xFF94A3B8),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Container(
                            height: 22,
                            width: 1,
                            color: const Color(0xFFE2E8F0),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "ACTUAL",
                                  style: TextStyle(
                                    color: statusColor.withOpacity(0.8),
                                    fontSize: 8,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                const SizedBox(height: 1),
                                Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    Text(
                                      actualGl?.toStringAsFixed(1) ?? '--',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: actualGl != null
                                            ? const Color(0xFF1E293B)
                                            : const Color(0xFFCBD5E1),
                                      ),
                                    ),
                                    if (actualGl != null) ...[
                                      const SizedBox(width: 1),
                                      Text(
                                        'gl',
                                        style: TextStyle(
                                          fontSize: 8,
                                          color: statusColor,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          vertical: 4,
                          horizontal: 6,
                        ),
                        decoration: BoxDecoration(
                          color: indicator != null
                              ? statusColor.withOpacity(0.08)
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Center(
                          child: Text(
                            indicator != null
                                ? "${indicator.toUpperCase()} IMPACT"
                                : (plannedGl != null
                                      ? "AWAITING LOG"
                                      : "NO DATA"),
                            style: TextStyle(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w800,
                              color: indicator != null
                                  ? statusColor
                                  : const Color(0xFF64748B),
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMealGlycemicLoadTimeline(DashboardModel dashboard) {
    final meals = [
      {
        "name": "Breakfast",
        "icon": Icons.wb_twilight,
        "weighted_avg": dashboard.glByMeal['breakfast']?.weightedAvgPast14d,
        "yesterday": dashboard.glByMeal['breakfast']?.yesterday,
        "indicator": dashboard.glByMeal['breakfast']?.indicator,
      },
      {
        "name": "Lunch",
        "icon": Icons.wb_sunny_outlined,
        "weighted_avg": dashboard.glByMeal['lunch']?.weightedAvgPast14d,
        "yesterday": dashboard.glByMeal['lunch']?.yesterday,
        "indicator": dashboard.glByMeal['lunch']?.indicator,
      },
      {
        "name": "Dinner",
        "icon": Icons.dark_mode_outlined,
        "weighted_avg": dashboard.glByMeal['dinner']?.weightedAvgPast14d,
        "yesterday": dashboard.glByMeal['dinner']?.yesterday,
        "indicator": dashboard.glByMeal['dinner']?.indicator,
      },
      {
        "name": "Snacks",
        "icon": Icons.cookie_outlined,
        "weighted_avg": dashboard.glByMeal['snacks']?.weightedAvgPast14d,
        "yesterday": dashboard.glByMeal['snacks']?.yesterday,
        "indicator": dashboard.glByMeal['snacks']?.indicator,
      },
      {
        "name": "Per Day Total",
        "icon": Icons.analytics_outlined,
        "weighted_avg": dashboard.glByMeal['per_day']?.weightedAvgPast14d,
        "yesterday": dashboard.glByMeal['per_day']?.yesterday,
        "indicator": dashboard.glByMeal['per_day']?.indicator,
        "isTotal": true,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Text(
            "GL Trends",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: meals.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            mainAxisExtent: 180,
          ),
          itemBuilder: (context, index) {
            final meal = meals[index];
            final double? yesterdayGl = meal['yesterday'] as double?;
            final double? avg14dGl = meal['weighted_avg'] as double?;
            final String? indicator = meal['indicator'] as String?;
            final bool isTotal = meal['isTotal'] == true;

            Color cardBg = isTotal ? const Color(0xFFF8FAFC) : Colors.white;
            Color borderAccent = isTotal
                ? const Color(0xFFCBD5E1)
                : const Color(0xFFE5E7EB);
            Color titleAccent = isTotal
                ? const Color(0xFF334155)
                : const Color(0xFF111827);
            Color statusColor = const Color(0xFF6B7280);
            Color statusBg = const Color(0xFFF9FAFB);
            IconData statusIcon = Icons.help_outline_rounded;

            if (indicator != null) {
              if (indicator.toLowerCase() == 'good') {
                statusColor = const Color(0xFF16A34A);
                statusBg = const Color(0xFFF0FDF4);
                statusIcon = Icons.check_circle_rounded;
                if (isTotal) cardBg = const Color(0xFFF0FDF4);
              } else if (indicator.toLowerCase() == 'poor') {
                statusColor = const Color(0xFFDC2626);
                statusBg = const Color(0xFFFEF2F2);
                statusIcon = Icons.error_rounded;
                if (isTotal) cardBg = const Color(0xFFFEF2F2);
              }
              borderAccent = statusColor.withOpacity(0.25);
            }

            return Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: borderAccent,
                  width: isTotal ? 1.5 : 1.0,
                ),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Icon(
                              meal['icon'] as IconData,
                              size: 16,
                              color: indicator != null
                                  ? statusColor
                                  : const Color(0xFF6B7280),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                meal['name'].toString(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: titleAccent,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (indicator != null)
                        Icon(statusIcon, size: 14, color: statusColor),
                    ],
                  ),

                  _buildCompactMetricRow("YESTERDAY", yesterdayGl),
                  Divider(height: 1, color: borderAccent.withOpacity(0.5)),
                  _buildCompactMetricRow("14D AVG", avg14dGl),

                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: Text(
                        indicator?.toUpperCase() ?? "NO DATA",
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCompactMetricRow(String label, double? value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.w800,
            color: Color(0xFF9CA3AF),
          ),
        ),
        Text(
          value != null ? value.toStringAsFixed(0) : '--',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: Color(0xFF111827),
          ),
        ),
      ],
    );
  }
}
