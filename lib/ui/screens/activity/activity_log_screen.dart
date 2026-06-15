import 'package:adam/ui/utils/custom_calendar.dart';
import 'package:adam/ui/utils/shimmer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../bloc/activity/activity_bloc.dart';
import '../../../data/models/activity_model.dart';
import '../../../data/repositories/activity_repository.dart';

class ActivityLogScreen extends StatelessWidget {
  const ActivityLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ActivityBloc(repository: ActivityRepository()),
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
  DateTime selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();

    _loadActivities();
    _loadLoggedActivities(selectedDate);
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

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  /// ✅ FIX: FETCH TODAY LOGGED ACTIVITIES FROM API
  Future<void> _loadLoggedActivities(DateTime date) async {
    try {
      final data = await _repository.fetchTodayActivities(date);

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

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  /// SAVE ACTIVITY
  Future<void> _saveActivity() async {
    if (_selectedActivity.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select activity')));
      return;
    }

    final model = ActivityLogModel(
      durationMin: _duration.toInt(),
      intensity: _intensity,
      paName: _selectedActivity,
      // timeOfDay: "Morning",
      date: DateFormat('yyyy-MM-dd').format(selectedDate)
    );

    try {
      /// POST TO BACKEND
      await _repository.logActivity(model);

      /// 🔥 IMPORTANT: ALWAYS REFRESH FROM API (NO LOCAL INSERT)
      final updated = await _repository.fetchTodayActivities(selectedDate);

      setState(() {
        _loggedActivities = updated;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Activity Saved Successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
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
            CustomCalendar(
              initialDate: selectedDate,
              onDateSelected: (date) {
                setState(() {
                  selectedDate = date;
                });

                _loadLoggedActivities(date);
              },
            ),
            const SizedBox(height: 10),

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
                  hintStyle: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
                  prefixIcon: Icon(
                    Icons.search,
                    color: Color(0xFF6B7280),
                    size: 20,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),

            const SizedBox(height: 12),

            /// ACTIVITY LIST
            _isLoadingActivities
                ? Center(child: Shimmer.list())
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
                Expanded(
                  child: _buildIntensityCard('Moderate', 'Breathing harder'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildIntensityCard('Vigorous', 'Breathing fast'),
                ),
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
              'Logged ',
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
                child: const Center(child: Text('No activities logged today')),
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
                            Text(
                              item.paName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text('${item.durationMin} min • ${item.intensity}'),
                            Text('Logged on: ${item.date}'),
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
            color: isSelected
                ? const Color(0xFF0F5132)
                : const Color(0xFFE5E7EB),
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
            color: isSelected
                ? const Color(0xFFFDBA74)
                : const Color(0xFFE5E7EB),
          ),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected
                    ? const Color(0xFFC2410C)
                    : const Color(0xFF1F2937),
              ),
            ),
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
    if (name.contains('cycle') || name.contains('bike'))
      return Icons.directions_bike;
    if (name.contains('yoga')) return Icons.self_improvement;
    if (name.contains('gym')) return Icons.fitness_center;
    if (name.contains('swim')) return Icons.pool;

    return Icons.local_activity;
  }
}
