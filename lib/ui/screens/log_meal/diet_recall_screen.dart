import 'package:adam/bloc/diet_recall/diet_recall_bloc.dart';
import 'package:adam/data/repositories/diet_recall_repository.dart';
import 'package:adam/data/repositories/plan_meal_repository.dart';
import 'package:adam/ui/screens/log_meal/log_meal_screen.dart';
import 'package:adam/ui/utils/custom_calendar.dart';
import 'package:adam/ui/utils/custom_snackbar.dart';
import 'package:adam/ui/utils/shimmer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class DietRecallScreen extends StatefulWidget {
  const DietRecallScreen({super.key});

  @override
  State<DietRecallScreen> createState() => DietRecallScreenState();
}

class DietRecallScreenState extends State<DietRecallScreen> {
  String _selectedMealPeriod = 'Breakfast';
  final MealPlanRepository mealPlanRepository = MealPlanRepository();
  final List<String> _mealPeriods = ['Breakfast', 'Lunch', 'Dinner', 'Snacks'];
  Map<String, String> _mealPlanIdsMap = {};
  bool _isLoading = true;
  final Map<String, List<String>> _mealQuantitiesMap = {};
  DateTime selectedDate = DateTime.now();
  String? planId;

  @override
  void initState() {
    super.initState();
    _fetchPlanId(selectedDate);
  }
  Future<void> _fetchPlanId(DateTime selectedDate) async {
    setState(() => _isLoading = true);

    try {
      final String date = DateFormat('yyyy-MM-dd').format(selectedDate);

      final response = await mealPlanRepository.fetchMealPlan(date: date);

      final Map<String, String> tempPlanIds = {};

      if (response != null) {
        for (var meal in response) {
          final slot = meal.mealType.trim().toLowerCase();

          if (slot.isNotEmpty && meal.planId.isNotEmpty) {
            tempPlanIds[slot] = meal.planId;
          }
        }
      }

      setState(() {
        _mealPlanIdsMap = tempPlanIds;
        _isLoading = false;
        planId = response[0].planId;
        print("this is coming from call ${planId}");
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => DietRecallBloc(repository: DietRecallRepository()),

      child: BlocListener<DietRecallBloc, DietRecallState>(
        listener: (context, state) {
          if (state is DietRecallSuccess) {
            AppSnackBar.show(
              context,
              message: "Meal logged successfully",
              type: SnackBarType.success,
            );
          }
          if (state is DietRecallFailure) {
            AppSnackBar.show(
              context,
              message: state.message,
              type: SnackBarType.error,
            );
          }
        },

        child: Scaffold(
          backgroundColor: const Color(0xFFF7F7F7),

          appBar: AppBar(
            backgroundColor: Colors.white,
            centerTitle: true,
            elevation: 0,
            title: const Text(
              'RECALL',
              style: TextStyle(
                color: Color(0xFF006B52),
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
          ),

          body: _isLoading
              ? Shimmer.list()
              : Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),

                        child: Column(
                          children: [
                            CustomCalendar(
                              initialDate: selectedDate,
                              onDateSelected: (date) {
                                setState(() {
                                  selectedDate = date;
                                });

                                _fetchPlanId(date);
                              },
                            ),
                            const SizedBox(height: 20),

                            Container(
                              height: 42,
                              padding: const EdgeInsets.all(3),

                              decoration: BoxDecoration(
                                color: const Color(0xFFE3E3E3),
                                borderRadius: BorderRadius.circular(7),
                              ),

                              child: Row(
                                children: _mealPeriods.map((meal) {
                                  final isSelected =
                                      _selectedMealPeriod == meal;

                                  return Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _selectedMealPeriod = meal;
                                        });
                                      },

                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? Colors.white
                                              : Colors.transparent,

                                          borderRadius: BorderRadius.circular(
                                            5,
                                          ),

                                          border: isSelected
                                              ? Border.all(
                                                  color: const Color(
                                                    0xFFD1D1D1,
                                                  ),
                                                )
                                              : null,
                                        ),

                                        alignment: Alignment.center,

                                        child: Text(
                                          meal,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,

                                            color: isSelected
                                                ? Colors.black
                                                : Colors.black54,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),

                            const SizedBox(height: 30),

                            const Text(
                              'Did you eat as planned?',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),

                            const SizedBox(height: 16),
                            _buildOptionCard(
                              emoji: '✅',
                              text: 'Yes, I ate as planned',
                              onTap: () {
                                print("my plan id $planId");
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => LogMealScreen(
                                      tab: true,
                                      planId: planId,
                                      didEatPlanned: true,
                                      meal: _selectedMealPeriod,
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 14),

                            _buildOptionCard(
                              emoji: '✏️',
                              text: 'No, I changed something',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => LogMealScreen(
                                      tab: true,
                                      planId: planId,
                                      didEatPlanned: false,
                                      meal: _selectedMealPeriod,
                                    ),
                                  ),
                                );
                              },
                            ),

                            const SizedBox(height: 28),

                            BlocBuilder<DietRecallBloc, DietRecallState>(
                              builder: (context, state) {
                                return GestureDetector(
                                  onTap: state is DietRecallLoading
                                      ? () {}
                                      : () {
                                          final String? planId =
                                              _mealPlanIdsMap[_selectedMealPeriod
                                                  .toLowerCase()];

                                          final List<String> quantities =
                                              _mealQuantitiesMap[_selectedMealPeriod
                                                  .toLowerCase()] ??
                                              [];

                                          if (planId != null) {
                                            context.read<DietRecallBloc>().add(
                                              SubmitDietRecallEvent(
                                                mealSlot: _selectedMealPeriod,
                                                planId: planId,
                                                recipeCodes: [],
                                                quantities: quantities,
                                                didEatAsPlanned: false,
                                              ),
                                            );
                                          } else {
                                            AppSnackBar.show(
                                              context,
                                              message:
                                                  "No meal plan found to skip.",
                                              type: SnackBarType.error,
                                            );
                                          }
                                        },

                                  child: const Text(
                                    'I skipped this meal',
                                    style: TextStyle(
                                      color: Color(0xFF006B52),
                                      fontSize: 13,
                                      decoration: TextDecoration.underline,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required String emoji,
    required String text,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,

      child: Container(
        width: double.infinity,

        padding: const EdgeInsets.symmetric(vertical: 22),

        decoration: BoxDecoration(
          color: Colors.white,

          borderRadius: BorderRadius.circular(12),

          border: Border.all(color: const Color(0xFFD5DDD8)),
        ),

        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 36)),

            const SizedBox(height: 10),

            Text(
              text,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }
}
