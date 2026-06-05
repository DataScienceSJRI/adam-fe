// import 'package:flutter/material.dart';
// import '../../data/models/activity_model.dart';
// import '../../data/repositories/activity_repository.dart';
//
// class ActivityLogScreen extends StatefulWidget {
//   const ActivityLogScreen({super.key});
//
//   @override
//   State<ActivityLogScreen> createState() => _ActivityLogScreenState();
// }
//
// class _ActivityLogScreenState extends State<ActivityLogScreen> {
//   final ActivityRepository _repository = ActivityRepository();
//   String _selectedActivity = '';
//   List<String> _activities = [];
//   bool _isLoadingActivities = true;
//   double _duration = 30.0;
//   String _intensity = 'Moderate';
//
//   @override
//   void initState() {
//     _loadActivities();
//     super.initState();
//   }
//
//   Future<void> _loadActivities() async {
//     try {
//       final activities = await _repository.fetchPhysicalActivities();
//
//       if (!mounted) return;
//
//       setState(() {
//         _activities = activities;
//
//         if (activities.isNotEmpty) {
//           _selectedActivity = activities.first;
//         }
//
//         _isLoadingActivities = false;
//       });
//     } catch (e) {
//       if (!mounted) return;
//
//       setState(() {
//         _isLoadingActivities = false;
//       });
//
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text(e.toString())));
//     }
//   }
//
//   void _saveActivity() async {
//     final activity = ActivityLog(
//       id: DateTime.now().millisecondsSinceEpoch.toString(),
//       activityName: _selectedActivity,
//       durationMinutes: _duration.toInt(),
//       intensity: _intensity,
//       loggedAt: DateTime.now().toIso8601String(),
//     );
//
//     await _repository.submitActivity(activity);
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text('Activity Saved Successfully')),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFFAFAFA),
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         elevation: 0,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back, color: Color(0xFF0F5132)),
//           onPressed: () => Navigator.pop(context),
//         ),
//         title: const Text(
//           'Log activity',
//           style: TextStyle(
//             color: Color(0xFF0F5132),
//             fontSize: 18,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         bottom: PreferredSize(
//           preferredSize: const Size.fromHeight(1),
//           child: Container(color: const Color(0xFFE5E7EB), height: 1),
//         ),
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               'What did you do?',
//               style: TextStyle(
//                 fontSize: 14,
//                 fontWeight: FontWeight.bold,
//                 color: Color(0xFF1F2937),
//               ),
//             ),
//             const SizedBox(height: 10),
//
//             // 1. Search Bar Field Block
//             Container(
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(10),
//                 border: Border.all(color: const Color(0xFFE5E7EB)),
//               ),
//               child: const TextField(
//                 decoration: InputDecoration(
//                   hintText: 'Search activities...',
//                   hintStyle: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
//                   prefixIcon: Icon(
//                     Icons.search,
//                     color: Color(0xFF6B7280),
//                     size: 20,
//                   ),
//                   border: InputBorder.none,
//                   contentPadding: EdgeInsets.symmetric(vertical: 12),
//                 ),
//               ),
//             ),
//             const SizedBox(height: 12),
//
//             // 2. Selectable Activity Rows Track
//             // _buildActivitySelectRow('Walking', Icons.directions_walk),
//             // const SizedBox(height: 8),
//             // _buildActivitySelectRow('Yoga', Icons.self_improvement),
//             // const SizedBox(height: 8),
//             // _buildActivitySelectRow('Cycling', Icons.directions_bike),
//             _isLoadingActivities
//                 ? const Center(
//                     child: Padding(
//                       padding: EdgeInsets.all(20),
//                       child: CircularProgressIndicator(),
//                     ),
//                   )
//                 : Container(
//                     height: 250,
//                     padding: const EdgeInsets.only(top: 4),
//                     child: ListView.builder(
//                       itemCount: _activities.length,
//                       itemBuilder: (context, index) {
//                         final activity = _activities[index];
//
//                         return Padding(
//                           padding: const EdgeInsets.only(bottom: 8),
//                           child: _buildActivitySelectRow(
//                             activity,
//                             _getActivityIcon(activity),
//                           ),
//                         );
//                       },
//                     ),
//                   ),
//             const SizedBox(height: 24),
//
//             // 3. Slider Section Layout with Dynamic Right-Aligned Text Label
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 const Text(
//                   'For how long?',
//                   style: TextStyle(
//                     fontSize: 14,
//                     fontWeight: FontWeight.bold,
//                     color: Color(0xFF1F2937),
//                   ),
//                 ),
//                 Text(
//                   '${_duration.toInt()} minutes',
//                   style: const TextStyle(
//                     fontSize: 14,
//                     fontWeight: FontWeight.bold,
//                     color: Color(0xFF0F5132),
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 8),
//             SliderTheme(
//               data: SliderTheme.of(context).copyWith(
//                 activeTrackColor: const Color(0xFF0F5132),
//                 inactiveTrackColor: const Color(0xFFE5E7EB),
//                 thumbColor: const Color(0xFF0F5132),
//                 overlayColor: const Color(0xFF0F5132).withOpacity(0.12),
//                 trackHeight: 4,
//                 thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
//               ),
//               child: Slider(
//                 value: _duration,
//                 min: 0,
//                 max: 100,
//                 onChanged: (value) => setState(() => _duration = value),
//               ),
//             ),
//             const Padding(
//               padding: EdgeInsets.symmetric(horizontal: 12),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Text(
//                     '0',
//                     style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 11),
//                   ),
//                   Text(
//                     '50',
//                     style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 11),
//                   ),
//                   Text(
//                     '100m',
//                     style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 11),
//                   ),
//                 ],
//               ),
//             ),
//             const SizedBox(height: 24),
//
//             // 4. Custom Intensity Custom Block Cards
//             const Text(
//               'How did it feel?',
//               style: TextStyle(
//                 fontSize: 14,
//                 fontWeight: FontWeight.bold,
//                 color: Color(0xFF1F2937),
//               ),
//             ),
//             const SizedBox(height: 12),
//             Row(
//               children: [
//                 Expanded(
//                   child: _buildIntensityCard(
//                     'Light',
//                     'Easy breathing',
//                     const Color(0xFFFDBA74),
//                     const Color(0xFFFFF7ED),
//                     const Color(0xFFC2410C),
//                   ),
//                 ),
//                 const SizedBox(width: 8),
//                 Expanded(
//                   child: _buildIntensityCard(
//                     'Moderate',
//                     'Breathing harder',
//                     const Color(0xFFFDBA74),
//                     const Color(0xFFFFF7ED),
//                     const Color(0xFFC2410C),
//                   ),
//                 ),
//                 const SizedBox(width: 8),
//                 Expanded(
//                   child: _buildIntensityCard(
//                     'Vigorous',
//                     'Breathing fast',
//                     const Color(0xFFFDBA74),
//                     const Color(0xFFFFF7ED),
//                     const Color(0xFFC2410C),
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 24),
//
//             // 5. Solid Submission Action Button Frame
//             SizedBox(
//               width: double.infinity,
//               height: 48,
//               child: ElevatedButton(
//                 onPressed: _saveActivity,
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: const Color(0xFF0F5132),
//                   elevation: 0,
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                 ),
//                 child: const Text(
//                   'Save activity',
//                   style: TextStyle(
//                     color: Colors.white,
//                     fontWeight: FontWeight.bold,
//                     fontSize: 14,
//                   ),
//                 ),
//               ),
//             ),
//             const SizedBox(height: 24),
//             Container(color: const Color(0xFFE5E7EB), height: 1),
//             const SizedBox(height: 20),
//
//             // 6. Logged Today Historical Records Block
//             const Text(
//               'Logged today',
//               style: TextStyle(
//                 fontSize: 14,
//                 fontWeight: FontWeight.bold,
//                 color: Color(0xFF1F2937),
//               ),
//             ),
//             const SizedBox(height: 12),
//             Container(
//               padding: const EdgeInsets.all(12),
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(12),
//                 border: Border.all(color: const Color(0xFFE5E7EB)),
//               ),
//               child: Row(
//                 children: [
//                   Container(
//                     padding: const EdgeInsets.all(8),
//                     decoration: const BoxDecoration(
//                       color: Color(0xFFF3F4F6),
//                       shape: BoxShape.circle,
//                     ),
//                     child: const Icon(
//                       Icons.directions_walk,
//                       color: Color(0xFF6B7280),
//                       size: 20,
//                     ),
//                   ),
//                   const SizedBox(width: 12),
//                   const Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         'Morning Walk',
//                         style: TextStyle(
//                           fontWeight: FontWeight.bold,
//                           fontSize: 14,
//                           color: Color(0xFF1F2937),
//                         ),
//                       ),
//                       SizedBox(height: 2),
//                       Text(
//                         '30 min • Moderate',
//                         style: TextStyle(
//                           color: Color(0xFF6B7280),
//                           fontSize: 12,
//                         ),
//                       ),
//                     ],
//                   ),
//                   const Spacer(),
//                   Container(
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 8,
//                       vertical: 4,
//                     ),
//                     decoration: BoxDecoration(
//                       color: const Color(0xFFE8F5E9),
//                       borderRadius: BorderRadius.circular(10),
//                     ),
//                     child: const Text(
//                       'Completed',
//                       style: TextStyle(
//                         color: Color(0xFF2E7D32),
//                         fontSize: 11,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildActivitySelectRow(String name, IconData icon) {
//     final isSelected = _selectedActivity == name;
//     return GestureDetector(
//       onTap: () => setState(() => _selectedActivity = name),
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
//         decoration: BoxDecoration(
//           color: isSelected ? const Color(0xFFE6F4EA) : Colors.white,
//           borderRadius: BorderRadius.circular(10),
//           border: Border.all(
//             color: isSelected
//                 ? const Color(0xFF0F5132)
//                 : const Color(0xFFE5E7EB),
//             width: isSelected ? 1.5 : 1,
//           ),
//         ),
//         child: Row(
//           children: [
//             Icon(icon, color: const Color(0xFF0F5132), size: 22),
//             const SizedBox(width: 12),
//             Text(
//               name,
//               style: const TextStyle(
//                 fontSize: 14,
//                 fontWeight: FontWeight.w500,
//                 color: Color(0xFF1F2937),
//               ),
//             ),
//             const Spacer(),
//             if (isSelected)
//               const Icon(Icons.check, color: Color(0xFF0F5132), size: 18),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildIntensityCard(
//     String label,
//     String desc,
//     Color activeBorderColor,
//     Color activeBg,
//     Color activeTextColor,
//   ) {
//     final isSelected = _intensity == label;
//
//     return GestureDetector(
//       onTap: () {
//         setState(() {
//           _intensity = label;
//         });
//       },
//       child: AnimatedContainer(
//         duration: const Duration(milliseconds: 200),
//         padding: const EdgeInsets.symmetric(vertical: 12),
//         decoration: BoxDecoration(
//           color: isSelected ? activeBg : Colors.white,
//           borderRadius: BorderRadius.circular(10),
//           border: Border.all(
//             color: isSelected ? activeBorderColor : const Color(0xFFE5E7EB),
//             width: isSelected ? 1.5 : 1,
//           ),
//           boxShadow: isSelected
//               ? [
//                   BoxShadow(
//                     color: activeBorderColor.withOpacity(0.15),
//                     blurRadius: 8,
//                     offset: const Offset(0, 3),
//                   ),
//                 ]
//               : [],
//         ),
//         child: Column(
//           children: [
//             Text(
//               label,
//               style: TextStyle(
//                 fontWeight: FontWeight.bold,
//                 fontSize: 14,
//                 color: isSelected ? activeTextColor : const Color(0xFF1F2937),
//               ),
//             ),
//             const SizedBox(height: 2),
//             Text(
//               desc,
//               style: TextStyle(
//                 fontSize: 10,
//                 color: isSelected
//                     ? activeTextColor.withOpacity(0.8)
//                     : const Color(0xFF6B7280),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   IconData _getActivityIcon(String activity) {
//     final name = activity.toLowerCase();
//
//     if (name.contains('walk')) {
//       return Icons.directions_walk;
//     } else if (name.contains('run')) {
//       return Icons.directions_run;
//     } else if (name.contains('cycle') || name.contains('bike')) {
//       return Icons.directions_bike;
//     } else if (name.contains('yoga')) {
//       return Icons.self_improvement;
//     } else if (name.contains('gym')) {
//       return Icons.fitness_center;
//     } else if (name.contains('swim')) {
//       return Icons.pool;
//     } else if (name.contains('football')) {
//       return Icons.sports_soccer;
//     } else if (name.contains('basketball')) {
//       return Icons.sports_basketball;
//     }
//
//     return Icons.local_activity;
//   }
// }
import 'package:adam/ui/shared_widgets/shimmer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/activity/activity_bloc.dart';
import '../../data/models/activity_model.dart';
import '../../data/repositories/activity_repository.dart';

class ActivityLogScreen extends StatelessWidget {
  const ActivityLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ActivityBloc(
        repository: ActivityRepository(),
      ),
      child: const _ActivityLogView(),
    );
  }
}

class _ActivityLogView extends StatefulWidget {
  const _ActivityLogView();

  @override
  State<_ActivityLogView> createState() => _ActivityLogViewState();
}

class _ActivityLogViewState extends State<_ActivityLogView> {
  final ActivityRepository _repository = ActivityRepository();

  String _selectedActivity = '';
  List<String> _activities = [];
  bool _isLoadingActivities = true;

  double _duration = 30.0;
  String _intensity = 'Moderate';

  /// LIST FROM API ONLY
  List<ActivityHistoryModel> _loggedActivities = [];
  bool _isLoadingLogs = true;

  @override
  void initState() {
    super.initState();

    _loadActivities();
    _loadLoggedActivities();
  }

  /// FETCH ACTIVITIES LIST
  Future<void> _loadActivities() async {
    try {
      final activities = await _repository.fetchPhysicalActivities();

      if (!mounted) return;

      setState(() {
        _activities = activities;

        if (activities.isNotEmpty) {
          _selectedActivity = activities.first;
        }

        _isLoadingActivities = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoadingActivities = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  /// ✅ FIX: FETCH TODAY LOGGED ACTIVITIES FROM API
  Future<void> _loadLoggedActivities() async {
    try {
      final data = await _repository.fetchTodayActivities();
      print("📦 Fetched Today's Activities: $data");

      if (!mounted) return;

      setState(() {
        _loggedActivities = data;
        _isLoadingLogs = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoadingLogs = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  /// SAVE ACTIVITY
  Future<void> _saveActivity() async {
    if (_selectedActivity.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select activity')),
      );
      return;
    }

    final model = ActivityLogModel(
      durationMin: _duration.toInt(),
      intensity: _intensity,
      paName: _selectedActivity,
      timeOfDay: "Morning",
    );

    try {
      /// POST TO BACKEND
      await _repository.logActivity(model);

      /// 🔥 IMPORTANT: ALWAYS REFRESH FROM API (NO LOCAL INSERT)
      final updated = await _repository.fetchTodayActivities();

      setState(() {
        _loggedActivities = updated;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Activity Saved Successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),

      appBar: AppBar(
        backgroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        // leading: const Padding(
        //   padding: EdgeInsets.all(10.0),
        //   child: CircleAvatar(
        //     radius: 16,
        //     backgroundColor: Color(0xFFE6F4EA),
        //     child: Icon(
        //       Icons.person_outline,
        //       color: Color(0xFF0F5132),
        //       size: 18,
        //     ),
        //   ),
        // ),
        title: const Text(
          'ACTIVITY',
          style: TextStyle(
            color: Color(0xFF006B52),
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            const Text(
              'What did you do?',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),

            const SizedBox(height: 10),

            /// SEARCH FIELD (UNCHANGED UI)
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: const TextField(
                decoration: InputDecoration(
                  hintText: 'Search activities...',
                  hintStyle: TextStyle(
                    color: Color(0xFF9CA3AF),
                    fontSize: 14,
                  ),
                  prefixIcon: Icon(Icons.search, color: Color(0xFF6B7280), size: 20),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),

            const SizedBox(height: 12),

            /// ACTIVITY LIST
            _isLoadingActivities
                ?  Center(child: Shimmer.list())
                : SizedBox(
              height: 250,
              child: ListView.builder(
                itemCount: _activities.length,
                itemBuilder: (context, index) {
                  final activity = _activities[index];

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _buildActivitySelectRow(
                      activity,
                      _getActivityIcon(activity),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 24),

            /// DURATION
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'For how long?',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                Text(
                  '${_duration.toInt()} minutes',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F5132),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            Slider(
              value: _duration,
              min: 0,
              max: 100,
              activeColor: const Color(0xFF0F5132),
              onChanged: (value) {
                setState(() {
                  _duration = value;
                });
              },
            ),

            const SizedBox(height: 24),

            /// INTENSITY
            const Text(
              'How did it feel?',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(child: _buildIntensityCard('Light', 'Easy breathing')),
                const SizedBox(width: 8),
                Expanded(child: _buildIntensityCard('Moderate', 'Breathing harder')),
                const SizedBox(width: 8),
                Expanded(child: _buildIntensityCard('Vigorous', 'Breathing fast')),
              ],
            ),

            const SizedBox(height: 24),

            /// SAVE BUTTON
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _saveActivity,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F5132),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Save activity',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            Container(color: const Color(0xFFE5E7EB), height: 1),

            const SizedBox(height: 20),

            /// LOGGED TODAY
            const Text(
              'Logged today',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),

            const SizedBox(height: 12),

            /// 🔥 FIXED: ALWAYS FROM API
            if (_isLoadingLogs)
               Center(child: Shimmer.list())
            else if (_loggedActivities.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: const Center(
                  child: Text('No activities logged today'),
                ),
              )
            else
              ..._loggedActivities.map(
                    (item) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Row(
                    children: [
                      Icon(_getActivityIcon(item.paName)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.paName,
                                style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text('${item.durationMin} min • ${item.intensity}'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivitySelectRow(String name, IconData icon) {
    final isSelected = _selectedActivity == name;

    return GestureDetector(
      onTap: () => setState(() => _selectedActivity = name),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE6F4EA) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? const Color(0xFF0F5132) : const Color(0xFFE5E7EB),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF0F5132)),
            const SizedBox(width: 12),
            Text(name),
            const Spacer(),
            if (isSelected) const Icon(Icons.check, color: Color(0xFF0F5132)),
          ],
        ),
      ),
    );
  }

  Widget _buildIntensityCard(String label, String desc) {
    final isSelected = _intensity == label;

    return GestureDetector(
      onTap: () => setState(() => _intensity = label),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFF7ED) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? const Color(0xFFFDBA74) : const Color(0xFFE5E7EB),
          ),
        ),
        child: Column(
          children: [
            Text(label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isSelected ? const Color(0xFFC2410C) : const Color(0xFF1F2937),
                )),
            Text(desc, style: const TextStyle(fontSize: 10)),
          ],
        ),
      ),
    );
  }

  IconData _getActivityIcon(String activity) {
    final name = activity.toLowerCase();

    if (name.contains('walk')) return Icons.directions_walk;
    if (name.contains('run')) return Icons.directions_run;
    if (name.contains('cycle') || name.contains('bike')) return Icons.directions_bike;
    if (name.contains('yoga')) return Icons.self_improvement;
    if (name.contains('gym')) return Icons.fitness_center;
    if (name.contains('swim')) return Icons.pool;

    return Icons.local_activity;
  }
}