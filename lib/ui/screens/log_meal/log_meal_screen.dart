import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:adam/data/models/plan_meal_model.dart';
import 'package:adam/data/models/recipe_model.dart';
import 'package:adam/data/repositories/diet_recall_repository.dart';
import 'package:adam/data/repositories/recipe_repository.dart';
import 'package:adam/ui/utils/custom_calendar.dart';
import 'package:adam/ui/utils/custom_snackbar.dart';
import 'package:adam/ui/utils/shimmer.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LogMealScreen extends StatefulWidget {
  const LogMealScreen({super.key, required this.tab, required this.planId});

  final bool tab;
  final String? planId;

  @override
  State<LogMealScreen> createState() => _LogMealScreenState();
}

class _LogMealScreenState extends State<LogMealScreen> {
  late bool isImageSelected;
  final DietRecallRepository _dietRecallRepository = DietRecallRepository();
  final TextEditingController quantityController = TextEditingController(
    text: "1",
  );
  Recipe? selectedRecipe;
  String selectedMealType = 'Breakfast';
  final List<String> mealTypes = ['Breakfast', 'Lunch', 'Dinner', 'Snacks'];
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  File? preMealImage;
  File? postMealImage;
  bool isCameraInitialized = false;
  final TextEditingController searchController = TextEditingController();
  final RecipeRepository _recipeRepository = RecipeRepository();
  List<Recipe> searchedRecipes = [];
  bool isSearching = false;
  Timer? _debounce;
  DateTime selectedDate = DateTime.now();
  List<MealPlanModel> selectedMeals = [];
  List<String> recipeUnits = [];
  bool isLoadingUnits = false;

  @override
  void initState() {
    super.initState();
    isImageSelected = widget.tab;
    savedMealPlan();
    _fetchRecall(selectedDate);
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    searchController.dispose();
    _debounce?.cancel();
    quantityController.dispose();
    super.dispose();
  }

  List<MealPlanModel> savedMeals = [];

  Future<void> savedMealPlan() async {
    final prefs = await SharedPreferences.getInstance();

    final mealPlanData = prefs.getString('meal_plan_data');

    if (mealPlanData != null) {
      final List decoded = jsonDecode(mealPlanData);

      savedMeals = decoded.map((e) => MealPlanModel.fromJson(e)).toList();
      print("===== SAVED MEALS =====");
      print("Total meals: ${savedMeals.length}");

      setState(() {});
    }
  }

  Future<List<String>> _fetchRecipeUnitValues(String recipeCode) async {
    try {
      final supabase = Supabase.instance.client;

      final data = await supabase
          .from('RecipeTagging')
          .select('Description')
          .eq('"Recipe_Code"', recipeCode)
          .single();

      final values = <String>[];

      void add(dynamic v) {
        final value = v?.toString().trim();
        if (value != null && value.isNotEmpty) values.add(value);
      }

      add(data['Variation1']);
      add(data['Variation2']);
      add(data['Variation3']);
      add(data['Description']);

      return values;
    } catch (e) {
      debugPrint('Error fetching recipe unit values: $e');
      return [];
    }
  }

  final DietRecallRepository _dietRepo = DietRecallRepository();
  List<dynamic> recallItems = [];

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

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();

      if (_cameras.isEmpty) {
        if (mounted) {
          AppSnackBar.show(
            context,
            message: "No Camera found on device",
            type: SnackBarType.error,
          );
        }
        return;
      }

      CameraDescription selectedCamera = _cameras.first;

      for (final camera in _cameras) {
        if (camera.lensDirection == CameraLensDirection.back) {
          selectedCamera = camera;
          break;
        }
      }

      _cameraController = CameraController(
        selectedCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _cameraController!.initialize();

      if (mounted) {
        setState(() {
          isCameraInitialized = true;
        });
      }
    } catch (e) {
      debugPrint("Camera Init Error: $e");

      if (mounted) {
        AppSnackBar.show(
          context,
          message: "Camera error: $e",
          type: SnackBarType.error,
        );
      }
    }
  }

  Future<void> _openCamera({required bool isPreMeal}) async {
    await _initializeCamera();
    if (_cameraController == null || !_cameraController!.value.isInitialized)
      return;
    if (!mounted) return;

    bool isUploading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.92,
                child: Column(
                  children: [
                    Expanded(child: CameraPreview(_cameraController!)),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: isUploading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : GestureDetector(
                              onTap: () async {
                                setSheetState(() => isUploading = true);
                                try {
                                  final image = await _cameraController!
                                      .takePicture();
                                  final file = File(image.path);

                                  final imageUrl = await _dietRecallRepository
                                      .uploadMealImage(
                                        file: file,
                                        mealSlot: selectedMealType,
                                        isPreMeal: isPreMeal,
                                      );

                                  await _dietRecallRepository.saveImageRecall(
                                    imageUrlPre: isPreMeal ? imageUrl : "",
                                    imageUrlPost: !isPreMeal ? imageUrl : null,
                                    mealSlot: selectedMealType.toLowerCase(),
                                    planId: widget.planId ?? "",
                                  );

                                  if (mounted) {
                                    setState(() {
                                      if (isPreMeal) {
                                        preMealImage = file;
                                      } else {
                                        postMealImage = file;
                                      }
                                    });
                                    AppSnackBar.show(
                                      context,
                                      message:
                                          "${selectedMealType} logged successfully",
                                      type: SnackBarType.success,
                                    );
                                    Navigator.pop(context);
                                  }
                                } catch (e) {
                                  setSheetState(() => isUploading = false);
                                }
                              },
                              child: Container(
                                height: 78,
                                width: 78,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 5,
                                  ),
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),

      appBar: AppBar(
        backgroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        title: const Text(
          'Log Meal',
          style: TextStyle(
            color: Color(0xFF0F5132),
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CustomCalendar(
              initialDate: selectedDate,
              onDateSelected: (date) {
                setState(() {
                  selectedDate = date;
                });
                _fetchRecall(date);
              },
            ),
            const SizedBox(height: 10),
            Container(
              height: 46,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFE7E7E7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  _buildToggleButton(
                    title: 'Image',
                    icon: Icons.image_outlined,
                    selected: isImageSelected,
                    onTap: () {
                      setState(() {
                        isImageSelected = true;
                      });
                    },
                  ),

                  _buildToggleButton(
                    title: 'Search & Choose',
                    icon: Icons.search,
                    selected: !isImageSelected,
                    onTap: () {
                      setState(() {
                        isImageSelected = false;
                      });
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 26),

            isImageSelected ? _buildImageUI() : _buildSearchChooseUI(),
            if (!isImageSelected)
              Align(
                alignment: Alignment.topRight,
                child: TextButton.icon(
                  onPressed: _showLoggedItems,
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF008C5E),
                  ),
                  icon: const Icon(Icons.history, color: Color(0xFF008C5E)),
                  label: const Text(
                    "Show Logged Items",
                    style: TextStyle(
                      color: Color(0xFF008C5E),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            if (!isImageSelected)
              Column(
                children: savedMeals.map((meal) {
                  final isSelected = selectedMeals.contains(meal);

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          selectedMeals.remove(meal);
                        } else {
                          selectedMeals.add(meal);
                        }
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFE8F7F1)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF008C5E)
                              : Colors.grey.shade200,
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.network(
                              'https://datatools.sjri.res.in/static/VD/food_images_large/${meal.recipeCode}.jpg',
                              height: 72,
                              width: 72,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                height: 72,
                                width: 72,
                                color: const Color(0xFFE7F5EF),
                                child: const Icon(
                                  Icons.fastfood,
                                  color: Color(0xFF008C5E),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(width: 14),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        meal.foodName,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 8),

                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE7F5EF),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    meal.mealType,
                                    style: const TextStyle(
                                      color: Color(0xFF008C5E),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 8),

                                Row(
                                  children: [
                                    const Icon(
                                      Icons.local_fire_department,
                                      size: 16,
                                      color: Colors.orange,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${meal.calories.toStringAsFixed(0)} kcal',
                                    ),

                                    const SizedBox(width: 14),

                                    const Icon(
                                      Icons.scale,
                                      size: 16,
                                      color: Colors.blueGrey,
                                    ),
                                    const SizedBox(width: 4),

                                    Text(
                                      '${meal.quantity} ${meal.quantityUnit}',
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () async {
                              _showEditMealBottomSheet(meal);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE7F5EF),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.edit_outlined,
                                size: 18,
                                color: Color(0xFF008C5E),
                              ),
                            ),
                          ),
                          SizedBox(width: 4),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            height: 28,
                            width: 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected
                                  ? const Color(0xFF008C5E)
                                  : Colors.transparent,
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF008C5E)
                                    : Colors.grey.shade400,
                                width: 2,
                              ),
                            ),
                            child: isSelected
                                ? const Icon(
                                    Icons.check,
                                    size: 18,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          color: Colors.white,
          child: _saveButton(isImageSelected),
        ),
      ),
    );
  }

  void _showLoggedItems() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),

              Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),

              const SizedBox(height: 18),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    const Text(
                      "Logged Meals",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
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
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              Expanded(
                child: recallItems.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(
                              Icons.restaurant_menu,
                              size: 70,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 12),
                            Text(
                              "No meals logged",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: recallItems.length,
                        itemBuilder: (context, index) {
                          final item = recallItems[index];

                          final bool planned =
                              item['did_eat_as_planned'] == true;

                          Color mealColor(String meal) {
                            switch (meal.toLowerCase()) {
                              case 'breakfast':
                                return Colors.orange;
                              case 'lunch':
                                return Colors.blue;
                              case 'dinner':
                                return Colors.purple;
                              default:
                                return Colors.green;
                            }
                          }

                          final mealSlot = (item['meal_slot'] ?? "").toString();

                          return Container(
                            margin: const EdgeInsets.only(bottom: 14),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: Colors.grey.shade200),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  height: 52,
                                  width: 52,
                                  decoration: BoxDecoration(
                                    color: planned
                                        ? Colors.green.shade50
                                        : Colors.orange.shade50,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Icon(
                                    planned
                                        ? Icons.check_circle
                                        : Icons.edit_note,
                                    color: planned
                                        ? Colors.green
                                        : Colors.orange,
                                  ),
                                ),

                                const SizedBox(width: 12),

                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item['food_name'] ?? "Unknown Food",
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),

                                      const SizedBox(height: 8),

                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 5,
                                            ),
                                            decoration: BoxDecoration(
                                              color: mealColor(
                                                mealSlot,
                                              ).withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              mealSlot.toUpperCase(),
                                              style: TextStyle(
                                                color: mealColor(mealSlot),
                                                fontWeight: FontWeight.w600,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ),

                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 5,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.orange.shade50,
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              "${item['energy_kcal'] ?? 0} kcal",
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),

                                          if (item['food_qty'] != null)
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 5,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.blue.shade50,
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              child: Text(
                                                "Qty ${item['food_qty']}",
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),

                                      const SizedBox(height: 10),

                                      Row(
                                        children: [
                                          Icon(
                                            planned
                                                ? Icons.task_alt
                                                : Icons.change_circle,
                                            size: 16,
                                            color: planned
                                                ? Colors.green
                                                : Colors.orange,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            planned ? "As Planned" : "Modified",
                                            style: TextStyle(
                                              color: planned
                                                  ? Colors.green
                                                  : Colors.orange,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEditMealBottomSheet(MealPlanModel meal) {
    final quantityController = TextEditingController(
      text: meal.quantity.toString(),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 12,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 45,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),

                const SizedBox(height: 20),

                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.network(
                        "https://datatools.sjri.res.in/static/VD/food_images_large/${meal.recipeCode}.jpg",
                        height: 70,
                        width: 70,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 70,
                          width: 70,
                          color: const Color(0xFFE7F5EF),
                          child: const Icon(
                            Icons.fastfood,
                            color: Color(0xFF008C5E),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 14),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            meal.foodName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),

                          const SizedBox(height: 6),

                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE7F5EF),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              meal.mealType,
                              style: const TextStyle(
                                color: Color(0xFF008C5E),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Quantity",
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF6F6F6),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFD7D7D7)),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          final current =
                              double.tryParse(quantityController.text) ?? 1;

                          if (current > 0.1) {
                            quantityController.text = (current - 0.1)
                                .toStringAsFixed(1);
                          }
                        },
                        icon: const Icon(Icons.remove_circle_outline),
                      ),

                      Expanded(
                        child: TextField(
                          controller: quantityController,
                          textAlign: TextAlign.center,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                          ),
                        ),
                      ),

                      IconButton(
                        onPressed: () {
                          final current =
                              double.tryParse(quantityController.text) ?? 1;

                          quantityController.text = (current + 0.1)
                              .toStringAsFixed(1);
                        },
                        icon: const Icon(Icons.add_circle_outline),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await _saveMealLog(meal);

                      if (mounted) {
                        Navigator.pop(context);
                      }
                    },
                    icon: const Icon(Icons.check),
                    label: const Text(
                      "Update Meal",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
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
    );
  }

  Widget _buildImageUI() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Meal Type',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),

          decoration: BoxDecoration(
            color: const Color(0xFFF6F6F6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFD7D7D7)),
          ),

          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedMealType,

              isExpanded: true,

              icon: const Icon(Icons.keyboard_arrow_down),

              items: mealTypes.map((meal) {
                return DropdownMenuItem(
                  value: meal,

                  child: Text(meal, style: const TextStyle(fontSize: 15)),
                );
              }).toList(),

              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    selectedMealType = value;
                  });
                }
              },
            ),
          ),
        ),

        const SizedBox(height: 6),

        Container(height: 1, color: const Color(0xFFD7D7D7)),

        const SizedBox(height: 24),

        const Text(
          'Pre-meal photo',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),

        const SizedBox(height: 4),

        const Text(
          'Take a photo of your food before you start eating.',
          style: TextStyle(fontSize: 12, color: Colors.black54),
        ),

        const SizedBox(height: 16),

        GestureDetector(
          onTap: () {
            _openCamera(isPreMeal: true);
          },
          child: Container(
            height: 260,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFC9D4CF)),
              image: preMealImage != null
                  ? DecorationImage(
                      image: FileImage(preMealImage!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: preMealImage == null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        height: 72,
                        width: 72,
                        decoration: const BoxDecoration(
                          color: Color(0xFF008C5E),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 34,
                        ),
                      ),

                      const SizedBox(height: 16),

                      const Text(
                        'Tap to take photo',
                        style: TextStyle(
                          color: Color(0xFF006B52),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  )
                : Stack(
                    children: [
                      Positioned(
                        top: 12,
                        right: 12,
                        child: GestureDetector(
                          onTap: () {
                            _openCamera(isPreMeal: true);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.refresh,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),

        const SizedBox(height: 30),

        Row(
          children: [
            const Text(
              'Post-meal photo',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),

            const SizedBox(width: 8),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text('Optional', style: TextStyle(fontSize: 10)),
            ),
          ],
        ),

        const SizedBox(height: 6),

        const Text(
          'Show us what was left on your plate.',
          style: TextStyle(fontSize: 12, color: Colors.black54),
        ),

        const SizedBox(height: 16),

        GestureDetector(
          onTap: () {
            _openCamera(isPreMeal: false);
          },
          child: Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFC9D4CF)),
              image: postMealImage != null
                  ? DecorationImage(
                      image: FileImage(postMealImage!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: postMealImage == null
                ? const Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_a_photo_outlined, color: Colors.black54),

                        SizedBox(width: 10),

                        Text(
                          'Add post-meal photo',
                          style: TextStyle(
                            color: Color(0xFF006B52),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                : Stack(
                    children: [
                      Positioned(
                        top: 12,
                        right: 12,
                        child: GestureDetector(
                          onTap: () {
                            _openCamera(isPreMeal: false);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.refresh,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),

        const SizedBox(height: 34),
      ],
    );
  }

  Widget _buildSearchChooseUI() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Diet Recall',
          style: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),

        const SizedBox(height: 4),

        const Text(
          'Log what you had for Breakfast',
          style: TextStyle(fontSize: 13, color: Colors.black54),
        ),

        const SizedBox(height: 24),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFD7D7D7)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Search recipe',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),

              const SizedBox(height: 10),

              TextField(
                controller: searchController,
                onChanged: (value) {
                  if (_debounce?.isActive ?? false) {
                    _debounce?.cancel();
                  }

                  _debounce = Timer(const Duration(milliseconds: 500), () {
                    _searchRecipes(value);
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Type food name...',
                  prefixIcon: const Icon(Icons.search),

                  suffixIcon: isSearching
                      ? Padding(
                          padding: EdgeInsets.all(14),
                          child: SizedBox(
                            height: 18,
                            width: 18,
                            child: Shimmer.card(),
                          ),
                        )
                      : null,

                  filled: true,
                  fillColor: const Color(0xFFF6F6F6),
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              if (searchedRecipes.isNotEmpty) ...[
                const SizedBox(height: 16),

                Container(
                  constraints: const BoxConstraints(maxHeight: 300),

                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE4E4E4)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),

                  child: ListView.separated(
                    padding: const EdgeInsets.all(10),
                    shrinkWrap: true,

                    itemCount: searchedRecipes.length,

                    separatorBuilder: (_, __) => const SizedBox(height: 10),

                    itemBuilder: (context, index) {
                      final recipe = searchedRecipes[index];

                      return GestureDetector(
                        onTap: () async {
                          searchController.text = recipe.recipeName;
                          FocusScope.of(context).unfocus();

                          setState(() {
                            selectedRecipe = recipe;
                            searchedRecipes.clear();
                            isLoadingUnits = true;
                          });

                          recipeUnits = await _fetchRecipeUnitValues(
                            recipe.recipeCode ?? "",
                          );

                          if (mounted) {
                            setState(() {
                              isLoadingUnits = false;
                            });
                          }
                        },

                        child: Container(
                          padding: const EdgeInsets.all(14),

                          decoration: BoxDecoration(
                            color: const Color(0xFFF8F8F8),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE4E4E4)),
                          ),

                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.network(
                                  'https://datatools.sjri.res.in/static/VD/food_images_large/${recipe.recipeCode}.jpg',

                                  height: 50,
                                  width: 50,
                                  fit: BoxFit.cover,

                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      height: 50,
                                      width: 50,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE7F5EF),
                                        borderRadius: BorderRadius.circular(10),
                                      ),

                                      child: const Icon(
                                        Icons.fastfood,
                                        color: Color(0xFF008C5E),
                                      ),
                                    );
                                  },

                                  loadingBuilder:
                                      (context, child, loadingProgress) {
                                        if (loadingProgress == null) {
                                          return child;
                                        }

                                        return Container(
                                          height: 50,
                                          width: 50,
                                          alignment: Alignment.center,

                                          decoration: BoxDecoration(
                                            color: const Color(0xFFE7F5EF),
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),

                                          child: SizedBox(
                                            height: 18,
                                            width: 18,
                                            child: Shimmer.card(),
                                          ),
                                        );
                                      },
                                ),
                              ),
                              const SizedBox(width: 12),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      recipe.recipeName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                      ),
                                    ),

                                    const SizedBox(height: 4),

                                    Text(
                                      recipe.recipeCategory,
                                      style: const TextStyle(
                                        color: Colors.black54,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const Icon(
                                Icons.arrow_forward_ios,
                                size: 14,
                                color: Colors.black38,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
              const SizedBox(height: 24),
              const Text(
                'Meal Type',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),

              const SizedBox(height: 10),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),

                decoration: BoxDecoration(
                  color: const Color(0xFFF6F6F6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFD7D7D7)),
                ),

                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedMealType,

                    isExpanded: true,

                    icon: const Icon(Icons.keyboard_arrow_down),

                    items: mealTypes.map((meal) {
                      return DropdownMenuItem(
                        value: meal,

                        child: Text(meal, style: const TextStyle(fontSize: 15)),
                      );
                    }).toList(),

                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          selectedMealType = value;
                        });
                      }
                    },
                  ),
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                'Quantity',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),

              const SizedBox(height: 10),
              SizedBox(
                child: TextField(
                  controller: quantityController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFFF6F6F6),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFD7D7D7)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFD7D7D7)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF008C5E)),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 26),
              const SizedBox(height: 12),

              if (selectedRecipe != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE7F5EF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF008C5E).withOpacity(0.2),
                    ),
                  ),
                  child: isLoadingUnits
                      ? const Row(
                          children: [
                            SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 10),
                            Text("Loading serving units..."),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Serving Unit",
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF008C5E),
                              ),
                            ),

                            const SizedBox(height: 8),

                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: recipeUnits.map((unit) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    unit,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 34),
      ],
    );
  }

  Future<void> _saveMealLog(MealPlanModel meal) async {
    final targetDateString =
        "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";

    final units = await _fetchRecipeUnitValues(meal.recipeCode ?? "");
    await _dietRecallRepository.logViaSearchChoose(
      recipeCode: meal.recipeCode ?? "",
      mealSlot: meal.mealType.toLowerCase(),
      quantity: meal.quantity.toString(),
      didEatAsPlanned: true,
      planId: widget.planId ?? "",
      date: targetDateString,
      unit: units.isNotEmpty ? units.first : "",
    );
  }

  Widget _saveButton(bool isImage) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: ElevatedButton(
        onPressed: () async {
          try {
            if (isImage) {
              AppSnackBar.show(
                context,
                message:
                    "Your Image has been sent to out team , you'll br notified once it's processed",
                type: SnackBarType.success,
              );
            }
            final targetDateString =
                "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";
            print("Selected Meals Count = ${selectedMeals.length}");

            for (final meal in selectedMeals) {
              print("Recipe Code = ${meal.recipeCode}");
              print("Meal Type = ${meal.mealType}");
              print("Quantity = ${meal.quantity}");
            }
            if (selectedMeals.isNotEmpty) {
              for (final meal in selectedMeals) {
                await _dietRecallRepository.logViaSearchChoose(
                  recipeCode: meal.recipeCode ?? "",
                  mealSlot: meal.mealType.toLowerCase(),
                  quantity: meal.quantity.toString(),
                  didEatAsPlanned: true,
                  planId: widget.planId ?? "",
                  date: targetDateString,
                  unit: recipeUnits.first,
                );
              }
            } else {
              await _dietRecallRepository.logViaSearchChoose(
                recipeCode: selectedRecipe?.recipeCode ?? "",
                mealSlot: selectedMealType.toLowerCase(),
                quantity: quantityController.text.trim(),
                didEatAsPlanned: false,
                planId: widget.planId ?? "",
                date: targetDateString,
                unit: recipeUnits.first,
              );
            }

            if (!mounted) return;
            AppSnackBar.show(
              context,
              message: "Meal Logged successfully",
              type: SnackBarType.success,
            );

            setState(() {
              searchController.clear();
              quantityController.text = "1";
              selectedRecipe = null;
            });
          } catch (e, stackTrace) {
            debugPrint("DETAILED ERROR: $e");
            debugPrint("STACK TRACE: $stackTrace");
            AppSnackBar.show(
              context,
              message: "Failed to save $e",
              type: SnackBarType.error,
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
          'Save meal log',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildToggleButton({
    required String title,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected ? const Color(0xFF006B52) : Colors.black54,
              ),

              const SizedBox(width: 8),

              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: selected ? const Color(0xFF006B52) : Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
