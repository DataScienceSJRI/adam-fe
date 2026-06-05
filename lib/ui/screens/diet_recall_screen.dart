import 'package:adam/bloc/diet_recall/diet_recall_bloc.dart';
import 'package:adam/data/repositories/diet_recall_repository.dart';
import 'package:adam/data/repositories/plan_meal_repository.dart';
import 'package:adam/ui/screens/log_meal_screen.dart';
import 'package:adam/ui/shared_widgets/custom_snackbar.dart';
import 'package:adam/ui/shared_widgets/shimmer.dart';
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
  Map<String, List<String>> _mealRecipeCodesMap = {};
  Map<String, List<String>> _mealQuantitiesMap = {};
  List<dynamic> _allMeals = [];

  @override
  void initState() {
    super.initState();
    _fetchPlanId();
  }

  // Future<void> _fetchPlanId() async {
  //   // print("mealSlot ===== $mealSlot");
  //   // if (currentPlanId == null) return;
  //
  //   final response = await mealPlanRepository.fetchMealPlan(
  //     date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
  //   );
  //   print("mealSlot ===== ${response.toString()}");
  //
  //   // setState(() {
  //   //   mealReactions[mealSlot] = response;
  //   // });
  // }
  // Future<void> _fetchPlanId() async {
  //   print("DEBUG: _fetchPlanId started...");
  //   setState(() => _isLoading = true);
  //
  //   try {
  //     final String date = DateFormat('yyyy-MM-dd').format(DateTime.now());
  //     print("DEBUG: Fetching plan for date: $date");
  //
  //     final response = await mealPlanRepository.fetchMealPlan(date: date);
  //     print("DEBUG: API Response received: ${response?.length ?? 0} items");
  //
  //     // Initialize/Reset maps
  //     final Map<String, String> tempPlanIds = {};
  //     final Map<String, List<String>> tempRecipeCodes = {};
  //     final Map<String, List<String>> tempQuantities = {};
  //
  //     if (response != null) {
  //       for (var meal in response) {
  //         final slot = meal.mealType.trim().toLowerCase();
  //         final uuid = meal.planId;
  //         final code = meal.recipeCode.toString();
  //         // Assuming your model has a quantity field, e.g., meal.quantity
  //         final qty = meal.quantity.toString();
  //
  //         print(
  //           "DEBUG: Processing - Type: $slot, ID: $uuid, Code: $code, Qty: $qty",
  //         );
  //
  //         // 1. Map Plan ID (Single String)
  //         if (slot.isNotEmpty && uuid.isNotEmpty) {
  //           tempPlanIds[slot] = uuid;
  //         }
  //
  //         // 2. Map Recipe Codes (List)
  //         tempRecipeCodes[slot] ??= [];
  //         tempRecipeCodes[slot]!.add(code);
  //
  //         // 3. Map Quantities (List)
  //         tempQuantities[slot] ??= [];
  //         tempQuantities[slot]!.add(qty);
  //       }
  //     }
  //
  //     if (mounted) {
  //       setState(() {
  //         _mealPlanIdsMap = tempPlanIds;
  //         _mealRecipeCodesMap = tempRecipeCodes;
  //         _mealQuantitiesMap = tempQuantities;
  //         _isLoading = false;
  //       });
  //       print("DEBUG: Maps updated successfully.");
  //     }
  //   } catch (e) {
  //     if (mounted) setState(() => _isLoading = false);
  //     print("DEBUG: Error fetching plan: $e");
  //   }
  // }
  Future<void> _fetchPlanId() async {
    setState(() => _isLoading = true);

    try {
      final String date = DateFormat('yyyy-MM-dd').format(DateTime.now());
      print("DEBUG: Fetching data for date: $date");

      final response = await mealPlanRepository.fetchMealPlan(date: date);

      // Check if response itself is null or empty
      if (response == null) {
        print("DEBUG: Repository returned NULL");
      } else {
        print("DEBUG: Repository returned ${response.length} items");
      }

      if (response != null && response.isNotEmpty) {
        setState(() {
          _allMeals = response; // Assigning the actual list
        });
        print("DEBUG: _allMeals successfully updated with ${response.length} items.");

        // Now build your maps
        final Map<String, String> tempPlanIds = {};
        for (var meal in response) {
          final slot = meal.mealType.trim().toLowerCase();
          if (slot.isNotEmpty && meal.planId.isNotEmpty) {
            tempPlanIds[slot] = meal.planId;
          }
        }

        setState(() {
          _mealPlanIdsMap = tempPlanIds;
        });
      }

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      print("DEBUG: Error in _fetchPlanId: $e");
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
            //   ScaffoldMessenger.of(
            //     context,
            //   ).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },

        child: Scaffold(
          backgroundColor: const Color(0xFFF7F7F7),

          // ================= APP BAR =================
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

          // ================= BODY =================
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
                            const SizedBox(height: 20),

                            // ================= MEAL TAB =================
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

                            /// QUESTION
                            const Text(
                              'Did you eat as planned?',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),

                            const SizedBox(height: 16),

                            // BlocBuilder<DietRecallBloc, DietRecallState>(
                            //   builder: (context, state) {
                            //     return _buildOptionCard(
                            //       emoji: state is DietRecallLoading ? '⏳' : '✅',
                            //
                            //       text: state is DietRecallLoading
                            //           ? 'Logging meal...'
                            //           : 'Yes, I ate as planned',
                            //
                            //       onTap: state is DietRecallLoading
                            //           ? () {}
                            //           : () {
                            //               context.read<DietRecallBloc>().add(
                            //                 SubmitDietRecallEvent(
                            //                   mealSlot: _selectedMealPeriod,
                            //                   planId: "abc",
                            //                   didEatAsPlanned: true,
                            //                 ),
                            //               );
                            //             },
                            //     );
                            //   },
                            // ),
                            BlocBuilder<DietRecallBloc, DietRecallState>(
                              builder: (context, state) {
                                return _buildOptionCard(
                                  emoji: state is DietRecallLoading ? '⏳' : '✅',
                                  text: state is DietRecallLoading
                                      ? 'Logging meal...'
                                      : 'Yes, I ate as planned',
                                  onTap: state is DietRecallLoading
                                      ? () {}
                                      : () {
                                          print(
                                            "DEBUG: Selected period: '${_selectedMealPeriod.toLowerCase()}'",
                                          );
                                          print(
                                            "DEBUG: Total meals in _allMeals: ${_allMeals.length}",
                                          );

                                          // Print each meal type found in the list
                                          for (var m in _allMeals) {
                                            print(
                                              "DEBUG: Available meal type in data: '${m.mealType.trim().toLowerCase()}'",
                                            );
                                          }

                                          final List<dynamic> currentSlotMeals =
                                              _allMeals.where((meal) {
                                                final dataSlot = meal.mealType
                                                    .trim()
                                                    .toLowerCase();
                                                final selectedSlot =
                                                    _selectedMealPeriod
                                                        .trim()
                                                        .toLowerCase();
                                                return dataSlot == selectedSlot;
                                              }).toList();

                                          print(
                                            "DEBUG: Meals found for this slot: ${currentSlotMeals.length}",
                                          );

                                          // 2. Lookup the planId from your map
                                          final String? planId =
                                              _mealPlanIdsMap[_selectedMealPeriod
                                                  .toLowerCase()];

                                          // 3. Extract the lists from the filtered items
                                          final List<String> codes =
                                              currentSlotMeals
                                                  .map(
                                                    (m) =>
                                                        m.recipeCode.toString(),
                                                  )
                                                  .toList();
                                          final List<String> quantities =
                                              currentSlotMeals
                                                  .map(
                                                    (m) =>
                                                        m.quantity.toString(),
                                                  )
                                                  .toList();

                                          // 4. Validation
                                          if (planId == null ||
                                              currentSlotMeals.isEmpty) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  "No meal plan found for this time.",
                                                ),
                                              ),
                                            );
                                            return;
                                          }

                                          // 5. Dispatch
                                          context.read<DietRecallBloc>().add(
                                            SubmitDietRecallEvent(
                                              mealSlot: _selectedMealPeriod,
                                              planId: planId,
                                              didEatAsPlanned: true,
                                              recipeCodes: codes,
                                              // Use the variable created in step 3
                                              quantities:
                                                  quantities, // Use the variable created in step 3
                                            ),
                                          );
                                        },
                                );
                              },
                            ),
                            const SizedBox(height: 14),

                            _buildOptionCard(
                              emoji: '✏️',
                              text: 'No, I changed something',
                              onTap: () {
                                final String? planId = _mealPlanIdsMap[_selectedMealPeriod.toLowerCase()];
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => LogMealScreen(
                                      tab: true,
                                      planId: planId, // Pass it here
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
                                            // Optional: Handle the case where no plan exists
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  "No meal plan found to skip.",
                                                ),
                                              ),
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
