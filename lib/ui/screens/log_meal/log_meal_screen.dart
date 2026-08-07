import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:adam/data/models/plan_meal_model.dart';
import 'package:adam/data/models/recipe_model.dart';
import 'package:adam/data/repositories/diet_recall_repository.dart';
import 'package:adam/data/repositories/plan_meal_repository.dart';
import 'package:adam/data/repositories/recipe_repository.dart';
import 'package:adam/ui/utils/custom_calendar.dart';
import 'package:adam/ui/utils/custom_snackbar.dart';
import 'package:adam/ui/utils/shimmer.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gal/gal.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LogMealScreen extends StatefulWidget {
  const LogMealScreen({super.key});

  @override
  State<LogMealScreen> createState() => _LogMealScreenState();
}

class _LogMealScreenState extends State<LogMealScreen> {
  bool isImageSelected = true;
  final DietRecallRepository _dietRecallRepository = DietRecallRepository();
  final TextEditingController quantityController = TextEditingController(
    text: "1",
  );
  Recipe? selectedRecipe;
  String selectedMealType = 'None';
  final List<String> mealTypes = [
    'None',
    'Breakfast',
    'Lunch',
    'Dinner',
    'Snacks',
  ];
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
  final Set<String> selectedMealGroups = {};
  bool _isSaving = false;
  final DietRecallRepository _dietRepo = DietRecallRepository();
  List<dynamic> recallItems = [];

  @override
  void initState() {
    super.initState();
    _loadMealPlan(selectedDate);
    _fetchRecall(selectedDate);
    _fetchPlanId(selectedDate);
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
      print("Total meals: ${savedMeals.length}");

      setState(() {});
    }
  }

  bool _isLoading = true;
  final MealPlanRepository mealPlanRepository = MealPlanRepository();
  String? planId;

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
        _isLoading = false;
        planId = response[0].planId;
        print("this is coming from call ${planId}");
      });
    } catch (e) {
      setState(() => _isLoading = false);
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

  Future<void> _loadMealPlan(DateTime date) async {
    try {
      final formattedDate = DateFormat('yyyy-MM-dd').format(date);

      final meals = await _dietRepo.fetchMealPlan(date: formattedDate);

      if (!mounted) return;

      setState(() {
        savedMeals = meals;
        selectedMeals.clear();
      });
    } catch (e) {
      print("❌ LOAD MEAL PLAN ERROR: $e");
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
                                try {
                                  final image = await _cameraController!
                                      .takePicture();
                                  final file = File(image.path);
                                  try {
                                    await Gal.putImage(file.path);
                                    debugPrint("✅ Image saved to gallery");
                                  } catch (e) {
                                    debugPrint("❌ Failed to save image: $e");
                                  }
                                  if (!mounted) return;

                                  Navigator.pop(context);

                                  _showImagePreview(
                                    file: file,
                                    isPreMeal: isPreMeal,
                                  );
                                } catch (e) {
                                  debugPrint(e.toString());
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

  Future<void> _openImageSourcePicker({required bool isPreMeal}) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Select Image Source",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F5132),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Choose how you want to capture your $selectedMealType log",
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          Navigator.pop(context); // Close selection sheet
                          _openCamera(isPreMeal: isPreMeal);
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE7F5EF),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFF008C5E).withOpacity(0.2),
                            ),
                          ),
                          child: const Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.camera_alt_rounded,
                                size: 32,
                                color: Color(0xFF008C5E),
                              ),
                              SizedBox(height: 10),
                              Text(
                                "Take Photo",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF0F5132),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Option 2: Device Media Photo Gallery
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          Navigator.pop(context); // Close selection sheet
                          try {
                            final ImagePicker picker = ImagePicker();
                            final XFile? image = await picker.pickImage(
                              source: ImageSource.gallery,
                              imageQuality: 85,
                            );

                            if (image == null) return;
                            final file = File(image.path);

                            if (!mounted) return;
                            _showImagePreview(file: file, isPreMeal: isPreMeal);
                          } catch (e) {
                            debugPrint("Gallery Picker Exception: $e");
                          }
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF6F6F6),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.photo_library_rounded,
                                size: 32,
                                color: Colors.grey.shade700,
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                "From Gallery",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF111827),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showImagePreview({
    required File file,
    required bool isPreMeal,
  }) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      builder: (context) {
        bool isSaving = false;

        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.95,
                child: Column(
                  children: [
                    Expanded(
                      child: Image.file(
                        file,
                        fit: BoxFit.contain,
                        width: double.infinity,
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () async {
                                Navigator.pop(context);

                                await _openCamera(isPreMeal: isPreMeal);
                              },
                              child: const Text(
                                "Retake",
                                style: TextStyle(color: Colors.green),
                              ),
                            ),
                          ),

                          const SizedBox(width: 12),

                          Expanded(
                            child: ElevatedButton(
                              onPressed: isSaving
                                  ? null
                                  : () async {
                                      if (selectedMealType.toLowerCase() ==
                                          'none') {
                                        AppSnackBar.show(
                                          context,
                                          message: "Please select Meal type",
                                          type: SnackBarType.error,
                                        );
                                        setState(() => _isSaving = false);
                                      }
                                      setSheetState(() {
                                        isSaving = true;
                                      });

                                      try {
                                        final imageUrl =
                                            await _dietRecallRepository
                                                .uploadMealImage(
                                                  file: file,
                                                  mealSlot: selectedMealType,
                                                  isPreMeal: isPreMeal,
                                                );

                                        await _dietRecallRepository
                                            .saveImageRecall(
                                              imageUrlPre: isPreMeal
                                                  ? imageUrl
                                                  : "",
                                              imageUrlPost: !isPreMeal
                                                  ? imageUrl
                                                  : null,
                                              mealSlot: selectedMealType
                                                  .toLowerCase(),
                                              planId: planId ?? "",
                                            );

                                        if (mounted) {
                                          setState(() {
                                            if (isPreMeal) {
                                              preMealImage = file;
                                            } else {
                                              postMealImage = file;
                                            }
                                          });

                                          Navigator.pop(context);

                                          AppSnackBar.show(
                                            context,
                                            message:
                                                "$selectedMealType image saved successfully",
                                            type: SnackBarType.success,
                                          );
                                        }
                                      } catch (e) {
                                        setSheetState(() {
                                          isSaving = false;
                                        });

                                        AppSnackBar.show(
                                          context,
                                          message: "Failed to upload image",
                                          type: SnackBarType.error,
                                        );
                                      }
                                    },
                              child: isSaving
                                  ? const SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      "Save Image",
                                      style: TextStyle(color: Colors.green),
                                    ),
                            ),
                          ),
                        ],
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

  Future<void> _saveImageToGallery(File file) async {
    try {
      await Gal.putImage(file.path);
      debugPrint("✅ Image saved to gallery");
    } catch (e) {
      debugPrint("❌ Gallery save failed: $e");
      rethrow;
    }
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
    final breakfastMeals = savedMeals
        .where((m) => m.mealType.toLowerCase() == 'breakfast')
        .toList();

    final lunchMeals = savedMeals
        .where((m) => m.mealType.toLowerCase() == 'lunch')
        .toList();

    final dinnerMeals = savedMeals
        .where((m) => m.mealType.toLowerCase() == 'dinner')
        .toList();

    final snackMeals = savedMeals
        .where((m) => m.mealType.toLowerCase() == 'snacks')
        .toList();
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
                _loadMealPlan(date);
              },
            ),
            const SizedBox(height: 10),
            Container(
              height: 50,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F2F1),
                borderRadius: BorderRadius.circular(16),
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
                    icon: Icons.search_rounded,
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
                  onPressed: () async {
                    await _openLoggedItems();
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF008C5E),
                  ),
                  icon: const Icon(Icons.history, color: Color(0xFF008C5E)),
                  label: const Text(
                    "Show Logged Meals",
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

                                    Flexible(
                                      child: Text(
                                        '${meal.quantity} ${meal.quantityUnit}',
                                      ),
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
            if (!isImageSelected)
              Column(
                children: [
                  _buildMealGroupCard("Breakfast", breakfastMeals),
                  _buildMealGroupCard("Lunch", lunchMeals),
                  _buildMealGroupCard("Dinner", dinnerMeals),
                  _buildMealGroupCard("Snacks", snackMeals),
                ],
              ),
          ],
        ),
      ),
      bottomNavigationBar: isImageSelected
          ? SizedBox()
          : SafeArea(
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                color: Colors.white,
                child: _saveButton(isImageSelected),
              ),
            ),
    );
  }

  Widget _buildMealGroupCard(String title, List<MealPlanModel> meals) {
    if (meals.isEmpty) return const SizedBox();

    final isSelected = selectedMealGroups.contains(title);

    final totalCalories = meals.fold<double>(
      0,
      (sum, meal) => sum + meal.calories,
    );

    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            selectedMealGroups.remove(title);
          } else {
            selectedMealGroups.add(title);
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE8F7F1) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? const Color(0xFF008C5E) : Colors.grey.shade200,
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
            Container(
              height: 72,
              width: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFE7F5EF),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.restaurant_menu,
                color: Color(0xFF008C5E),
                size: 32,
              ),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    "${meals.length} items",
                    style: TextStyle(color: Colors.grey.shade600),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    meals.map((e) => e.foodName).join(", "),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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
                      Text("${totalCalories.toStringAsFixed(0)} kcal"),
                    ],
                  ),
                ],
              ),
            ),

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
                  ? const Icon(Icons.check, size: 18, color: Colors.white)
                  : null,
            ),
          ],
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

              // Drag Handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              const SizedBox(height: 16),

              // Sheet Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    const Text(
                      "Logged Meals",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.3,
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
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "${recallItems.length} Items",
                        style: const TextStyle(
                          color: Color(0xFF008C5E),
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              Divider(height: 1, color: Colors.grey.shade200),

              Expanded(
                child: recallItems.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.restaurant_outlined,
                              size: 56,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              "No meals logged",
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        itemCount: recallItems.length,
                        itemBuilder: (context, index) {
                          final item = recallItems[index];
                          final bool planned =
                              item['did_eat_as_planned'] == true;
                          final mealSlot = (item['meal_slot'] ?? "").toString();

                          Color mealColor(String meal) {
                            switch (meal.toLowerCase()) {
                              case 'breakfast':
                                return const Color(0xFFE65100);
                              case 'lunch':
                                return const Color(0xFF0277BD);
                              case 'dinner':
                                return const Color(0xFF6A1B9A);
                              default:
                                return const Color(0xFF2E7D32);
                            }
                          }

                          final slotColor = mealColor(mealSlot);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.shade200),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.02),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Container(
                                    height: 48,
                                    width: 48,
                                    decoration: BoxDecoration(
                                      color:
                                          (planned
                                                  ? Colors.green
                                                  : Colors.orange)
                                              .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      planned
                                          ? Icons.check_circle_outline
                                          : Icons.edit_note,
                                      color: planned
                                          ? Colors.green.shade700
                                          : Colors.orange.shade800,
                                      size: 24,
                                    ),
                                  ),

                                  const SizedBox(width: 12),

                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                item['food_name'] ??
                                                    "Unknown Food",
                                                style: const TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w600,
                                                  letterSpacing: -0.2,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                          ],
                                        ),

                                        const SizedBox(height: 6),

                                        Wrap(
                                          spacing: 6,
                                          runSpacing: 4,
                                          crossAxisAlignment:
                                              WrapCrossAlignment.center,
                                          children: [
                                            if (mealSlot.isNotEmpty)
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 2,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: slotColor.withOpacity(
                                                    0.08,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  mealSlot.toUpperCase(),
                                                  style: TextStyle(
                                                    color: slotColor,
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 10,
                                                  ),
                                                ),
                                              ),
                                            Text(
                                              "${item['energy_kcal'] ?? 0} kcal",
                                              style: TextStyle(
                                                color: Colors.grey.shade700,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            if (item['food_qty'] != null) ...[
                                              Text(
                                                "•",
                                                style: TextStyle(
                                                  color: Colors.grey.shade400,
                                                ),
                                              ),
                                              Text(
                                                "Qty: ${item['food_qty']}",
                                                style: TextStyle(
                                                  color: Colors.grey.shade700,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),

                                  PopupMenuButton<String>(
                                    icon: Icon(
                                      Icons.more_vert,
                                      color: Colors.grey.shade500,
                                      size: 20,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    onSelected: (value) async {
                                      if (value == 'edit') {
                                        Navigator.pop(context);
                                        _showRecallEditBottomSheet(item);
                                      } else if (value == 'delete') {
                                        final confirmed = await showDialog<bool>(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text("Delete Meal"),
                                            content: const Text(
                                              "Are you sure you want to delete this meal?",
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(
                                                  context,
                                                  false,
                                                ),
                                                child: const Text("Cancel"),
                                              ),
                                              TextButton(
                                                onPressed: () => Navigator.pop(
                                                  context,
                                                  true,
                                                ),
                                                child: const Text(
                                                  "Delete",
                                                  style: TextStyle(
                                                    color: Colors.red,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );

                                        if (confirmed == true) {
                                          try {
                                            await _deleteRecall(item['id']);
                                            Navigator.pop(context);
                                          } catch (e) {
                                            print("Delete error => $e");
                                            AppSnackBar.show(
                                              context,
                                              message: "Failed to delete meal",
                                              type: SnackBarType.error,
                                            );
                                          }
                                        }
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(
                                        value: 'edit',
                                        child: Row(
                                          children: [
                                            Icon(Icons.edit_outlined, size: 18),
                                            SizedBox(width: 8),
                                            Text("Edit"),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.delete_outline,
                                              size: 18,
                                              color: Colors.red,
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              "Delete",
                                              style: TextStyle(
                                                color: Colors.red,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
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

  Future<bool> _shouldProceedWithEdit({
    required Map<String, dynamic> currentItem,
    required String mealSlot,
  }) async {
    print("========== _shouldProceedWithEdit ==========");

    final limit = mealSlot.toLowerCase() == "snacks" ? 500 : 750;

    double totalCalories = 0;

    print("Current Recall Id = ${currentItem['id']}");
    print("Meal Slot = $mealSlot");

    for (final item in recallItems) {
      final itemSlot = (item["meal_slot"] ?? "").toString().toLowerCase();

      if (itemSlot != mealSlot.toLowerCase()) {
        continue;
      }

      // Skip the item being edited
      if (item["id"] == currentItem["id"]) {
        continue;
      }

      final calories = double.tryParse(item["energy_kcal"].toString()) ?? 0;

      totalCalories += calories;

      print(
        "Adding ${item["food_name"]} -> $calories kcal | Total = $totalCalories",
      );
    }

    // Add calories of edited item
    final editedCalories =
        double.tryParse(currentItem["energy_kcal"].toString()) ?? 0;

    totalCalories += editedCalories;

    print("--------------------------------");
    print("Total Calories = $totalCalories");
    print("Limit = $limit");
    print("--------------------------------");

    if (totalCalories <= limit) {
      print("Within limit");
      return true;
    }

    final result = await _showConfirmationDialog(
      totalCalories,
      limit,
      mealSlot,
    );

    return result ?? false;
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
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                padding: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Handle
                      Container(
                        width: 45,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),

                      const SizedBox(height: 20),

                      const Text(
                        "Edit Meal",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Recipe Name Field
                      TextField(
                        controller: recipeController,
                        onChanged: (value) {
                          if (_debounce?.isActive ?? false) {
                            _debounce?.cancel();
                          }

                          _debounce = Timer(
                            const Duration(milliseconds: 500),
                            () async {
                              await _searchRecipes(value);
                              setModalState(() {});
                            },
                          );
                        },
                        decoration: InputDecoration(
                          labelText: "Recipe Name",
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: isSearching
                              ? const Padding(
                                  padding: EdgeInsets.all(14),
                                  child: SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Quantity Field
                      TextField(
                        controller: quantityController,
                        textInputAction: TextInputAction.done,
                        keyboardType: const TextInputType.numberWithOptions(
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

                      // Meal Slot Dropdown
                      DropdownButtonFormField<String>(
                        value: mealTimes.contains(selectedMealTime)
                            ? selectedMealTime
                            : mealTimes.first,
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
                                  meal[0].toUpperCase() + meal.substring(1),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setModalState(() {
                              selectedMealTime = value;
                            });
                          }
                        },
                      ),

                      // Recipe Search List
                      if (searchedRecipes.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Container(
                          constraints: const BoxConstraints(maxHeight: 200),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE4E4E4)),
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
                            itemCount: searchedRecipes.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final recipe = searchedRecipes[index];

                              return ListTile(
                                leading: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
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
                                  recipeController.text = recipe.recipeName;
                                  setModalState(() {
                                    selectedRecipe = recipe;
                                    searchedRecipes.clear();
                                  });
                                  FocusScope.of(context).unfocus();
                                },
                              );
                            },
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final enteredFoodName = recipeController.text
                                .trim();
                            final enteredQuantity = quantityController.text
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

                            final shouldUpdate = await _shouldProceedWithEdit(
                              currentItem: item,
                              mealSlot: selectedMealTime,
                            );

                            if (!shouldUpdate) return;

                            try {
                              await _dietRepo.editRecall(
                                recallId: item['id'],
                                foodName: recipeController.text,
                                quantity: quantityController.text,
                                mealSlot: selectedMealTime,
                              );

                              if (mounted) Navigator.pop(sheetContext);

                              await _fetchRecall(selectedDate);
                            } catch (e) {
                              AppSnackBar.show(
                                sheetContext,
                                message: "Failed to update meal",
                                type: SnackBarType.error,
                              );
                            }
                          },
                          icon: const Icon(Icons.check),
                          label: const Text("Update Meal"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF008C5E),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // void _showRecallEditBottomSheet(Map<String, dynamic> item) {
  //   final recipeController = TextEditingController(
  //     text: (item['food_name'] ?? '').toString(),
  //   );
  //
  //   final quantityController = TextEditingController(
  //     text: (item['food_qty'] ?? '').toString(),
  //   );
  //
  //   String selectedMealTime = (item['meal_slot'] ?? 'breakfast')
  //       .toString()
  //       .toLowerCase();
  //
  //   final mealTimes = ['breakfast', 'lunch', 'dinner', 'snacks'];
  //
  //   showModalBottomSheet(
  //     context: context,
  //     isScrollControlled: true,
  //     backgroundColor: Colors.transparent,
  //     builder: (sheetContext) {
  //       return Scaffold(
  //         body: StatefulBuilder(
  //           builder: (context, setModalState) {
  //             return Container(
  //               decoration: const BoxDecoration(
  //                 color: Colors.white,
  //                 borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
  //               ),
  //               child: Padding(
  //                 padding: EdgeInsets.only(
  //                   left: 20,
  //                   right: 20,
  //                   top: 20,
  //                   bottom: MediaQuery.of(context).viewInsets.bottom + 20,
  //                 ),
  //                 child: SingleChildScrollView(
  //                   child: Column(
  //                     mainAxisSize: MainAxisSize.min,
  //                     children: [
  //                       Container(
  //                         width: 45,
  //                         height: 5,
  //                         decoration: BoxDecoration(
  //                           color: Colors.grey.shade300,
  //                           borderRadius: BorderRadius.circular(20),
  //                         ),
  //                       ),
  //
  //                       const SizedBox(height: 24),
  //
  //                       const Text(
  //                         "Edit Meal",
  //                         style: TextStyle(
  //                           fontSize: 20,
  //                           fontWeight: FontWeight.w700,
  //                         ),
  //                       ),
  //
  //                       const SizedBox(height: 24),
  //
  //                       TextField(
  //                         controller: recipeController,
  //                         onChanged: (value) {
  //                           if (_debounce?.isActive ?? false) {
  //                             _debounce?.cancel();
  //                           }
  //
  //                           _debounce = Timer(
  //                             const Duration(milliseconds: 500),
  //                             () {
  //                               _searchRecipes(value);
  //                             },
  //                           );
  //                         },
  //                         decoration: InputDecoration(
  //                           labelText: "Recipe Name",
  //                           prefixIcon: const Icon(Icons.search),
  //
  //                           suffixIcon: isSearching
  //                               ? Padding(
  //                                   padding: EdgeInsets.all(14),
  //                                   child: SizedBox(
  //                                     height: 18,
  //                                     width: 18,
  //                                     child: Shimmer.card(),
  //                                   ),
  //                                 )
  //                               : null,
  //
  //                           border: OutlineInputBorder(
  //                             borderRadius: BorderRadius.circular(12),
  //                           ),
  //                         ),
  //                       ),
  //                       const SizedBox(height: 16),
  //
  //                       TextField(
  //                         controller: quantityController,
  //                         textInputAction: TextInputAction.done,
  //                         keyboardType: const TextInputType.numberWithOptions(
  //                           decimal: true,
  //                         ),
  //                         decoration: InputDecoration(
  //                           labelText: "Quantity",
  //                           border: OutlineInputBorder(
  //                             borderRadius: BorderRadius.circular(12),
  //                           ),
  //                         ),
  //                       ),
  //
  //                       const SizedBox(height: 16),
  //
  //                       DropdownButtonFormField<String>(
  //                         value: selectedMealTime,
  //                         decoration: InputDecoration(
  //                           labelText: "Meal Time",
  //                           border: OutlineInputBorder(
  //                             borderRadius: BorderRadius.circular(12),
  //                           ),
  //                         ),
  //                         items: mealTimes
  //                             .map(
  //                               (meal) => DropdownMenuItem(
  //                                 value: meal,
  //                                 child: Text(
  //                                   meal[0].toUpperCase() + meal.substring(1),
  //                                 ),
  //                               ),
  //                             )
  //                             .toList(),
  //                         onChanged: (value) {
  //                           if (value != null) {
  //                             setModalState(() {
  //                               selectedMealTime = value;
  //                             });
  //                           }
  //                         },
  //                       ),
  //                       if (searchedRecipes.isNotEmpty) ...[
  //                         const SizedBox(height: 10),
  //
  //                         Container(
  //                           constraints: const BoxConstraints(maxHeight: 250),
  //                           decoration: BoxDecoration(
  //                             color: Colors.white,
  //                             borderRadius: BorderRadius.circular(12),
  //                             border: Border.all(
  //                               color: const Color(0xFFE4E4E4),
  //                             ),
  //                             boxShadow: [
  //                               BoxShadow(
  //                                 color: Colors.black.withOpacity(0.05),
  //                                 blurRadius: 8,
  //                                 offset: const Offset(0, 4),
  //                               ),
  //                             ],
  //                           ),
  //                           child: ListView.separated(
  //                             shrinkWrap: true,
  //                             padding: const EdgeInsets.all(8),
  //                             itemCount: searchedRecipes.length,
  //                             separatorBuilder: (_, __) =>
  //                                 const Divider(height: 1),
  //                             itemBuilder: (context, index) {
  //                               final recipe = searchedRecipes[index];
  //
  //                               return ListTile(
  //                                 leading: ClipRRect(
  //                                   borderRadius: BorderRadius.circular(8),
  //                                   child: Image.network(
  //                                     'https://datatools.sjri.res.in/static/VD/food_images_large/${recipe.recipeCode}.jpg',
  //                                     width: 40,
  //                                     height: 40,
  //                                     fit: BoxFit.cover,
  //                                     errorBuilder: (_, __, ___) =>
  //                                         const Icon(Icons.fastfood),
  //                                   ),
  //                                 ),
  //                                 title: Text(recipe.recipeName),
  //                                 onTap: () {
  //                                   recipeController.text = recipe.recipeName;
  //
  //                                   setState(() {
  //                                     selectedRecipe = recipe;
  //                                     searchedRecipes.clear();
  //                                   });
  //
  //                                   FocusScope.of(context).unfocus();
  //                                 },
  //                               );
  //                             },
  //                           ),
  //                         ),
  //                       ],
  //                       const SizedBox(height: 24),
  //
  //                       SizedBox(
  //                         width: double.infinity,
  //                         height: 54,
  //                         child: ElevatedButton.icon(
  //                           // onPressed: () async {
  //                           //   final String enteredFoodName = recipeController
  //                           //       .text
  //                           //       .trim();
  //                           //   final String enteredQuantity = quantityController
  //                           //       .text
  //                           //       .trim();
  //                           //
  //                           //   if (enteredFoodName.isEmpty) {
  //                           //     AppSnackBar.show(
  //                           //       sheetContext,
  //                           //       message: "Meal name cannot be empty",
  //                           //       type: SnackBarType.error,
  //                           //     );
  //                           //     return;
  //                           //   }
  //                           //
  //                           //   if (enteredQuantity.isEmpty ||
  //                           //       double.tryParse(enteredQuantity) == null ||
  //                           //       double.parse(enteredQuantity) <= 0) {
  //                           //     AppSnackBar.show(
  //                           //       sheetContext,
  //                           //       message:
  //                           //           "Please enter a valid quantity greater than 0",
  //                           //       type: SnackBarType.error,
  //                           //     );
  //                           //     return;
  //                           //   }
  //                           //   try {
  //                           //     await _dietRepo.editRecall(
  //                           //       recallId: item['id'],
  //                           //       foodName: recipeController.text,
  //                           //       quantity: quantityController.text,
  //                           //       mealSlot: selectedMealTime,
  //                           //       didEatAsPlanned:
  //                           //           widget.didEatPlanned ?? false,
  //                           //     );
  //                           //
  //                           //     Navigator.pop(context);
  //                           //
  //                           //     await _fetchRecall(selectedDate);
  //                           //   } catch (e) {
  //                           //     AppSnackBar.show(
  //                           //       context,
  //                           //       message: "Failed to update meal",
  //                           //       type: SnackBarType.error,
  //                           //     );
  //                           //   }
  //                           // },
  //                           onPressed: () async {
  //                             print("===== UPDATE BUTTON PRESSED =====");
  //
  //                             final enteredFoodName = recipeController.text
  //                                 .trim();
  //                             final enteredQuantity = quantityController.text
  //                                 .trim();
  //                             print("Before validation");
  //
  //                             if (enteredFoodName.isEmpty) {
  //                               AppSnackBar.show(
  //                                 sheetContext,
  //                                 message: "Meal name cannot be empty",
  //                                 type: SnackBarType.error,
  //                               );
  //                               return;
  //                             }
  //
  //                             if (enteredQuantity.isEmpty ||
  //                                 double.tryParse(enteredQuantity) == null ||
  //                                 double.parse(enteredQuantity) <= 0) {
  //                               AppSnackBar.show(
  //                                 sheetContext,
  //                                 message:
  //                                     "Please enter a valid quantity greater than 0",
  //                                 type: SnackBarType.error,
  //                               );
  //                               return;
  //                             }
  //
  //                             final shouldUpdate = await _shouldProceedWithEdit(
  //                               currentItem: item,
  //                               mealSlot: selectedMealTime,
  //                             );
  //
  //                             if (!shouldUpdate) {
  //                               return;
  //                             }
  //
  //                             try {
  //                               await _dietRepo.editRecall(
  //                                 recallId: item['id'],
  //                                 foodName: recipeController.text,
  //                                 quantity: quantityController.text,
  //                                 mealSlot: selectedMealTime,
  //                               );
  //
  //                               Navigator.pop(context);
  //
  //                               await _fetchRecall(selectedDate);
  //                             } catch (e) {
  //                               AppSnackBar.show(
  //                                 context,
  //                                 message: "Failed to update meal",
  //                                 type: SnackBarType.error,
  //                               );
  //                             }
  //                           },
  //                           icon: const Icon(Icons.check),
  //                           label: const Text("Update Meal"),
  //                           style: ElevatedButton.styleFrom(
  //                             backgroundColor: const Color(0xFF008C5E),
  //                             foregroundColor: Colors.white,
  //                           ),
  //                         ),
  //                       ),
  //                     ],
  //                   ),
  //                 ),
  //               ),
  //             );
  //           },
  //         ),
  //       );
  //     },
  //   );
  // }

  // Future<bool> _shouldProceedWithSave() async {
  //   print("\n========== _shouldProceedWithSave ==========");
  //
  //   print("selectedRecipe = ${selectedRecipe?.recipeCode}");
  //   print("selectedMealType = $selectedMealType");
  //   print("selectedMeals Count = ${selectedMeals.length}");
  //   print("selectedMealGroups = $selectedMealGroups");
  //   print("quantity = ${quantityController.text}");
  //   print("recallItems Count = ${recallItems.length}");
  //
  //   //--------------------------------------------------
  //   // Determine current meal slot
  //   //--------------------------------------------------
  //
  //   String mealSlot = "";
  //
  //   if (selectedMeals.isNotEmpty) {
  //     print("\n📦 BULK SAVE");
  //
  //     for (final meal in selectedMeals) {
  //       print(
  //         "Selected Meal -> ${meal.recipeCode} | ${meal.mealType} | ${meal.quantity}",
  //       );
  //     }
  //
  //     mealSlot = selectedMeals.first.mealType.trim().toLowerCase();
  //
  //     print("Meal slot resolved from selectedMeals = $mealSlot");
  //   } else if (selectedMealGroups.isNotEmpty) {
  //     print("\n📋 PLANNED MEAL");
  //
  //     mealSlot = selectedMealGroups.first.trim().toLowerCase();
  //
  //     print("Meal slot resolved from selectedMealGroups = $mealSlot");
  //   } else {
  //     print("\n🥣 MANUAL RECIPE");
  //
  //     if (selectedRecipe == null) {
  //       print("selectedRecipe is NULL");
  //       return true;
  //     }
  //
  //     final qty = double.tryParse(quantityController.text.trim()) ?? 0;
  //
  //     if (qty <= 0) {
  //       print("Quantity invalid");
  //       return true;
  //     }
  //
  //     mealSlot = selectedMealType.trim().toLowerCase();
  //
  //     print("Meal slot resolved from selectedMealType = $mealSlot");
  //   }
  //
  //   //--------------------------------------------------
  //   // Safety
  //   //--------------------------------------------------
  //
  //   if (mealSlot.isEmpty) {
  //     print("Meal slot empty. Skipping dialog.");
  //     return true;
  //   }
  //
  //   final limit = mealSlot == "snacks" ? 500 : 750;
  //
  //   print("\nMeal Slot = $mealSlot");
  //   print("Limit = $limit");
  //
  //   //--------------------------------------------------
  //   // Calculate calories
  //   //--------------------------------------------------
  //
  //   double totalCalories = 0;
  //
  //   print("\n------------- RECALL ITEMS -------------");
  //   for (final item in recallItems) {
  //     print(
  //       "${item['meal_slot']} | ${item['food_name']} | ${item['energy_kcal']}",
  //     );
  //   }
  //
  //   for (int i = 0; i < recallItems.length; i++) {
  //     final item = recallItems[i];
  //
  //     final itemMealSlot = (item["meal_slot"] ?? "")
  //         .toString()
  //         .trim()
  //         .toLowerCase();
  //
  //     final energy = double.tryParse(item["energy_kcal"].toString()) ?? 0;
  //
  //     print(
  //       "Item $i -> slot=$itemMealSlot energy=$energy food=${item["food_name"]}",
  //     );
  //
  //     if (itemMealSlot == mealSlot) {
  //       totalCalories += energy;
  //
  //       print("✅ MATCH");
  //       print("Running Total = $totalCalories");
  //     } else {
  //       print("❌ NO MATCH");
  //     }
  //   }
  //
  //   print("----------------------------------------");
  //   print("Meal Slot       = $mealSlot");
  //   print("Total Calories  = $totalCalories");
  //   print("Limit           = $limit");
  //   print("----------------------------------------");
  //
  //   if (totalCalories <= limit) {
  //     print("Calories within limit.");
  //     return true;
  //   }
  //
  //   print("Calories exceeded. Showing dialog...");
  //
  //   final result = await _showConfirmationDialog(
  //     totalCalories,
  //     limit,
  //     mealSlot,
  //   );
  //
  //   print("Dialog Result = $result");
  //
  //   return result ?? false;
  // }
  Future<bool> _shouldProceedWithSave() async {
    print("\n========== _shouldProceedWithSave ==========");

    print("selectedRecipe = ${selectedRecipe?.recipeCode}");
    print("selectedMealType = $selectedMealType");
    print("selectedMeals Count = ${selectedMeals.length}");
    print("selectedMealGroups = $selectedMealGroups");
    print("quantity = ${quantityController.text}");
    print("recallItems Count = ${recallItems.length}");

    // Early validation for meal type
    if (selectedMealType.toLowerCase() == 'none' && selectedMeals.isEmpty) {
      print("❌ Meal type is 'None' and no bulk meals selected");
      return false;
    }

    String mealSlot = "";

    if (selectedMeals.isNotEmpty) {
      print("\n📦 BULK SAVE");

      for (final meal in selectedMeals) {
        print(
          "Selected Meal -> ${meal.recipeCode} | ${meal.mealType} | ${meal.quantity}",
        );
      }

      mealSlot = selectedMeals.first.mealType.trim().toLowerCase();

      print("Meal slot resolved from selectedMeals = $mealSlot");
    } else if (selectedMealGroups.isNotEmpty) {
      print("\n📋 PLANNED MEAL");

      mealSlot = selectedMealGroups.first.trim().toLowerCase();

      print("Meal slot resolved from selectedMealGroups = $mealSlot");
    } else {
      print("\n🥣 MANUAL RECIPE");

      if (selectedRecipe == null) {
        print("selectedRecipe is NULL");
        return false;
      }

      final qty = double.tryParse(quantityController.text.trim()) ?? 0;

      if (qty <= 0) {
        print("Quantity invalid");
        return false;
      }

      mealSlot = selectedMealType.trim().toLowerCase();

      print("Meal slot resolved from selectedMealType = $mealSlot");
    }

    // Safety check
    if (mealSlot.isEmpty || mealSlot == 'none') {
      print("Meal slot empty or 'none'. Skipping dialog.");
      return false;
    }

    final limit = mealSlot == "snacks" ? 500 : 750;

    print("\nMeal Slot = $mealSlot");
    print("Limit = $limit");

    double totalCalories = 0;

    print("\n------------- RECALL ITEMS -------------");
    for (final item in recallItems) {
      print(
        "${item['meal_slot']} | ${item['food_name']} | ${item['energy_kcal']}",
      );
    }

    for (int i = 0; i < recallItems.length; i++) {
      final item = recallItems[i];

      final itemMealSlot = (item["meal_slot"] ?? "")
          .toString()
          .trim()
          .toLowerCase();

      final energy = double.tryParse(item["energy_kcal"].toString()) ?? 0;

      print(
        "Item $i -> slot=$itemMealSlot energy=$energy food=${item["food_name"]}",
      );

      if (itemMealSlot == mealSlot) {
        totalCalories += energy;

        print("✅ MATCH");
        print("Running Total = $totalCalories");
      } else {
        print("❌ NO MATCH");
      }
    }

    print("----------------------------------------");
    print("Meal Slot       = $mealSlot");
    print("Total Calories  = $totalCalories");
    print("Limit           = $limit");
    print("----------------------------------------");

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

    print("Dialog Result = $result");

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

  Future<bool> _shouldProceedWithMealPlanUpdate(MealPlanModel meal) async {
    print("\n========== _shouldProceedWithMealPlanUpdate ==========");

    final mealSlot = meal.mealType.trim().toLowerCase();
    final limit = mealSlot == "snacks" ? 500 : 750;

    print("Meal Slot = $mealSlot");
    print("Limit = $limit");

    double totalCalories = 0;

    print("\n------------- RECALL ITEMS -------------");
    for (final item in recallItems) {
      print(
        "${item['meal_slot']} | ${item['food_name']} | ${item['energy_kcal']}",
      );
    }

    for (final item in recallItems) {
      final itemMealSlot = (item["meal_slot"] ?? "")
          .toString()
          .trim()
          .toLowerCase();

      if (itemMealSlot != mealSlot) {
        continue;
      }

      final calories = double.tryParse(item["energy_kcal"].toString()) ?? 0;

      totalCalories += calories;

      print(
        "Adding ${item["food_name"]} -> $calories kcal | Total = $totalCalories",
      );
    }

    print("----------------------------------------");
    print("Meal Slot      = $mealSlot");
    print("Total Calories = $totalCalories");
    print("Limit          = $limit");
    print("----------------------------------------");

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
                      final shouldProceed =
                          await _shouldProceedWithMealPlanUpdate(meal);

                      if (!shouldProceed) return;

                      await _saveMealLog(meal, quantityController.text);

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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF008C5E).withOpacity(0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF008C5E).withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedMealType,
              isExpanded: true,
              borderRadius: BorderRadius.circular(16),
              // Rounded popup menu
              dropdownColor: Colors.white,
              elevation: 6,
              icon: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE7F5EF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Color(0xFF008C5E),
                  size: 22,
                ),
              ),
              items: mealTypes.map((meal) {
                final isSelected = meal == selectedMealType;

                IconData mealIcon;
                switch (meal.toLowerCase()) {
                  case 'breakfast':
                    mealIcon = Icons.free_breakfast_outlined;
                    break;
                  case 'lunch':
                    mealIcon = Icons.lunch_dining_outlined;
                    break;
                  case 'dinner':
                    mealIcon = Icons.dinner_dining_outlined;
                    break;
                  default:
                    mealIcon = Icons.bakery_dining_outlined;
                }

                return DropdownMenuItem<String>(
                  value: meal,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF008C5E)
                              : const Color(0xFFE7F5EF),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          mealIcon,
                          size: 18,
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF008C5E),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        meal,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isSelected
                              ? const Color(0xFF0F5132)
                              : Colors.black87,
                        ),
                      ),
                    ],
                  ),
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
          onTap: () async {
            final isValid = await _validateMealTypeSelection();
            if (!isValid) return;
            _openImageSourcePicker(isPreMeal: true);
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
                            _openImageSourcePicker(isPreMeal: true);
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
            _openImageSourcePicker(isPreMeal: false);
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
                            _openImageSourcePicker(isPreMeal: false);
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
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.deepPurple.withOpacity(0.06),
                Colors.deepPurple.withOpacity(0.01),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.deepPurple.withOpacity(0.1)),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Diet Recall',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.6,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Replay your day. What’s on your plate?',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ],
          ),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF008C5E).withOpacity(0.2),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF008C5E).withOpacity(0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedMealType,
                    isExpanded: true,
                    borderRadius: BorderRadius.circular(16),
                    dropdownColor: Colors.white,
                    elevation: 6,
                    icon: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE7F5EF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: Color(0xFF008C5E),
                        size: 22,
                      ),
                    ),
                    items: mealTypes.map((meal) {
                      final isSelected = meal == selectedMealType;

                      IconData mealIcon;
                      switch (meal.toLowerCase()) {
                        case 'breakfast':
                          mealIcon = Icons.free_breakfast_outlined;
                          break;
                        case 'lunch':
                          mealIcon = Icons.lunch_dining_outlined;
                          break;
                        case 'dinner':
                          mealIcon = Icons.dinner_dining_outlined;
                          break;
                        default:
                          mealIcon = Icons.bakery_dining_outlined;
                      }

                      return DropdownMenuItem<String>(
                        value: meal,
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF008C5E)
                                    : const Color(0xFFE7F5EF),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                mealIcon,
                                size: 18,
                                color: isSelected
                                    ? Colors.white
                                    : const Color(0xFF008C5E),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              meal,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isSelected
                                    ? const Color(0xFF0F5132)
                                    : Colors.black87,
                              ),
                            ),
                          ],
                        ),
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
      ],
    );
  }

  Future<bool> _validateMealTypeSelection() async {
    if (selectedMealType.toLowerCase() == 'none') {
      AppSnackBar.show(
        context,
        message: "Please select a Meal type first",
        type: SnackBarType.error,
      );
      return false;
    }
    return true;
  }

  Future<void> _saveMealLog(MealPlanModel meal, String? quantity) async {
    final targetDateString =
        "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";

    await _dietRecallRepository.logViaSearchChoose(
      recipeCode: meal.recipeCode ?? "",
      mealSlot: meal.mealType.toLowerCase(),
      quantity: quantity.toString(),
      planId: planId ?? "",
      date: targetDateString,
    );
  }

  // Widget _saveButton(bool isImage) {
  //   return SizedBox(
  //     width: double.infinity,
  //     height: 58,
  //     child: ElevatedButton(
  //       onPressed: _isSaving
  //           ? null
  //           : () async {
  //               if (selectedMealType.toLowerCase() == 'none') {
  //                 AppSnackBar.show(
  //                   context,
  //                   message: "Please select Meal type",
  //                   type: SnackBarType.error,
  //                 );
  //                 setState(() => _isSaving = false);
  //               }
  //               print("========================================");
  //               print("🟢 SAVE BUTTON PRESSED");
  //               print("isImage: $isImage");
  //               print("selectedRecipe: ${selectedRecipe?.recipeCode}");
  //               print("selectedMealType: $selectedMealType");
  //               print("quantity: ${quantityController.text}");
  //               print("selectedMeals count: ${selectedMeals.length}");
  //               print("selectedMealGroups: $selectedMealGroups");
  //               print("========================================");
  //
  //               setState(() => _isSaving = true);
  //
  //               try {
  //                 print("➡️ Entered try block");
  //
  //                 if (isImage) {
  //                   print("📷 Image logging flow");
  //
  //                   if (preMealImage == null) {
  //                     print("❌ No pre meal image selected");
  //
  //                     AppSnackBar.show(
  //                       context,
  //                       message: "Please capture a pre-meal image first",
  //                       type: SnackBarType.error,
  //                     );
  //
  //                     setState(() => _isSaving = false);
  //                     return;
  //                   } else {
  //                     print("✅ Pre meal image found");
  //
  //                     AppSnackBar.show(
  //                       context,
  //                       message:
  //                           "Your Image has been sent to our team, you'll be notified once it's processed",
  //                       type: SnackBarType.success,
  //                     );
  //                   }
  //                 }
  //
  //                 if (!isImage) {
  //                   print("🍽 Manual meal logging flow");
  //
  //                   final bool hasBulkSelections = selectedMeals.isNotEmpty;
  //
  //                   print("hasBulkSelections = $hasBulkSelections");
  //
  //                   if (!hasBulkSelections) {
  //                     print("➡️ Manual recipe flow");
  //
  //                     final enteredQuantity = quantityController.text.trim();
  //
  //                     print("enteredQuantity = $enteredQuantity");
  //
  //                     if (selectedRecipe == null) {
  //                       print("❌ selectedRecipe is NULL");
  //
  //                       AppSnackBar.show(
  //                         context,
  //                         message:
  //                             "Please select a recipe or select items from your meal plan list before saving",
  //                         type: SnackBarType.error,
  //                       );
  //
  //                       setState(() => _isSaving = false);
  //                       return;
  //                     }
  //                     print("slot name${selectedMealType}");
  //
  //                     print("✅ selectedRecipe = ${selectedRecipe!.recipeCode}");
  //
  //                     if (enteredQuantity.isEmpty ||
  //                         double.tryParse(enteredQuantity) == null ||
  //                         double.parse(enteredQuantity) <= 0) {
  //                       print("❌ Invalid quantity");
  //
  //                       AppSnackBar.show(
  //                         context,
  //                         message:
  //                             "Please enter a valid recipe quantity greater than 0",
  //                         type: SnackBarType.error,
  //                       );
  //
  //                       setState(() => _isSaving = false);
  //                       return;
  //                     }
  //
  //                     print("✅ Quantity valid");
  //
  //                     print("✅ Proceeding with save");
  //                   }
  //                 }
  //                 print("========================================");
  //                 print("🚦 ALL VALIDATIONS PASSED");
  //                 print("About to run calorie confirmation");
  //                 print("========================================");
  //
  //                 final shouldSave = await _shouldProceedWithSave();
  //
  //                 print("========================================");
  //                 print("shouldSave = $shouldSave");
  //                 print("========================================");
  //
  //                 if (!shouldSave) {
  //                   print("❌ User cancelled save");
  //
  //                   setState(() => _isSaving = false);
  //
  //                   return;
  //                 }
  //                 print("🔥 BEFORE targetDateString");
  //                 final targetDateString =
  //                     "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";
  //
  //                 print("📅 targetDate = $targetDateString");
  //
  //                 if (!isImage) {
  //                   if (selectedMeals.isNotEmpty) {
  //                     print("📦 Bulk meal save");
  //                     print("Meal count = ${selectedMeals.length}");
  //
  //                     for (final meal in selectedMeals) {
  //                       print(
  //                         "➡️ Saving ${meal.recipeCode} (${meal.mealType}) qty=${meal.quantity}",
  //                       );
  //
  //                       await _dietRecallRepository.logViaSearchChoose(
  //                         recipeCode: meal.recipeCode ?? "",
  //                         mealSlot: meal.mealType.toLowerCase(),
  //                         quantity: meal.quantity.toString(),
  //                         planId: planId ?? "",
  //                         date: targetDateString,
  //                         unit: meal.quantityUnit.toString(),
  //                       );
  //
  //                       print("✅ Saved ${meal.recipeCode}");
  //                     }
  //                   } else {
  //                     print("🥣 Saving manual recipe");
  //                     print("recipeCode = ${selectedRecipe?.recipeCode}");
  //                     print("mealSlot = ${selectedMealType.toLowerCase()}");
  //                     print("quantity = ${quantityController.text.trim()}");
  //                     if (selectedMealType.toLowerCase() == 'none') {
  //                       AppSnackBar.show(
  //                         context,
  //                         message: "Please select Meal type",
  //                         type: SnackBarType.error,
  //                       );
  //                       setState(() => _isSaving = false);
  //                     }
  //
  //                     await _dietRecallRepository.logViaSearchChoose(
  //                       recipeCode: selectedRecipe?.recipeCode ?? "",
  //                       mealSlot: selectedMealType.toLowerCase(),
  //                       quantity: quantityController.text.trim(),
  //                       planId: planId ?? "",
  //                       date: targetDateString,
  //                       unit: recipeUnits.isNotEmpty ? recipeUnits.first : "g",
  //                     );
  //
  //                     print("✅ Manual recipe saved");
  //                   }
  //                 } else if (isImage && preMealImage != null) {
  //                   print("📷 Saving image meal");
  //
  //                   await _dietRecallRepository.logViaSearchChoose(
  //                     recipeCode: selectedRecipe?.recipeCode ?? "",
  //                     mealSlot: selectedMealType.toLowerCase(),
  //                     quantity: quantityController.text.trim(),
  //                     planId: planId ?? "",
  //                     date: targetDateString,
  //                   );
  //
  //                   print("✅ Image meal saved");
  //                 }
  //
  //                 print("🎉 Save completed successfully");
  //
  //                 if (!mounted) return;
  //
  //                 AppSnackBar.show(
  //                   context,
  //                   message: "Meal Logged successfully",
  //                   type: SnackBarType.success,
  //                 );
  //
  //                 print("🔄 Fetching recall");
  //
  //                 await _fetchRecall(selectedDate);
  //
  //                 print("🧹 Clearing form");
  //
  //                 setState(() {
  //                   searchController.clear();
  //                   quantityController.text = "1";
  //                   selectedRecipe = null;
  //                   selectedMeals.clear();
  //                   selectedMealGroups.clear();
  //                 });
  //
  //                 print("✅ Done");
  //               } catch (e, st) {
  //                 print("❌ ERROR");
  //                 print(e);
  //                 print(st);
  //
  //                 AppSnackBar.show(
  //                   context,
  //                   message: "Failed to save: $e",
  //                   type: SnackBarType.error,
  //                 );
  //               } finally {
  //                 print("🏁 Finally block");
  //
  //                 if (mounted) {
  //                   setState(() => _isSaving = false);
  //                 }
  //
  //                 print("========================================");
  //               }
  //             },
  //       style: ElevatedButton.styleFrom(
  //         backgroundColor: const Color(0xFF007A50),
  //         disabledBackgroundColor: const Color(0xFF007A50).withOpacity(0.6),
  //         elevation: 0,
  //         shape: RoundedRectangleBorder(
  //           borderRadius: BorderRadius.circular(14),
  //         ),
  //       ),
  //       child: _isSaving
  //           ? const SizedBox(
  //               height: 24,
  //               width: 24,
  //               child: CircularProgressIndicator(
  //                 color: Colors.white,
  //                 strokeWidth: 2.5,
  //               ),
  //             )
  //           : const Text(
  //               'Save meal log',
  //               style: TextStyle(
  //                 fontSize: 17,
  //                 fontWeight: FontWeight.w600,
  //                 color: Colors.white,
  //               ),
  //             ),
  //     ),
  //   );
  // }
  Widget _saveButton(bool isImage) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: ElevatedButton(
        onPressed: _isSaving
            ? null
            : () async {
                print("========================================");
                print("🟢 SAVE BUTTON PRESSED");
                print("isImage: $isImage");
                print("selectedRecipe: ${selectedRecipe?.recipeCode}");
                print("selectedMealType: $selectedMealType");
                print("quantity: ${quantityController.text}");
                print("selectedMeals count: ${selectedMeals.length}");
                print("selectedMealGroups: $selectedMealGroups");
                print("========================================");

                final bool hasBulkSelections = selectedMeals.isNotEmpty;

                // Validate top-level meal type ONLY IF NOT bulk saving
                if (!hasBulkSelections &&
                    selectedMealType.toLowerCase() == 'none') {
                  AppSnackBar.show(
                    context,
                    message: "Please select a Meal type",
                    type: SnackBarType.error,
                  );
                  return;
                }

                setState(() => _isSaving = true);

                try {
                  print("➡️ Entered try block");

                  if (isImage) {
                    print("📷 Image logging flow");

                    if (preMealImage == null) {
                      print("❌ No pre meal image selected");

                      AppSnackBar.show(
                        context,
                        message: "Please capture a pre-meal image first",
                        type: SnackBarType.error,
                      );

                      setState(() => _isSaving = false);
                      return;
                    } else {
                      print("✅ Pre meal image found");

                      AppSnackBar.show(
                        context,
                        message:
                            "Your Image has been sent to our team, you'll be notified once it's processed",
                        type: SnackBarType.success,
                      );
                    }
                  }

                  if (!isImage) {
                    print("🍽 Manual meal logging flow");
                    print("hasBulkSelections = $hasBulkSelections");

                    if (!hasBulkSelections) {
                      print("➡️ Manual recipe flow");

                      final enteredQuantity = quantityController.text.trim();

                      print("enteredQuantity = $enteredQuantity");

                      if (selectedRecipe == null) {
                        print("❌ selectedRecipe is NULL");

                        AppSnackBar.show(
                          context,
                          message:
                              "Please select a recipe or select items from your meal plan list before saving",
                          type: SnackBarType.error,
                        );

                        setState(() => _isSaving = false);
                        return;
                      }

                      print("✅ selectedRecipe = ${selectedRecipe!.recipeCode}");

                      if (enteredQuantity.isEmpty ||
                          double.tryParse(enteredQuantity) == null ||
                          double.parse(enteredQuantity) <= 0) {
                        print("❌ Invalid quantity");

                        AppSnackBar.show(
                          context,
                          message:
                              "Please enter a valid recipe quantity greater than 0",
                          type: SnackBarType.error,
                        );

                        setState(() => _isSaving = false);
                        return;
                      }

                      print("✅ Quantity valid");
                      print("✅ Proceeding with save");
                    } else {
                      // Bulk save validation
                      if (selectedMeals.isEmpty) {
                        AppSnackBar.show(
                          context,
                          message: "Please select at least one meal",
                          type: SnackBarType.error,
                        );
                        setState(() => _isSaving = false);
                        return;
                      }
                    }
                  }

                  print("========================================");
                  print("🚦 ALL VALIDATIONS PASSED");
                  print("About to run calorie confirmation");
                  print("========================================");

                  final shouldSave = await _shouldProceedWithSave();

                  print("========================================");
                  print("shouldSave = $shouldSave");
                  print("========================================");

                  if (!shouldSave) {
                    print("❌ User cancelled save");
                    setState(() => _isSaving = false);
                    return;
                  }

                  print("🔥 BEFORE targetDateString");
                  final targetDateString =
                      "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";

                  print("📅 targetDate = $targetDateString");

                  if (!isImage) {
                    if (selectedMeals.isNotEmpty) {
                      print("📦 Bulk meal save");
                      print("Meal count = ${selectedMeals.length}");

                      for (final meal in selectedMeals) {
                        print(
                          "➡️ Saving ${meal.recipeCode} (${meal.mealType}) qty=${meal.quantity}",
                        );

                        await _dietRecallRepository.logViaSearchChoose(
                          recipeCode: meal.recipeCode ?? "",
                          mealSlot: meal.mealType.toLowerCase(),
                          quantity: meal.quantity.toString(),
                          planId: planId ?? "",
                          date: targetDateString,
                          unit: meal.quantityUnit.toString(),
                        );

                        print("✅ Saved ${meal.recipeCode}");
                      }
                    } else {
                      print("🥣 Saving manual recipe");
                      print("recipeCode = ${selectedRecipe?.recipeCode}");
                      print("mealSlot = ${selectedMealType.toLowerCase()}");
                      print("quantity = ${quantityController.text.trim()}");

                      await _dietRecallRepository.logViaSearchChoose(
                        recipeCode: selectedRecipe?.recipeCode ?? "",
                        mealSlot: selectedMealType.toLowerCase(),
                        quantity: quantityController.text.trim(),
                        planId: planId ?? "",
                        date: targetDateString,
                        unit: recipeUnits.isNotEmpty ? recipeUnits.first : "g",
                      );

                      print("✅ Manual recipe saved");
                    }
                  } else if (isImage && preMealImage != null) {
                    print("📷 Saving image meal");

                    await _dietRecallRepository.logViaSearchChoose(
                      recipeCode: selectedRecipe?.recipeCode ?? "",
                      mealSlot: selectedMealType.toLowerCase(),
                      quantity: quantityController.text.trim(),
                      planId: planId ?? "",
                      date: targetDateString,
                    );

                    print("✅ Image meal saved");
                  }

                  print("🎉 Save completed successfully");

                  if (!mounted) return;

                  AppSnackBar.show(
                    context,
                    message: "Meal Logged successfully",
                    type: SnackBarType.success,
                  );

                  print("🔄 Fetching recall");

                  await _fetchRecall(selectedDate);

                  print("🧹 Clearing form");

                  setState(() {
                    searchController.clear();
                    quantityController.text = "1";
                    selectedRecipe = null;
                    selectedMeals.clear();
                    selectedMealGroups.clear();
                    preMealImage = null;
                    postMealImage = null;
                  });

                  print("✅ Done");
                } catch (e, st) {
                  print("❌ ERROR");
                  print(e);
                  print(st);

                  AppSnackBar.show(
                    context,
                    message: "Failed to save: $e",
                    type: SnackBarType.error,
                  );
                } finally {
                  print("🏁 Finally block");

                  if (mounted) {
                    setState(() => _isSaving = false);
                  }

                  print("========================================");
                }
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF007A50),
          disabledBackgroundColor: const Color(0xFF007A50).withOpacity(0.6),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: _isSaving
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : const Text(
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              decoration: BoxDecoration(
                color: selected ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : [],
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      icon,
                      key: ValueKey<bool>(selected),
                      size: 19,
                      color: selected
                          ? const Color(0xFF008C5E)
                          : const Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                      color: selected
                          ? const Color(0xFF0F5132)
                          : const Color(0xFF6B7280),
                    ),
                    child: Text(title),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openLoggedItems() async {
    await _fetchRecall(selectedDate);

    if (!mounted) return;

    _showLoggedItems();
  }
}
