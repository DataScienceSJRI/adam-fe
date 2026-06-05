import 'package:adam/bloc/plan_meal/plan_meal_bloc.dart';
import 'package:adam/data/models/plan_meal_model.dart';
import 'package:adam/data/repositories/diet_recall_repository.dart';
import 'package:adam/data/repositories/plan_meal_repository.dart';
import 'package:adam/ui/shared_widgets/custom_snackbar.dart';
import 'package:adam/ui/shared_widgets/shimmer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MealPlanScreen extends StatefulWidget {
  const MealPlanScreen({super.key});

  @override
  State<MealPlanScreen> createState() => MealPlanScreenState();
}

class MealPlanScreenState extends State<MealPlanScreen> {
  int selectedDay = 0;
  late DateTime selectedDate;
  final DietRecallRepository _dietRepo = DietRecallRepository();

  List<Map<String, dynamic>> days = [];
  late DateTime weekStartDate;
  final List<String> allMealSlots = ['breakfast', 'lunch', 'dinner', 'snacks'];

  List<dynamic> recallItems = [];
  final MealPlanRepository mealPlanRepository = MealPlanRepository();
  final now = DateTime.now();
  final formattedDate =
      "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}";
  Map<String, dynamic> mealReactions = {};
  String? currentPlanId;

  // @override
  // void initState() {
  //   super.initState();
  //   selectedDate = DateTime.now();
  //   _generateWeek(selectedDate);
  //   selectedDay = selectedDate.weekday - 1;
  //   final now = DateTime.now();
  //   days = List.generate(7, (index) {
  //     final date = now.add(Duration(days: index));
  //     _loadAllReactions();
  //     return {
  //       "day": _getDayLetter(date.weekday),
  //       "date": date.day.toString(),
  //       "fullDate": date,
  //     };
  //   });
  //
  //   // _fetchRecall();
  // }
  @override
  void initState() {
    super.initState();
    selectedDate = DateTime.now();

    _generateWeek(selectedDate);
    selectedDay = selectedDate.weekday - 1;

    _loadAllReactions();
  }

  Future<void> _loadAllReactions() async {
    for (final slot in allMealSlots) {
      await _fetchMealReaction(mealSlot: slot);
    }
  }

  Future<void> _fetchMealReaction({required String mealSlot}) async {
    if (currentPlanId == null) return;

    final response = await mealPlanRepository.getMealReaction(
      planId: currentPlanId!,
    );

    setState(() {
      mealReactions[mealSlot] = response;
    });
  }

  // Future<void> _fetchRecall() async {
  //   try {
  //     final now = DateTime.now();
  //
  //     final formattedDate =
  //         "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
  //
  //     final response = await _dietRepo.getRecall(date: formattedDate);
  //
  //     if (!mounted) return;
  //
  //     setState(() {
  //       recallItems = response['items'] ?? [];
  //     });
  //
  //     print("✅ RECALL ITEMS ===== $recallItems");
  //   } catch (e) {
  //     print("❌ RECALL ERROR ===== $e");
  //   }
  // }
  void _generateWeek(DateTime referenceDate) {
    final monday = referenceDate.subtract(
      Duration(days: referenceDate.weekday - 1),
    );

    weekStartDate = monday;

    days = List.generate(7, (index) {
      final date = monday.add(Duration(days: index));

      return {
        "day": _getDayLetter(date.weekday),
        "date": date.day.toString(),
        "fullDate": date,
      };
    });
  }

  bool _isMealLogged(String mealSlot) {
    return recallItems.any(
      (e) => e['meal_slot'].toString().toLowerCase() == mealSlot.toLowerCase(),
    );
  }

  String _getDayLetter(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return "M";

      case DateTime.tuesday:
        return "T";

      case DateTime.wednesday:
        return "W";

      case DateTime.thursday:
        return "T";

      case DateTime.friday:
        return "F";

      case DateTime.saturday:
        return "S";

      case DateTime.sunday:
        return "S";

      default:
        return "";
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          MealPlanBloc(repository: MealPlanRepository())
            ..add(FetchMealPlanEvent(date: formattedDate)),

      child: Scaffold(
        backgroundColor: const Color(0xFFF7F7F7),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          toolbarHeight: 60,
          automaticallyImplyLeading: false,
          centerTitle: true,
          title: Text(
            'MEAL PLAN',
            style: TextStyle(
              color: Color(0xFF006B52),
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(height: 1, color: const Color(0xFFDADADA)),
          ),
        ),

        body: BlocBuilder<MealPlanBloc, MealPlanState>(
          builder: (context, state) {
            if (state is MealPlanLoading) {
              return Center(child: Shimmer.list());
            }

            if (state is MealPlanFailure) {
              return Center(child: Text(state.message));
            }

            if (state is MealPlanLoaded) {
              final List<MealPlanModel> meals = state.meals;
              if (meals.isNotEmpty) {
                currentPlanId = meals.first.planId;
              }

              final breakfastMeals = meals
                  .where((e) => e.mealType.toLowerCase() == 'breakfast')
                  .toList();

              final lunchMeals = meals
                  .where((e) => e.mealType.toLowerCase() == 'lunch')
                  .toList();

              final dinnerMeals = meals
                  .where((e) => e.mealType.toLowerCase() == 'dinner')
                  .toList();

              final snacksMeals = meals
                  .where((e) => e.mealType.toLowerCase() == 'snacks')
                  .toList();

              return RefreshIndicator(
                color: const Color(0xFF007A50),
                onRefresh: () async {
                  final targetDateString =
                      "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";

                  BlocProvider.of<MealPlanBloc>(
                    context,
                  ).add(FetchMealPlanEvent(date: targetDateString));
                  await context.read<MealPlanBloc>().stream.firstWhere(
                    (state) =>
                        state is MealPlanLoaded || state is MealPlanFailure,
                  );
                },
                child: SingleChildScrollView(
                  physics: AlwaysScrollableScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              _getMonthName(DateTime.now().month),
                              style: const TextStyle(
                                fontSize: 15,
                                color: Colors.black87,
                              ),
                            ),

                            const Spacer(),

                            IconButton(
                              onPressed: () {
                                setState(() {
                                  weekStartDate = weekStartDate.subtract(
                                    const Duration(days: 7),
                                  );

                                  _generateWeek(weekStartDate);

                                  selectedDay = 0;
                                  selectedDate = days[0]['fullDate'];
                                });
                                final targetDateString =
                                    "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";

                                context.read<MealPlanBloc>().add(
                                  FetchMealPlanEvent(date: targetDateString),
                                );
                              },
                              icon: const Icon(Icons.chevron_left, size: 20),
                            ),

                            IconButton(
                              onPressed: () {
                                setState(() {
                                  weekStartDate = weekStartDate.add(
                                    const Duration(days: 7),
                                  );

                                  _generateWeek(weekStartDate);

                                  selectedDay = 0;
                                  selectedDate = days[0]['fullDate'];
                                });
                                final targetDateString =
                                    "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";

                                context.read<MealPlanBloc>().add(
                                  FetchMealPlanEvent(date: targetDateString),
                                );
                              },
                              icon: const Icon(Icons.chevron_right, size: 20),
                            ),
                          ],
                        ),

                        const SizedBox(height: 6),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(days.length, (index) {
                            final item = days[index];

                            final isSelected = selectedDay == index;

                            return GestureDetector(
                              onTap: () {
                                final clickedDate =
                                    item['fullDate'] as DateTime;

                                final targetDateString =
                                    "${clickedDate.year}-${clickedDate.month.toString().padLeft(2, '0')}-${clickedDate.day.toString().padLeft(2, '0')}";

                                setState(() {
                                  selectedDay = index;
                                  selectedDate = clickedDate;
                                });

                                BlocProvider.of<MealPlanBloc>(context).add(
                                  FetchMealPlanEvent(date: targetDateString),
                                );
                              },
                              child: Container(
                                width: 38,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFFDDF4EB)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                  border: isSelected
                                      ? Border.all(
                                          color: const Color(0xFF008C5E),
                                        )
                                      : null,
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      item['day'],
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.black54,
                                      ),
                                    ),

                                    const SizedBox(height: 6),

                                    Text(
                                      item['date'],
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: isSelected
                                            ? const Color(0xFF008C5E)
                                            : Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ),

                        const SizedBox(height: 20),
                        if (meals.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              vertical: 50,
                              horizontal: 20,
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.no_meals_outlined,
                                  size: 70,
                                  color: Colors.grey.shade400,
                                ),

                                const SizedBox(height: 16),

                                const Text(
                                  "No meal plan found",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),

                                const SizedBox(height: 8),

                                Text(
                                  "No meals are available for the selected day.",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else ...[
                          // BREAKFAST
                          if (breakfastMeals.isNotEmpty)
                            _buildMealSection(
                              context,
                              title: "Breakfast",
                              mealSlot: "breakfast",
                              meals: breakfastMeals,
                              icon: Icons.breakfast_dining,
                              iconColor: Colors.green,
                            ),

                          const SizedBox(height: 16),

                          // LUNCH
                          if (lunchMeals.isNotEmpty)
                            _buildMealSection(
                              context,
                              title: "Lunch",
                              mealSlot: "lunch",
                              meals: lunchMeals,
                              icon: Icons.lunch_dining,
                              iconColor: Colors.orange,
                            ),

                          const SizedBox(height: 16),

                          // DINNER
                          if (dinnerMeals.isNotEmpty)
                            _buildMealSection(
                              context,
                              title: "Dinner",
                              mealSlot: "dinner",
                              meals: dinnerMeals,
                              icon: Icons.dinner_dining,
                              iconColor: Colors.blue,
                            ),

                          const SizedBox(height: 16),

                          // SNACK
                          if (snacksMeals.isNotEmpty)
                            _buildMealSection(
                              context,
                              title: "Snacks",
                              mealSlot: "snacks",
                              meals: snacksMeals,
                              icon: Icons.fastfood,
                              iconColor: Colors.red,
                            ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            }

            return const SizedBox();
          },
        ),
      ),
    );
  }

  Widget _buildMealSection(
    BuildContext context, {
    required String title,
    required String mealSlot,
    required List<MealPlanModel> meals,
    required IconData icon,
    required Color iconColor,
  }) {
    final isLogged = _isMealLogged(mealSlot);

    return _mealCard(
      context,
      context,
      mealTitle: title,
      time: meals.first.mealTime,
      meals: meals,
      icon: icon,
      iconColor: iconColor,
      child: Column(
        children: [
          ...meals.map((meal) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GestureDetector(
                onLongPress: () async {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) => Center(
                      child: CircularProgressIndicator(
                        color: const Color(0xFF007A50),
                      ),
                    ),
                  );

                  try {
                    final now = DateTime.now();

                    final formattedDate =
                        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

                    final response = await MealPlanRepository()
                        .getPlanReplacement(
                          date: formattedDate,
                          day: "1",
                          mealSlot: mealSlot,
                          recipeCode: meal.recipeCode,
                        );

                    if (context.mounted) {
                      Navigator.pop(context); // close loader
                    }

                    final replacements = response['alternatives'] ?? [];

                    showSwapFoodBottomSheet(
                      context,
                      currentMeal: meal,
                      alternatives: replacements,
                    );
                  } catch (e) {
                    if (context.mounted) {
                      Navigator.pop(context); // close loader
                      AppSnackBar.show(
                        context,
                        message: "Failed to fetch alternatives",
                        type: SnackBarType.error,
                      );
                      // ScaffoldMessenger.of(context).showSnackBar(
                      //   const SnackBar(
                      //     content: Text("Failed to fetch alternatives"),
                      //   ),
                      // );
                    }
                  }
                },
                child: _foodItem(
                  context,
                  mealTitle: meal.mealType,
                  recipeCode: meals
                      .map((e) => e.recipeCode.toString())
                      .toList(),
                  planId: meals.isNotEmpty ? meals.first.planId.toString() : "",
                  image: meal.imageUrl,
                  title: meal.foodName,
                  subtitle:
                      '${meal.quantity} • ${meal.calories.toStringAsFixed(0)} kcal',
                  reaction: meal.reaction,
                ),
              ),
            );
          }),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      '',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return months[month];
  }

  Widget _mealCard(
    BuildContext context,
    BuildContext parentContext, {
    required String mealTitle,
    required String time,
    required IconData icon,
    required Color iconColor,
    required List<MealPlanModel> meals,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E2E2)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              children: [
                Icon(icon, size: 18, color: iconColor),

                const SizedBox(width: 8),

                Text(
                  mealTitle,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const Spacer(),

                // LIKE BUTTON
                GestureDetector(
                  onTap: () async {
                    final targetDateString =
                        "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";

                    print("👎 likes $mealTitle");

                    await MealPlanRepository().sendMealReaction(
                      date: formattedDate,
                      mealSlot: mealTitle.toLowerCase(),
                      planId: meals.isNotEmpty
                          ? meals.first.planId.toString()
                          : "",
                      reaction: "like",
                      recipeCodes: meals
                          .map((e) => e.recipeCode.toString())
                          .toList(),
                    );
                    _fetchMealReaction(mealSlot: mealTitle);
                    AppSnackBar.show(
                      context,
                      message: '$mealTitle liked',
                      type: SnackBarType.success,
                    );
                    BlocProvider.of<MealPlanBloc>(
                      parentContext,
                    ).add(FetchMealPlanEvent(date: targetDateString));
                  },
                  child: Icon(
                    Icons.thumb_up_alt_outlined,
                    size: 18,
                    color:
                        (meals.isNotEmpty &&
                            meals.first.comboReaction == "like")
                        ? Colors.red
                        : Colors.black54,
                    // color: Colors.black54,
                  ),
                ),

                const SizedBox(width: 12),

                GestureDetector(
                  onTap: () async {
                    final targetDateString =
                        "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";

                    print("👎 Disliked $mealTitle");

                    await MealPlanRepository().sendMealReaction(
                      date: formattedDate,
                      mealSlot: mealTitle.toLowerCase(),
                      planId: meals.isNotEmpty
                          ? meals.first.planId.toString()
                          : "",
                      reaction: "dislike",
                      recipeCodes: meals
                          .map((e) => e.recipeCode.toString())
                          .toList(),
                    );
                    _fetchMealReaction(mealSlot: mealTitle);
                    AppSnackBar.show(
                      context,
                      message: '$mealTitle disliked',
                      type: SnackBarType.error,
                    );
                    BlocProvider.of<MealPlanBloc>(
                      parentContext,
                    ).add(FetchMealPlanEvent(date: targetDateString));
                  },
                  child: Icon(
                    Icons.thumb_down_alt_outlined,
                    size: 18,
                    color:
                        (meals.isNotEmpty &&
                            meals.first.comboReaction == "dislike")
                        ? Colors.green
                        : Colors.black54,
                  ),
                ),

                const SizedBox(width: 14),

                Text(
                  time,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _foodItem(
    BuildContext parentContext, {
    required String image,
    required String title,
    required String subtitle,
    required String mealTitle,
    required String planId,
    required List<String> recipeCode,
    required String? reaction,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F6F6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // IMAGE
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              image,
              width: 44,
              height: 44,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 44,
                height: 44,
                color: Colors.grey.shade300,
                child: const Icon(Icons.fastfood),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // TITLE + SUBTITLE
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),

          // LIKE / DISLIKE
          Row(
            children: [
              GestureDetector(
                onTap: () async {
                  final targetDateString =
                      "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";

                  print("👎 likes $mealTitle");

                  await MealPlanRepository().sendMealReaction(
                    date: formattedDate,
                    mealSlot: mealTitle.toLowerCase(),
                    planId: planId,
                    reaction: "like",
                    recipeCodes: recipeCode,
                  );
                  _fetchMealReaction(mealSlot: mealTitle);
                  AppSnackBar.show(
                    context,
                    message: '$mealTitle liked',
                    type: SnackBarType.success,
                  );
                  BlocProvider.of<MealPlanBloc>(
                    parentContext,
                  ).add(FetchMealPlanEvent(date: targetDateString));
                  // ScaffoldMessenger.of(
                  //   context,
                  // ).showSnackBar(SnackBar(content: Text('$mealTitle Liked')));
                },
                child: Icon(
                  Icons.thumb_up_alt_outlined,
                  size: 18,
                  color: (reaction == "like") ? Colors.red : Colors.black54,
                ),
              ),

              const SizedBox(width: 12),

              GestureDetector(
                onTap: () async {
                  final targetDateString =
                      "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";

                  print("👎 Disliked $mealTitle");

                  await MealPlanRepository().sendMealReaction(
                    date: formattedDate,
                    mealSlot: mealTitle.toLowerCase(),
                    planId: planId,
                    reaction: "dislike",
                    recipeCodes: recipeCode,
                  );
                  _fetchMealReaction(mealSlot: mealTitle);
                  AppSnackBar.show(
                    context,
                    message: '$mealTitle Disliked',
                    type: SnackBarType.error,
                  );
                  BlocProvider.of<MealPlanBloc>(
                    parentContext,
                  ).add(FetchMealPlanEvent(date: targetDateString));
                },
                child: Icon(
                  Icons.thumb_down_alt_outlined,
                  size: 18,
                  color: (reaction == "dislike")
                      ? Colors.green
                      : Colors.black54,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void showSwapFoodBottomSheet(
    BuildContext parentContext, {
    required MealPlanModel currentMeal,
    required List<dynamic> alternatives,
  }) {
    if (context == null) return;

    int selectedIndex = -1;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.82,
              decoration: const BoxDecoration(
                color: Color(0xFFF7F7F7),
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 10),

                  Container(
                    width: 46,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),

                  const SizedBox(height: 16),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        const Text(
                          'Swap food item',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        const Spacer(),

                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "CURRENTLY PLANNED",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.black54,
                            ),
                          ),

                          const SizedBox(height: 12),

                          _foodTile(
                            image: currentMeal.imageUrl,
                            title: currentMeal.foodName,
                            kcal:
                                "${currentMeal.calories.toStringAsFixed(0)} kcal",
                            tag: currentMeal.quantity.toString(),
                            selected: false,
                          ),

                          const SizedBox(height: 24),

                          const Text(
                            "CHOOSE AN ALTERNATIVE",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.black54,
                            ),
                          ),

                          const SizedBox(height: 16),

                          ...alternatives.asMap().entries.map((entry) {
                            final index = entry.key;

                            final group = entry.value;

                            final item = group[0];

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: GestureDetector(
                                onTap: () {
                                  setModalState(() {
                                    selectedIndex = index;
                                  });
                                },
                                child: _foodTile(
                                  image:
                                      'https://datatools.sjri.res.in/static/VD/food_images_large/${item['recipe_code']}.jpg',
                                  title: item['recipe_name'] ?? '',
                                  kcal: "${item['quantity']} ${item['unit']}",
                                  tag: item['recipe_code'],
                                  selected: selectedIndex == index,
                                ),
                              ),
                            );
                          }).toList(),

                          const SizedBox(height: 120),
                        ],
                      ),
                    ),
                  ),

                  Container(
                    padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(18),
                      ),
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: selectedIndex == -1
                            ? null
                            : () async {
                                try {
                                  final selectedItem =
                                      alternatives[selectedIndex][0];
                                  final targetDateString =
                                      "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";

                                  final now = DateTime.now();

                                  final formattedDate =
                                      "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

                                  final response = await MealPlanRepository()
                                      .sendSwapRequest(
                                        date: formattedDate,
                                        mealSlot: currentMeal.mealType
                                            .toLowerCase(),
                                        recipeCodes: [
                                          selectedItem['recipe_code'],
                                        ],
                                        orignalRecipeCodes: [
                                          currentMeal.recipeCode ?? "",
                                        ],
                                      );

                                  print(
                                    "✅ FINAL SWAP RESPONSE ===== $response",
                                  );
                                  final isPossible =
                                      response['possible'] ?? false;

                                  if (isPossible) {
                                    if (!mounted) return;
                                    Navigator.pop(context);
                                    AppSnackBar.show(
                                      context,
                                      message: "Swap request sent successfully",
                                      type: SnackBarType.success,
                                    );
                                    BlocProvider.of<MealPlanBloc>(
                                      parentContext,
                                    ).add(
                                      FetchMealPlanEvent(
                                        date: targetDateString,
                                      ),
                                    );
                                  } else {
                                    Navigator.pop(context);
                                    AppSnackBar.show(
                                      context,
                                      message: "Not able to swap this item",
                                      type: SnackBarType.error,
                                    );
                                  }
                                } catch (e) {
                                  print("❌ SEND SWAP ERROR ===== $e");

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(e.toString())),
                                  );
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF007A50),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Send swap request',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _foodTile({
    required String image,
    required String title,
    required String kcal,
    required String tag,
    required bool selected,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFDDF1EA) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selected ? const Color(0xFF007A50) : const Color(0xFFD6D6D6),
        ),
      ),
      child: Row(
        children: [
          // ================= IMAGE =================
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              image,
              width: 54,
              height: 54,
              fit: BoxFit.cover,
            ),
          ),

          const SizedBox(width: 12),

          // ================= TEXT =================
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 6),

                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        kcal,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),
                  ],
                ),
              ],
            ),
          ),

          // ================= SELECT =================
          if (selected)
            const CircleAvatar(
              radius: 11,
              backgroundColor: Color(0xFF007A50),
              child: Icon(Icons.check, size: 14, color: Colors.white),
            ),
        ],
      ),
    );
  }
}
