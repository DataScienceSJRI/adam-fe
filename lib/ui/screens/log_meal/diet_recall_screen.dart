import 'dart:async';

import 'package:adam/bloc/diet_recall/diet_recall_bloc.dart';
import 'package:adam/data/models/recipe_model.dart';
import 'package:adam/data/repositories/diet_recall_repository.dart';
import 'package:adam/data/repositories/plan_meal_repository.dart';
import 'package:adam/data/repositories/recipe_repository.dart';
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
  final String _selectedMealPeriod = 'Breakfast';
  final MealPlanRepository mealPlanRepository = MealPlanRepository();
  Map<String, String> _mealPlanIdsMap = {};
  bool _isLoading = true;
  final Map<String, List<String>> _mealQuantitiesMap = {};
  DateTime selectedDate = DateTime.now();
  String? planId;
  final DietRecallRepository _dietRepo = DietRecallRepository();
  List<dynamic> recallItems = [];
  Timer? _debounce;
  List<Recipe> searchedRecipes = [];
  bool isSearching = false;
  final RecipeRepository _recipeRepository = RecipeRepository();
  Recipe? selectedRecipe;
  bool _isLoadingLoggedItems = false;

  @override
  void initState() {
    super.initState();
    _fetchPlanId(selectedDate);
    _fetchRecall(selectedDate);
  }

  @override
  void didUpdateWidget(covariant DietRecallScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Checks if this specific screen has become the active top route again
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && ModalRoute.of(context)?.isCurrent == true) {
        debugPrint("🚀 Screen is officially active! Forcing API call...");
        _fetchPlanId(selectedDate);
        _fetchInlineRecallItems(selectedDate);
      }
    });
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

  Future<void> _fetchRecall(DateTime date) async {
    try {
      final String formattedDate = DateFormat(
        'yyyy-MM-dd',
      ).format(selectedDate);

      final response = await _dietRepo.getRecall(date: formattedDate);

      if (!mounted) return;

      setState(() {
        recallItems = response['items'] ?? [];
      });

      print("✅ RECALL ITEMS ===== $recallItems");
    } catch (e) {
      print("❌ RECALL ERROR ===== $e");
    }
  }

  Future<void> _deleteRecall(String recallId) async {
    try {
      await _dietRepo.deleteRecall(recallId: recallId);

      await _fetchRecall(selectedDate);

      AppSnackBar.show(
        context,
        message: "Deleted successfully",
        type: SnackBarType.success,
      );
    } catch (e) {
      AppSnackBar.show(
        context,
        message: "Failed to delete meal",
        type: SnackBarType.error,
      );

      print("❌ DELETE RECALL ERROR ===== $e");
    }
  }

  void _showRecallEditBottomSheet(Map<String, dynamic> item) {
    final recipeController = TextEditingController(
      text: (item['food_name'] ?? '').toString(),
    );

    final quantityController = TextEditingController(
      text: (item['food_qty'] ?? '').toString(),
    );

    String selectedMealTime = (item['meal_slot'] ?? 'breakfast')
        .toString()
        .toLowerCase();

    final mealTimes = ['breakfast', 'lunch', 'dinner', 'snacks'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Material(
          color: Colors.transparent,
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Padding(
                  padding: EdgeInsets.only(
                    left: 20,
                    right: 20,
                    top: 14,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 45,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Center(
                        child: Text(
                          "Edit Meal Details",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      Flexible(
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextField(
                                controller: recipeController,
                                onChanged: (value) {
                                  if (_debounce?.isActive ?? false)
                                    _debounce?.cancel();
                                  _debounce = Timer(
                                    const Duration(milliseconds: 500),
                                    () => _searchRecipes(value),
                                  );
                                },
                                decoration: InputDecoration(
                                  labelText: "Recipe Name",
                                  prefixIcon: const Icon(Icons.search),
                                  suffixIcon: isSearching
                                      ? Padding(
                                          padding: const EdgeInsets.all(14),
                                          child: SizedBox(
                                            height: 18,
                                            width: 18,
                                            child: Shimmer.card(),
                                          ),
                                        )
                                      : null,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: quantityController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                decoration: InputDecoration(
                                  labelText: "Quantity",
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              DropdownButtonFormField<String>(
                                value: selectedMealTime,
                                decoration: InputDecoration(
                                  labelText: "Meal Time",
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                items: mealTimes
                                    .map(
                                      (meal) => DropdownMenuItem(
                                        value: meal,
                                        child: Text(
                                          meal[0].toUpperCase() +
                                              meal.substring(1),
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    setModalState(
                                      () => selectedMealTime = value,
                                    );
                                  }
                                },
                              ),
                              if (searchedRecipes.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                (() {
                                  final localRecipes = List.of(searchedRecipes);

                                  return Container(
                                    constraints: const BoxConstraints(
                                      maxHeight: 200,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: const Color(0xFFE4E4E4),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: ListView.separated(
                                      shrinkWrap: true,
                                      padding: const EdgeInsets.all(8),
                                      itemCount: localRecipes.length,
                                      separatorBuilder: (_, __) =>
                                          const Divider(height: 1),
                                      itemBuilder: (context, index) {
                                        final recipe = localRecipes[index];
                                        return ListTile(
                                          leading: ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            child: Image.network(
                                              'https://datatools.sjri.res.in/static/VD/food_images_large/${recipe.recipeCode}.jpg',
                                              width: 40,
                                              height: 40,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) =>
                                                  const Icon(Icons.fastfood),
                                            ),
                                          ),
                                          title: Text(recipe.recipeName),
                                          onTap: () {
                                            recipeController.text =
                                                recipe.recipeName;
                                            setState(() {
                                              selectedRecipe = recipe;
                                              searchedRecipes.clear();
                                            });
                                            FocusScope.of(context).unfocus();
                                          },
                                        );
                                      },
                                    ),
                                  );
                                })(),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton.icon(
                          // onPressed: () async {
                          //   final String enteredFoodName = recipeController.text
                          //       .trim();
                          //   final String enteredQuantity = quantityController
                          //       .text
                          //       .trim();
                          //
                          //   if (enteredFoodName.isEmpty) {
                          //     AppSnackBar.show(
                          //       sheetContext,
                          //       message: "Meal name cannot be empty",
                          //       type: SnackBarType.error,
                          //     );
                          //     return;
                          //   }
                          //
                          //   if (enteredQuantity.isEmpty ||
                          //       double.tryParse(enteredQuantity) == null ||
                          //       double.parse(enteredQuantity) <= 0) {
                          //     AppSnackBar.show(
                          //       sheetContext,
                          //       message:
                          //           "Please enter a valid quantity greater than 0",
                          //       type: SnackBarType.error,
                          //     );
                          //     return;
                          //   }
                          //
                          //   try {
                          //     await _dietRepo.editRecall(
                          //       recallId: item['id'],
                          //       foodName: enteredFoodName,
                          //       quantity: enteredQuantity,
                          //       mealSlot: selectedMealTime,
                          //       didEatAsPlanned:
                          //           item['did_eat_as_planned'] ?? false,
                          //     );
                          //
                          //     if (!mounted) return;
                          //     Navigator.pop(sheetContext);
                          //     await _fetchInlineRecallItems(selectedDate);
                          //   } catch (e) {
                          //     AppSnackBar.show(
                          //       sheetContext,
                          //       message: "Failed to update meal",
                          //       type: SnackBarType.error,
                          //     );
                          //   }
                          // },
                          onPressed: () async {
                            final String enteredFoodName = recipeController.text
                                .trim();
                            final String enteredQuantity = quantityController
                                .text
                                .trim();

                            if (enteredFoodName.isEmpty) {
                              AppSnackBar.show(
                                sheetContext,
                                message: "Meal name cannot be empty",
                                type: SnackBarType.error,
                              );
                              return;
                            }

                            if (enteredQuantity.isEmpty ||
                                double.tryParse(enteredQuantity) == null ||
                                double.parse(enteredQuantity) <= 0) {
                              AppSnackBar.show(
                                sheetContext,
                                message:
                                    "Please enter a valid quantity greater than 0",
                                type: SnackBarType.error,
                              );
                              return;
                            }

                            final recipeToUse = selectedRecipe;
                            print("=========== EDIT SAVE ===========");
                            print("selectedMealTime = $selectedMealTime");
                            print("item id = ${item["id"]}");
                            print("recallItems = $recallItems");

                            final shouldSave = await _shouldProceedWithSave(
                              mealSlot: selectedMealTime,
                              recipeCode: selectedRecipe?.recipeCode,
                              quantity: quantityController.text,
                              recallIdToIgnore: item["id"],
                            );
                            print("shouldSave = $shouldSave");

                            if (!shouldSave) {
                              return;
                            }

                            try {
                              await _dietRepo.editRecall(
                                recallId: item['id'],
                                foodName: enteredFoodName,
                                quantity: enteredQuantity,
                                mealSlot: selectedMealTime,
                                didEatAsPlanned:
                                    item['did_eat_as_planned'] ?? false,
                              );

                              if (!mounted) return;

                              await _fetchInlineRecallItems(selectedDate);
                              Navigator.pop(sheetContext);

                              AppSnackBar.show(
                                sheetContext,
                                message: "Meal updated successfully",
                                type: SnackBarType.success,
                              );
                            } catch (e) {
                              AppSnackBar.show(
                                sheetContext,
                                message: "Failed to update meal",
                                type: SnackBarType.error,
                              );
                            }
                          },
                          icon: const Icon(Icons.check),
                          label: const Text(
                            "Update Meal Details",
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF008C5E),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
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
        );
      },
    );
  }

  Future<bool> _shouldProceedWithSave({
    String? mealSlot,
    String? recipeCode,
    required String quantity,
    String? recallIdToIgnore,
  }) async {
    print("\n========== _shouldProceedWithSave ==========");

    mealSlot = (mealSlot ?? "").trim().toLowerCase();

    print("mealSlot = $mealSlot");
    print("recipeCode = $recipeCode");
    print("quantity = $quantity");
    print("recallIdToIgnore = $recallIdToIgnore");

    //--------------------------------------------------
    // Validation
    //--------------------------------------------------

    if (mealSlot.isEmpty) {
      print("Meal slot is empty");
      return true;
    }

    final qty = double.tryParse(quantity.trim()) ?? 0;

    if (qty <= 0) {
      print("Quantity invalid");
      return true;
    }

    //--------------------------------------------------
    // Calorie Limit
    //--------------------------------------------------

    final limit = mealSlot == "snacks" ? 500 : 750;

    print("Limit = $limit");

    //--------------------------------------------------
    // Calculate already logged calories
    //--------------------------------------------------

    double totalCalories = 0;

    print("\n------------- RECALL ITEMS -------------");

    for (final item in recallItems) {
      final itemId = (item["id"] ?? "").toString();

      // if (recallIdToIgnore != null && itemId == recallIdToIgnore) {
      //   print("Skipping edited item -> $itemId");
      //   continue;
      // }

      final itemMealSlot = (item["meal_slot"] ?? "")
          .toString()
          .trim()
          .toLowerCase();

      final energy = double.tryParse(item["energy_kcal"].toString()) ?? 0;

      print("slot=$itemMealSlot | kcal=$energy | food=${item["food_name"]}");

      if (itemMealSlot == mealSlot) {
        totalCalories += energy;
        print("MATCH -> Running Total = $totalCalories");
      }
    }

    print("----------------------------------------");
    print("Meal Slot      = $mealSlot");
    print("Total Calories = $totalCalories");
    print("Limit          = $limit");
    print("----------------------------------------");

    //--------------------------------------------------
    // Show dialog if exceeded
    //--------------------------------------------------

    if (totalCalories <= limit) {
      print("Calories within limit.");
      return true;
    }

    print("Calories exceeded. Showing dialog...");

    final result = await _showConfirmationDialog(
      totalCalories,
      limit,
      mealSlot,
    );

    return result ?? false;
  }

  Future<bool?> _showConfirmationDialog(
    double totalCalories,
    int limit,
    String mealSlot,
  ) {
    print("\n========== SHOW DIALOG ==========");
    print("Meal Slot = $mealSlot");
    print("Total Calories = $totalCalories");
    print("Limit = $limit");

    final title = mealSlot.isNotEmpty
        ? "${mealSlot[0].toUpperCase()}${mealSlot.substring(1)}"
        : "Meal";

    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text("Confirm Meal Log"),
        content: Text(
          "You have already logged "
          "${totalCalories.toStringAsFixed(0)} kcal for $title.\n\n"
          "This exceeds the recommended limit of $limit kcal.\n\n"
          "Are you sure you want to log another meal?",
        ),
        actions: [
          TextButton(
            onPressed: () {
              print("❌ User tapped Cancel");
              Navigator.pop(context, false);
            },
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              print("✅ User tapped Log Anyway");
              Navigator.pop(context, true);
            },
            child: const Text("Log Anyway"),
          ),
        ],
      ),
    );
  }

  Future<void> _searchRecipes(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        searchedRecipes.clear();
      });
      return;
    }

    try {
      setState(() {
        isSearching = true;
      });

      final response = await _recipeRepository.searchLogRecipes(query: query);

      debugPrint("SEARCH RESPONSE => $response");

      List<dynamic> data = [];

      if (response['results'] != null) {
        data = response['results'];
      } else if (response['data'] != null) {
        data = response['data'];
      } else if (response['recipes'] != null) {
        data = response['recipes'];
      }

      searchedRecipes = data.map((e) => Recipe.fromJson(e)).toList();

      setState(() {});
    } catch (e) {
      debugPrint("Search Error: $e");
    } finally {
      setState(() {
        isSearching = false;
      });
    }
  }

  Future<void> _fetchInlineRecallItems(DateTime date) async {
    try {
      setState(() => _isLoadingLoggedItems = true);
      final String formattedDate = DateFormat('yyyy-MM-dd').format(date);
      final response = await _dietRepo.getRecall(date: formattedDate);

      if (!mounted) return;
      setState(() {
        recallItems = response['items'] ?? [];
        _isLoadingLoggedItems = false;
      });
    } catch (e) {
      setState(() => _isLoadingLoggedItems = false);
      debugPrint("❌ Error loading inline items: $e");
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
                                _fetchInlineRecallItems(date);
                              },
                            ),
                            const SizedBox(height: 20),

                            // Container(
                            //   height: 42,
                            //   padding: const EdgeInsets.all(3),
                            //
                            //   decoration: BoxDecoration(
                            //     color: const Color(0xFFE3E3E3),
                            //     borderRadius: BorderRadius.circular(7),
                            //   ),
                            //
                            //   child: Row(
                            //     children: _mealPeriods.map((meal) {
                            //       final isSelected =
                            //           _selectedMealPeriod == meal;
                            //
                            //       return Expanded(
                            //         child: GestureDetector(
                            //           onTap: () {
                            //             setState(() {
                            //               _selectedMealPeriod = meal;
                            //             });
                            //           },
                            //
                            //           child: Container(
                            //             decoration: BoxDecoration(
                            //               color: isSelected
                            //                   ? Colors.white
                            //                   : Colors.transparent,
                            //
                            //               borderRadius: BorderRadius.circular(
                            //                 5,
                            //               ),
                            //
                            //               border: isSelected
                            //                   ? Border.all(
                            //                       color: const Color(
                            //                         0xFFD1D1D1,
                            //                       ),
                            //                     )
                            //                   : null,
                            //             ),
                            //
                            //             alignment: Alignment.center,
                            //
                            //             child: Text(
                            //               meal,
                            //               style: TextStyle(
                            //                 fontSize: 13,
                            //                 fontWeight: FontWeight.w500,
                            //
                            //                 color: isSelected
                            //                     ? Colors.black
                            //                     : Colors.black54,
                            //               ),
                            //             ),
                            //           ),
                            //         ),
                            //       );
                            //     }).toList(),
                            //   ),
                            // ),
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
                              onTap: () async {
                                print("my plan id $planId");
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => LogMealScreen(
                                      tab: true,
                                      planId: planId,
                                      didEatPlanned: true,
                                      onReturn: () {
                                        _fetchPlanId(selectedDate);
                                        _fetchInlineRecallItems(selectedDate);
                                      },
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 14),

                            _buildOptionCard(
                              emoji: '✏️',
                              text: 'No, I changed something',
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => LogMealScreen(
                                      tab: true,
                                      planId: planId,
                                      didEatPlanned: false,
                                      onReturn: () {
                                        _fetchPlanId(selectedDate);
                                        _fetchInlineRecallItems(selectedDate);
                                      },
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
                            Row(
                              children: [
                                const Text(
                                  "Logged Meals ",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1F2937),
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE8F7F1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    "${recallItems.length} Items",
                                    style: const TextStyle(
                                      color: Color(0xFF008C5E),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            _isLoadingLoggedItems
                                ? const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 20),
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        color: Color(0xFF008C5E),
                                      ),
                                    ),
                                  )
                                : _buildInlineLoggedMealsList(),
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

  Widget _buildInlineLoggedMealsList() {
    if (recallItems.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Colors.grey.shade50],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF008C5E).withOpacity(0.06),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.restaurant_outlined,
                size: 40,
                color: Color(0xFF008C5E),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "Your plate is empty for this date",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Logged meals will appear here to track your daily progress.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    final List<dynamic> sortedItems = List.from(recallItems);
    const mealOrder = {
      'breakfast': 0,
      'lunch': 1,
      'dinner': 2,
      'snacks': 3,
      'snack': 3,
    };

    sortedItems.sort((a, b) {
      final slotA = (a['meal_slot'] ?? "").toString().toLowerCase();
      final slotB = (b['meal_slot'] ?? "").toString().toLowerCase();
      final orderA = mealOrder[slotA] ?? 4;
      final orderB = mealOrder[slotB] ?? 4;
      return orderA.compareTo(orderB);
    });

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sortedItems.length,
      itemBuilder: (context, index) {
        final item = sortedItems[index];
        final bool planned = item['did_eat_as_planned'] == true;
        final mealSlot = (item['meal_slot'] ?? "").toString();
        final isLastItem = index == sortedItems.length - 1;

        Color themeColor;
        IconData mealIcon;
        switch (mealSlot.toLowerCase()) {
          case 'breakfast':
            themeColor = const Color(0xFFF59E0B);
            mealIcon = Icons.wb_sunny_outlined;
            break;
          case 'lunch':
            themeColor = const Color(0xFF3B82F6);
            mealIcon = Icons.wb_twilight_outlined;
            break;
          case 'dinner':
            themeColor = const Color(0xFF8B5CF6);
            mealIcon = Icons.dark_mode_outlined;
            break;
          default: // Snacks or Custom inputs
            themeColor = const Color(0xFF10B981);
            mealIcon = Icons.local_pizza_outlined;
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 14),
                  height: 36,
                  width: 36,
                  decoration: BoxDecoration(
                    color: themeColor.withOpacity(0.12),
                    shape: BoxShape.circle,
                    border: Border.all(color: themeColor, width: 2),
                  ),
                  child: Icon(mealIcon, size: 16, color: themeColor),
                ),
                if (!isLastItem)
                  Container(
                    width: 2,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [themeColor, Colors.grey.shade200],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(width: 16),

            Expanded(
              child: Container(
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade100),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.015),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            mealSlot.toUpperCase(),
                            style: TextStyle(
                              color: themeColor,
                              fontWeight: FontWeight.w800,
                              fontSize: 11,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const Spacer(),
                          PopupMenuButton<String>(
                            icon: Icon(
                              Icons.more_horiz,
                              color: Colors.grey.shade400,
                              size: 20,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onSelected: (value) async {
                              if (value == 'edit') {
                                _showRecallEditBottomSheet(item);
                              } else if (value == 'delete') {
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text("Delete Logged Meal"),
                                    content: const Text(
                                      "Are you sure you want to remove this item?",
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: const Text("Cancel"),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        child: const Text(
                                          "Delete",
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirmed == true) {
                                  await _deleteRecall(item['id']);
                                }
                              }
                            },
                            itemBuilder: (context) => [
                              if (!planned)
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: ListTile(
                                    leading: Icon(
                                      Icons.edit_outlined,
                                      size: 18,
                                      color: Colors.blue,
                                    ),
                                    title: Text(
                                      'Edit details',
                                      style: TextStyle(fontSize: 14),
                                    ),
                                    contentPadding: EdgeInsets.zero,
                                    dense: true,
                                  ),
                                ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: ListTile(
                                  leading: Icon(
                                    Icons.delete_outline,
                                    size: 18,
                                    color: Colors.red,
                                  ),
                                  title: Text(
                                    'Remove item',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                  contentPadding: EdgeInsets.zero,
                                  dense: true,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),

                      Text(
                        item['food_name'] ?? "Unknown Food",
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 12),

                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildMicroChip(
                            icon: Icons.local_fire_department_rounded,
                            label: "${item['energy_kcal'] ?? 0} kcal",
                            bgColor: const Color(0xFFFFF7ED),
                            fgColor: const Color(0xFFEA580C),
                          ),
                          if (item['food_qty'] != null)
                            _buildMicroChip(
                              icon: Icons.scale_outlined,
                              label: "Qty ${item['food_qty']}",
                              bgColor: const Color(0xFFF0FDF4),
                              fgColor: const Color(0xFF16A34A),
                            ),
                          _buildMicroChip(
                            icon: planned ? Icons.task_alt : Icons.bolt,
                            label: planned ? "As Planned" : "Modified",
                            bgColor: planned
                                ? const Color(0xFFECFDF5)
                                : const Color(0xFFEFF6FF),
                            fgColor: planned
                                ? const Color(0xFF059669)
                                : const Color(0xFF2563EB),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMicroChip({
    required IconData icon,
    required String label,
    required Color bgColor,
    required Color fgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fgColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: fgColor,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
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
