import 'package:adam/core/constants/api_endpoints.dart';
import 'package:adam/data/models/preference_model.dart';
import 'package:adam/ui/screens/dashboard/dashboard_wrapper.dart';
import 'package:adam/ui/screens/preference/progress_bar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'food_tile.dart';

class PreferenceScreen extends StatefulWidget {
  const PreferenceScreen({super.key});

  @override
  State<PreferenceScreen> createState() => _PreferenceScreenState();
}

class _PreferenceScreenState extends State<PreferenceScreen> {
  int currentStep = 1;
  final int totalSteps = 7;
  bool _isLoading = false;
  final List<PreferenceModel> breakfastOptions = [];
  final List<PreferenceModel> lunchOptions = [];
  final List<PreferenceModel> dinnerOptions = [];
  final List<PreferenceModel> snackOptions = [];
  String? selectedDietaryIds;
  final Set<String> selectedDietaryRestrictionIds = {};
  final Set<String> selectedBreakfastIds = {};
  final Set<String> selectedLunchIds = {};
  final Set<String> selectedDinnerIds = {};
  final Set<String> selectedSnackIds = {};
  bool showClock = false;
  late final SupabaseClient _supabase;
  final ScrollController _scrollController = ScrollController();
  int selectedHour = 8;
  int selectedMinute = 0;
  String selectedPeriod = 'AM';
  TimeOfDay? breakfastTime;
  TimeOfDay? lunchTime;
  TimeOfDay? dinnerTime;
  int tempHour = 8;
  int tempMinute = 0;
  bool tempIsAm = true;
  bool takeThirdSideLunch = false;
  bool takeBeverage = false;
  bool takeLunchSide = false;
  bool takeDinnerSide = false;
  Set<String> selectedBeverageIds = {};
  Set<String> selectedLunchSideIds = {};
  Set<String> selectedDinnerSideIds = {};
  final List<PreferenceModel> beverageOptions = [];
  final List<PreferenceModel> sideDishLunchOptions = [];
  final List<PreferenceModel> sideDishDinnerOptions = [];
  bool snackEnabled = false;
  bool isSnackLoading = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final Map<String, double> _activityMinutes = {};
  final Map<String, Set<int>> _selectedDays = {};
  bool isActivityLoading = false;
  String? selectedActivityLevel;
  String? selectedGender;
  final List<PreferenceModel> dietaryOptions = [
    PreferenceModel(id: 'Veg', title: 'Vegetarian', icon: Icons.eco),
    PreferenceModel(id: 'Non Veg', title: 'Non-Veg', icon: Icons.set_meal),
    PreferenceModel(id: 'Eggtarian', title: 'Eggtarian', icon: Icons.egg),
    PreferenceModel(id: 'Vegan', title: 'Vegan', icon: Icons.grass),
    PreferenceModel(
      id: 'Gluten Free',
      title: 'Gluten Free',
      icon: Icons.no_food,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _supabase = Supabase.instance.client;

    _initializeApp();
  }

  Future<void> _initializeApp() async {
    setState(() => _isLoading = true);

    await recipeList();

    await _loadExistingData();
    await _loadMeals();

    setState(() => _isLoading = false);
  }

  void _clearSearch() {
    _searchController.clear();
    _searchQuery = '';
  }

  Future<void> _loadMeals() async {
    try {
      final email = _supabase.auth.currentUser?.email ?? '';
      final userId = email.split('@').first.toUpperCase();

      final response = await _supabase
          .from('BE_Preference_onboarding')
          .select()
          .eq('user_id', userId);

      PreferenceModel? findItem(List<PreferenceModel> options, String val) {
        return options.where((e) => e.code == val || e.id == val).firstOrNull;
      }

      for (var row in response) {
        final mealTime = row['meal_time'];
        final dishType = row['dish_type'];
        final val = row['sub_category'];

        if (mealTime == "Breakfast" && dishType == "Main") {
          final item = findItem(breakfastOptions, val);
          if (item != null) selectedBreakfastIds.add(item.id);
        } else if (mealTime == "Breakfast" && dishType == "Beverage") {
          final item = findItem(beverageOptions, val);
          if (item != null) {
            selectedBeverageIds.add(item.id);
            takeBeverage = true;
          }
        } else if (mealTime == "Lunch" && dishType == "Main") {
          final item = findItem(lunchOptions, val);
          if (item != null) selectedLunchIds.add(item.id);
        } else if (mealTime == "Lunch" && dishType == "Side") {
          final item = findItem(sideDishLunchOptions, val);
          if (item != null) {
            selectedLunchSideIds.add(item.id);
            takeLunchSide = true;
          }
        } else if (mealTime == "Dinner" && dishType == "Main") {
          final item = findItem(dinnerOptions, val);
          if (item != null) selectedDinnerIds.add(item.id);
        } else if (mealTime == "Dinner" && dishType == "Side") {
          final item = findItem(sideDishDinnerOptions, val);
          if (item != null) {
            selectedDinnerSideIds.add(item.id);
            takeDinnerSide = true;
          }
        } else if (mealTime == "Snacks") {
          final item = findItem(snackOptions, val);
          if (item != null) {
            selectedSnackIds.add(item.id);
            snackEnabled = true;
          }
        }
      }

      print("✅ Load complete. Breakfast IDs: $selectedBreakfastIds");
      setState(() {});
    } catch (e) {
      print("❌ _loadMeals Error: $e");
    }
  }

  Future<void> _loadExistingData() async {
    try {
      final email = _supabase.auth.currentUser?.email ?? '';

      final userId = email.split('@').first.toUpperCase();
      print("the user id is ${userId}");
      if (userId == null) return;

      final response = await _supabase
          .from('BE_Preference_onboarding_details')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(1);

      if (response.isEmpty) return;

      final data = response.first;

      print("🔥 FULL DATA: $data");
      print("🔥 RAW diet_restrictions: ${data['diet_restrictions']}");
      print("🔥 TYPE: ${data['diet_restrictions'].runtimeType}");

      selectedDietaryIds = data['dietary_type'];
      print("🔥 DIETARY TYPE: $selectedDietaryIds");

      final raw = data['diet_restrictions'];
      selectedDietaryRestrictionIds.clear();

      if (raw != null && raw.toString().trim().isNotEmpty) {
        selectedDietaryRestrictionIds.addAll(
          raw.toString().split(',').map((e) => e.trim()),
        );
      }

      if (data['breakfast_time'] != null) {
        final dt = DateTime.parse(data['breakfast_time']);
        breakfastTime = TimeOfDay(hour: dt.hour, minute: dt.minute);
      }

      if (data['lunch_time'] != null) {
        final dt = DateTime.parse(data['lunch_time']);
        lunchTime = TimeOfDay(hour: dt.hour, minute: dt.minute);
      }

      if (data['dinner_time'] != null) {
        final dt = DateTime.parse(data['dinner_time']);
        dinnerTime = TimeOfDay(hour: dt.hour, minute: dt.minute);
      }

      setState(() {});

      print(
        "✅ breakfastTime: $breakfastTime, lunchTime: $lunchTime, dinnerTime: $dinnerTime",
      );
    } catch (e) {
      debugPrint("❌ Load error: $e");
    }
  }

  Future<void> recipeList() async {
    setState(() => _isLoading = true);
    try {
      final response = await _supabase
          .from('SubCategory_Onboarding')
          .select(
            'SubCategory, Breakfast, Lunch, Dinner, Snacks ,Beverage, Side_dish_lunch, Side_dish_dinner, Code',
          );

      breakfastOptions.clear();
      lunchOptions.clear();
      dinnerOptions.clear();
      snackOptions.clear();
      beverageOptions.clear();
      sideDishLunchOptions.clear();
      sideDishDinnerOptions.clear();

      bool isOne(dynamic value) {
        if (value == null) return false;
        return value.toString() == '1';
      }

      for (var item in response) {
        final model = PreferenceModel(
          id: item['SubCategory'].toString(),
          title: item['SubCategory'].toString(),
          code: item['Code'].toString(),
        );

        if (isOne(item['Breakfast'])) breakfastOptions.add(model);
        if (isOne(item['Lunch'])) lunchOptions.add(model);
        if (isOne(item['Dinner'])) dinnerOptions.add(model);
        if (isOne(item['Snacks'])) snackOptions.add(model);
        if (isOne(item['Beverage'])) beverageOptions.add(model);
        if (isOne(item['Side_dish_lunch'])) sideDishLunchOptions.add(model);
        if (isOne(item['Side_dish_dinner'])) sideDishDinnerOptions.add(model);
      }
      print("Breakfast options count: ${breakfastOptions.length}");

      for (final item in breakfastOptions.take(5)) {
        print("OPTION => id=${item.id}, code=${item.code}");
      }
    } catch (e) {
      debugPrint("Supabase error: $e");
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffE8F5E9),
      appBar: AppBar(title: const Text("Meal Preferences"), centerTitle: true),
      body: SafeArea(
        child: Column(
          children: [
            ProgressStoryBar(current: currentStep, total: totalSteps),
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                child: _buildStep(),
              ),
            ),
            FooterNav(
              currentStep: currentStep,
              totalSteps: totalSteps,
              onNext: () async {
                if (currentStep == totalSteps) {
                  await _next();
                  _showSnackSuccessDialog(context);
                } else {
                  await _next();
                }
              },
              onBack: _back,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> saveActivities() async {
    final userId = _supabase.auth.currentUser!.email;

    const dayMap = {
      1: "Mon",
      2: "Tue",
      3: "Wed",
      4: "Thu",
      5: "Fri",
      6: "Sat",
      7: "Sun",
    };

    List<Map<String, dynamic>> rows = [];

    _activityMinutes.forEach((activity, minutes) {
      final days = _selectedDays[activity] ?? {};

      if (minutes > 0 && days.isNotEmpty) {
        final dayNames = days.map((d) => dayMap[d] ?? '').join(', ');

        rows.add({
          "user_id": userId,
          "activity": activity,
          "minutes": minutes.toInt(),
          "days": dayNames,
          "created_at": DateTime.now().toIso8601String(),
        });
      }
    });

    try {
      await _supabase
          .from('user_physical_activities')
          .delete()
          .eq('user_id', userId!);

      if (rows.isNotEmpty) {
        await _supabase.from('user_physical_activities').insert(rows);
      }

      debugPrint("✅ Activities replaced successfully");
    } catch (e) {
      debugPrint("❌ Activity save error: $e");
    }
  }

  void _showSnackSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 20,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: Colors.green.shade100,
                child: Icon(
                  Icons.check_rounded,
                  size: 40,
                  color: Colors.green.shade700,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "You're All Set 🎉",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                "Your meal preferences have been saved successfully.\nLet’s start your healthy journey!",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 45,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => MainScreenWrapper()),
                    );
                  },
                  child: const Text(
                    "Let’s Eat 🍽",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStep() {
    switch (currentStep) {
      case 1:
        return _mealStep(
          title: 'Breakfast',
          subtitle: 'What do you usually eat? (Select min 3)',
          options: breakfastOptions,
          selectedIds: selectedBreakfastIds,
        );
      case 2:
        return _sideDishSection(
          title: "Beverage",
          options: beverageOptions,
          selectedIds: selectedBeverageIds,
          switchValue: takeBeverage,
          onSwitchChanged: (v) {
            setState(() {
              takeBeverage = v;
              if (!v) selectedBeverageIds.clear();
            });
          },
        );

      case 3:
        return _mealStep(
          title: 'Lunch',
          subtitle: 'Your mid-day fuel.',
          options: lunchOptions,
          selectedIds: selectedLunchIds,
        );

      case 4:
        return _sideDishSection(
          title: "Lunch",
          options: sideDishLunchOptions,
          selectedIds: selectedLunchSideIds,
          switchValue: takeLunchSide,
          onSwitchChanged: (v) {
            setState(() {
              takeLunchSide = v;
              if (!v) selectedLunchSideIds.clear();
            });
          },
        );

      case 5:
        return _mealStep(
          title: 'Dinner',
          subtitle: 'Wrapping up the day.',
          options: dinnerOptions,
          selectedIds: selectedDinnerIds,
        );
      case 6:
        return _sideDishSection(
          title: "Dinner",
          options: sideDishDinnerOptions,
          selectedIds: selectedDinnerSideIds,
          switchValue: takeDinnerSide,
          onSwitchChanged: (v) {
            setState(() {
              takeDinnerSide = v;
              if (!v) selectedDinnerSideIds.clear();
            });
          },
        );

      case 7:
        return _mealStep(
          title: 'Snacks',
          subtitle: 'Be honest, we all do it!',
          options: snackOptions,
          selectedIds: selectedSnackIds,
        );
      default:
        return const SizedBox();
    }
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    required Color primary,
    required Color primaryLight,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: primary),
      prefixIcon: Icon(icon, color: primary),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primaryLight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primary, width: 2),
      ),
    );
  }

  Widget _mealStep({
    required String title,
    required String subtitle,
    required List<PreferenceModel> options,
    required Set<String> selectedIds,
  }) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // TimeOfDay? selectedTime;
    // if (title == 'Breakfast') selectedTime = breakfastTime;
    // if (title == 'Lunch') selectedTime = lunchTime;
    // if (title == 'Dinner') selectedTime = dinnerTime;
    final filtered = _filteredOptions(options);
    for (final item in breakfastOptions.take(10)) {
      print("${item.id} -> ${selectedBreakfastIds.contains(item.id)}");
    }

    return StepWrapper(
      title: title,
      subtitle: subtitle,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          children: [
            if (title == 'Snacks')
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xffEAFBE3).withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Do you snack between meals?',
                      style: TextStyle(
                        color: Theme.of(context).primaryColorDark,
                      ),
                    ),
                    Theme(
                      data: Theme.of(context).copyWith(
                        switchTheme: SwitchThemeData(
                          trackOutlineColor: MaterialStateProperty.all(
                            Colors.transparent,
                          ),
                          trackOutlineWidth: MaterialStateProperty.all(0),
                        ),
                      ),
                      child: Switch(
                        value: snackEnabled,
                        activeColor: Theme.of(context).primaryColorDark,
                        inactiveThumbColor: Colors.grey.shade400,
                        inactiveTrackColor: Colors.grey.shade300,
                        onChanged: (v) {
                          setState(() => snackEnabled = v);
                          if (!v) selectedSnackIds.clear();
                        },
                      ),
                    ),
                  ],
                ),
              ),
            if (title != 'Snacks' || snackEnabled) _buildSearchBar(),
            if (title != 'Snacks' || snackEnabled)
              filtered.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.only(top: 20),
                      child: Center(child: Text("No items found")),
                    )
                  : GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: filtered
                          .map((e) => _tile(e, selectedIds))
                          .toList(),
                    ),
          ],
        ),
      ),
    );
  }

  Future<void> _showFloatingTimePicker(
    BuildContext context,
    String title,
  ) async {
    final primaryDark = Theme.of(context).primaryColorDark;

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      initialEntryMode: TimePickerEntryMode.dial,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: primaryDark,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
            timePickerTheme: TimePickerThemeData(
              backgroundColor: const Color(0xffEAEAEA),
              hourMinuteColor: primaryDark.withOpacity(0.15),
              hourMinuteTextColor: primaryDark,
              dayPeriodColor: primaryDark.withOpacity(0.15),
              dayPeriodTextColor: primaryDark,
              dialHandColor: primaryDark,
              dialBackgroundColor: Colors.white,
              entryModeIconColor: primaryDark,
              cancelButtonStyle: TextButton.styleFrom(
                foregroundColor: primaryDark,
              ),
              confirmButtonStyle: TextButton.styleFrom(
                foregroundColor: primaryDark,
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (title == 'Breakfast') breakfastTime = picked;
        if (title == 'Lunch') lunchTime = picked;
        if (title == 'Dinner') dinnerTime = picked;
      });
    }
  }

  Widget _customTimePicker() {
    return Container(
      height: 260,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xffEAEAEA),
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          _buildPicker(
            itemCount: 12,
            initialItem: selectedHour - 1,
            onChanged: (index) {
              setState(() => selectedHour = index + 1);
            },
            builder: (index) => '${index + 1}'.padLeft(2, '0'),
          ),
          _buildPicker(
            itemCount: 60,
            initialItem: selectedMinute,
            onChanged: (index) {
              setState(() => selectedMinute = index);
            },
            builder: (index) => index.toString().padLeft(2, '0'),
          ),
          _buildPicker(
            itemCount: 2,
            initialItem: selectedPeriod == 'AM' ? 0 : 1,
            onChanged: (index) {
              setState(() => selectedPeriod = index == 0 ? 'AM' : 'PM');
            },
            builder: (index) => index == 0 ? 'AM' : 'PM',
          ),
        ],
      ),
    );
  }

  Widget _buildPicker({
    required int itemCount,
    required int initialItem,
    required ValueChanged<int> onChanged,
    required String Function(int) builder,
  }) {
    return Expanded(
      child: CupertinoPicker(
        itemExtent: 42,
        scrollController: FixedExtentScrollController(initialItem: initialItem),
        onSelectedItemChanged: onChanged,
        selectionOverlay: Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(6)),
        ),
        children: List.generate(
          itemCount,
          (index) => Center(
            child: Text(
              builder(index),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sideDishSection({
    required String title,
    required List<PreferenceModel> options,
    required Set<String> selectedIds,
    required bool switchValue,
    required Function(bool) onSwitchChanged,
  }) {
    final filtered = _filteredOptions(options);

    return StepWrapper(
      title: title == "Beverage" ? "Beverage" : "$title Side Dish",
      subtitle: title == "Beverage"
          ? "Would you like to add a beverage?"
          : "Do you take a side dish with $title?",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xffEAFBE3).withOpacity(0.9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title == "Beverage" ? "Add Beverage?" : "Add Side Dish?",
                  style: TextStyle(
                    color: Theme.of(context).primaryColorDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Theme(
                  data: Theme.of(context).copyWith(
                    switchTheme: SwitchThemeData(
                      trackOutlineColor: MaterialStateProperty.all(
                        Colors.transparent,
                      ),
                      trackOutlineWidth: MaterialStateProperty.all(0),
                    ),
                  ),
                  child: Switch(
                    value: switchValue,
                    activeColor: Theme.of(context).primaryColorDark,
                    inactiveThumbColor: Colors.grey.shade400,
                    inactiveTrackColor: Colors.grey.shade300,
                    onChanged: onSwitchChanged,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (switchValue) _buildSearchBar(),
          if (switchValue)
            filtered.isEmpty
                ? const Padding(
                    padding: EdgeInsets.only(top: 20),
                    child: Center(child: Text("No items found")),
                  )
                : GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: filtered
                        .map((e) => _tile(e, selectedIds))
                        .toList(),
                  ),
        ],
      ),
    );
  }

  Widget _tile(PreferenceModel item, Set<String> selectedIds) {
    final imagePath =
        '${ApiEndpoints.preferenceOnboardingImage}${item.code}.jpg';
    return FoodTile(
      item: item,
      imageUrl: imagePath,
      isSelected: selectedIds.contains(item.id),
      onTap: () {
        selectedIds.contains(item.id)
            ? selectedIds.remove(item.id)
            : selectedIds.add(item.id);
        setState(() {});
      },
    );
  }

  void _scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  Future<void> _saveMealTime({
    String? column,
    required TimeOfDay time,
    required int step,
  }) async {
    final now = DateTime.now();
    final userId = _supabase.auth.currentUser!.email;

    final fullDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    await _supabase.from('BE_Preference_onboarding_details').upsert({
      'user_id': userId,
      column: fullDateTime.toIso8601String(),
      'step_count': step,
    }, onConflict: 'user_id');
  }

  Future<void> _saveMeal({
    required String mealTime,
    required String dishType,
    required Set<String> items,
  }) async {
    final email = _supabase.auth.currentUser?.email ?? '';
    final userId = email.split('@').first.toUpperCase();

    final allOptions = [
      ...breakfastOptions,
      ...lunchOptions,
      ...dinnerOptions,
      ...snackOptions,
      ...beverageOptions,
      ...sideDishLunchOptions,
      ...sideDishDinnerOptions,
    ];

    try {
      await _supabase
          .from('BE_Preference_onboarding')
          .delete()
          .eq('user_id', userId)
          .eq('meal_time', mealTime)
          .eq('dish_type', dishType);

      if (items.isNotEmpty) {
        final rows = items.map((id) {
          final option = allOptions.firstWhere((o) => o.id == id);
          print("this is the thing going ${option.code}");
          return {
            'user_id': userId,
            'meal_time': mealTime,
            'dish_type': dishType,
            'sub_category': option.code,
          };
        }).toList();

        await _supabase.from('BE_Preference_onboarding').insert(rows);
      }
    } catch (e) {
      debugPrint("❌ Meal save error: $e");
    }
  }

  Future<void> _next() async {
    final email = _supabase.auth.currentUser?.email ?? '';
    final userId = email.split('@').first.toUpperCase();
    switch (currentStep) {
      case 1:
        if (selectedBreakfastIds.length < 3) {
          _showError('Please select at least 3 breakfast items.');
          return;
        }

        await _saveMeal(
          mealTime: "Breakfast",
          dishType: "Main",
          items: selectedBreakfastIds,
        );
        break;

      case 2:
        await _saveMeal(
          mealTime: "Breakfast",
          dishType: "Beverage",
          items: selectedBeverageIds,
        );
        break;

      case 3:
        if (selectedLunchIds.isEmpty) {
          _showError('Please select at least 1');
          return;
        }

        await _saveMeal(
          mealTime: "Lunch",
          dishType: "Main",
          items: selectedLunchIds,
        );
        break;

      case 4:
        await _saveMeal(
          mealTime: "Lunch",
          dishType: "Side",
          items: selectedLunchSideIds,
        );
        break;

      case 5:
        if (selectedDinnerIds.isEmpty) {
          _showError('Please select at least 1');
          return;
        }

        await _saveMeal(
          mealTime: "Dinner",
          dishType: "Main",
          items: selectedDinnerIds,
        );
        break;

      case 6:
        await _saveMeal(
          mealTime: "Dinner",
          dishType: "Side",
          items: selectedDinnerSideIds,
        );
        break;

      case 7:
        await _supabase
            .from('BE_Preference_onboarding_details')
            .delete()
            .eq('user_id', userId);

        await _supabase.from('BE_Preference_onboarding_details').insert({
          'user_id': userId,
          'step_count': currentStep,
        });

        await _saveMeal(
          mealTime: "Snacks",
          dishType: "Snacks",
          items: selectedSnackIds,
        );
        break;
    }

    if (currentStep < totalSteps) {
      setState(() => currentStep++);
      _clearSearch();
      _scrollToTop();
    }
  }

  void _back() {
    if (currentStep > 1) {
      setState(() => currentStep--);
      _clearSearch();
      _scrollToTop();
    }
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() => _searchQuery = value.toLowerCase());
        },
        decoration: InputDecoration(
          hintText: "Search food...",
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  List<PreferenceModel> _filteredOptions(List<PreferenceModel> options) {
    if (_searchQuery.isEmpty) return options;

    return options
        .where((item) => item.title.toLowerCase().contains(_searchQuery))
        .toList();
  }

  Future<void> showWheelTimePicker({
    required BuildContext context,
    required TimeOfDay initialTime,
    required ValueChanged<TimeOfDay> onSelected,
  }) async {}
}
