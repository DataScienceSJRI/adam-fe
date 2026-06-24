import 'package:adam/ui/utils/custom_calendar.dart';
import 'package:adam/ui/utils/custom_snackbar.dart';
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
  final TextEditingController _searchController = TextEditingController();
  List<String> _filteredActivities = [];
  double _duration = 30.0;
  String _intensity = 'Moderate';

  List<ActivityHistoryModel> _loggedActivities = [];
  bool _isLoadingLogs = true;
  DateTime selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadActivities();
    _loadLoggedActivities(selectedDate);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadActivities() async {
    try {
      final activities = await _repository.fetchPhysicalActivities();

      if (!mounted) return;

      setState(() {
        _activities = activities;
        _filteredActivities = activities;
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
      AppSnackBar.show(
        context,
        message: e.toString(),
        type: SnackBarType.error,
      );
    }
  }

  void _filterActivities(String query) {
    setState(() {
      if (query.trim().isEmpty) {
        _filteredActivities = _activities;
      } else {
        _filteredActivities = _activities.where((activity) {
          return activity.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

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
      AppSnackBar.show(
        context,
        message: e.toString(),
        type: SnackBarType.error,
      );
    }
  }

  Future<void> _saveActivity() async {
    if (_selectedActivity.isEmpty) {
      AppSnackBar.show(
        context,
        message: 'Please select activity',
        type: SnackBarType.error,
      );

      return;
    }

    final model = ActivityLogModel(
      durationMin: _duration.toInt(),
      intensity: _intensity,
      paName: _selectedActivity,
      date: DateFormat('yyyy-MM-dd').format(selectedDate),
    );

    try {
      await _repository.logActivity(model);

      final updated = await _repository.fetchTodayActivities(selectedDate);

      setState(() {
        _loggedActivities = updated;
      });
      AppSnackBar.show(
        context,
        message: 'Activity Saved Successfully',
        type: SnackBarType.success,
      );
    } catch (e) {
      AppSnackBar.show(
        context,
        message: e.toString(),
        type: SnackBarType.error,
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

                _loadLoggedActivities(selectedDate);
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
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _filterActivities,
                decoration: const InputDecoration(
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

            // Container(
            //   decoration: BoxDecoration(
            //     color: Colors.white,
            //     borderRadius: BorderRadius.circular(10),
            //     border: Border.all(color: const Color(0xFFE5E7EB)),
            //   ),
            //   child: const TextField(
            //     decoration: InputDecoration(
            //       hintText: 'Search activities...',
            //       hintStyle: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
            //       prefixIcon: Icon(
            //         Icons.search,
            //         color: Color(0xFF6B7280),
            //         size: 20,
            //       ),
            //       border: InputBorder.none,
            //       contentPadding: EdgeInsets.symmetric(vertical: 12),
            //     ),
            //   ),
            // ),
            const SizedBox(height: 12),

            _isLoadingActivities
                ? Center(child: Shimmer.list())
                : SizedBox(
                    height: 250,
                    child: ListView.builder(
                      itemCount: _filteredActivities.length,
                      itemBuilder: (context, index) {
                        final activity = _filteredActivities[index];

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

            const Text(
              'Logged ',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),

            const SizedBox(height: 12),

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
                      InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () => _showEditActivityDialog(item),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE6F4EA),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.edit_outlined,
                            size: 18,
                            color: Color(0xFF0F5132),
                          ),
                        ),
                      ),

                      const SizedBox(width: 8),

                      InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () => _deleteActivity(item),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFEAEA),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.delete_outline,
                            size: 18,
                            color: Colors.red,
                          ),
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

  Future<void> _deleteActivity(ActivityHistoryModel item) async {
    final confirm = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              const SizedBox(height: 20),

              const Icon(Icons.delete_outline, color: Colors.red, size: 40),

              const SizedBox(height: 12),

              const Text(
                'Delete Activity?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 8),

              Text(
                'Remove "${item.paName}" from your activity log?',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
              ),

              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text(
                        'Delete',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );

    if (confirm != true) return;

    try {
      await _repository.deleteActivity(item.id);

      await _loadLoggedActivities(selectedDate);

      AppSnackBar.show(
        context,
        message: 'Activity deleted',
        type: SnackBarType.success,
      );
    } catch (e) {
      AppSnackBar.show(
        context,
        message: e.toString(),
        type: SnackBarType.error,
      );
    }
  }

  void _showEditActivityDialog(ActivityHistoryModel item) {
    final durationController = TextEditingController(
      text: item.durationMin.toString(),
    );

    String intensity = item.intensity;
    String selectedActivity = item.paName;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Container(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Icon(
                    Icons.edit_note_rounded,
                    size: 40,
                    color: Color(0xFF0F5132),
                  ),

                  const SizedBox(height: 12),

                  const Text(
                    'Edit Activity',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),

                  const SizedBox(height: 6),

                  DropdownButtonFormField<String>(
                    value: selectedActivity,
                    decoration: InputDecoration(
                      labelText: 'Activity',
                      filled: true,
                      fillColor: const Color(0xFFF9FAFB),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                    ),
                    items: _activities.map((activity) {
                      return DropdownMenuItem(
                        value: activity,
                        child: Text(activity),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setDialogState(() {
                        selectedActivity = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 24),

                  TextField(
                    controller: durationController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Duration (minutes)',
                      filled: true,
                      fillColor: const Color(0xFFF9FAFB),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  DropdownButtonFormField<String>(
                    value: intensity,
                    decoration: InputDecoration(
                      labelText: 'Intensity',
                      filled: true,
                      fillColor: const Color(0xFFF9FAFB),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Light', child: Text('Light')),
                      DropdownMenuItem(
                        value: 'Moderate',
                        child: Text('Moderate'),
                      ),
                      DropdownMenuItem(
                        value: 'Vigorous',
                        child: Text('Vigorous'),
                      ),
                    ],
                    onChanged: (value) {
                      setDialogState(() {
                        intensity = value!;
                      });
                    },
                  ),

                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            try {
                              final updatedModel = ActivityLogModel(
                                paName: selectedActivity,
                                durationMin:
                                    int.tryParse(durationController.text) ?? 0,
                                intensity: intensity,
                                date: item.date,
                              );

                              await _repository.editActivity(
                                activityId: item.id,
                                model: updatedModel,
                              );

                              await _loadLoggedActivities(selectedDate);

                              AppSnackBar.show(
                                context,
                                message: 'Activity updated successfully',
                                type: SnackBarType.success,
                              );
                              Navigator.pop(context);
                            } catch (e) {
                              AppSnackBar.show(
                                context,
                                message: e.toString(),
                                type: SnackBarType.error,
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0F5132),
                            minimumSize: const Size.fromHeight(50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Update',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
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
