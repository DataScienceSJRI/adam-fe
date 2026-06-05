import 'dart:async';
import 'dart:io';

import 'package:adam/data/models/recipe_model.dart';
import 'package:adam/data/repositories/diet_recall_repository.dart';
import 'package:adam/data/repositories/recipe_repository.dart';
import 'package:adam/ui/shared_widgets/custom_snackbar.dart';
import 'package:adam/ui/shared_widgets/shimmer.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

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
  final List<String> mealTypes = ['Breakfast', 'Lunch', 'Dinner', 'Snack'];
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

  @override
  void initState() {
    super.initState();
    isImageSelected = widget.tab;
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    searchController.dispose();
    _debounce?.cancel();
    quantityController.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();

      // No camera found
      if (_cameras.isEmpty) {
        if (mounted) {
          AppSnackBar.show(
            context,
            message:
            "No Camera found on device",
            type: SnackBarType.error,
          );
          // ScaffoldMessenger.of(context).showSnackBar(
          //   const SnackBar(content: Text('No camera found on device')),
          // );
        }
        return;
      }

      // Prefer back camera
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
          message:
          "Camera error: $e",
          type: SnackBarType.error,
        );
        // ScaffoldMessenger.of(
        //   context,
        // ).showSnackBar(SnackBar(content: Text('Camera error: $e')));
      }
    }
  }

  // Future<void> _openCamera({required bool isPreMeal}) async {
  //   await _initializeCamera();
  //
  //   if (_cameraController == null || !_cameraController!.value.isInitialized) {
  //     return;
  //   }
  //
  //   if (!mounted) return;
  //
  //   showModalBottomSheet(
  //     context: context,
  //     isScrollControlled: true,
  //     backgroundColor: Colors.black,
  //     builder: (_) {
  //       return SafeArea(
  //         child: SizedBox(
  //           height: MediaQuery.of(context).size.height * 0.92,
  //           child: Column(
  //             children: [
  //               Expanded(child: CameraPreview(_cameraController!)),
  //
  //               Padding(
  //                 padding: const EdgeInsets.symmetric(vertical: 24),
  //                 child: GestureDetector(
  //                   onTap: () async {
  //                     try {
  //                       if (_cameraController == null ||
  //                           !_cameraController!.value.isInitialized) {
  //                         return;
  //                       }
  //
  //                       if (_cameraController!.value.isTakingPicture) {
  //                         return;
  //                       }
  //
  //                       // ================= TAKE PICTURE =================
  //
  //                       final image = await _cameraController!.takePicture();
  //
  //                       final file = File(image.path);
  //
  //                       debugPrint("IMAGE PATH => ${file.path}");
  //
  //                       setState(() {
  //                         if (isPreMeal) {
  //                           preMealImage = file;
  //                         } else {
  //                           postMealImage = file;
  //                         }
  //                       });
  //
  //                       // ================= UPLOAD TO SUPABASE =================
  //
  //                       debugPrint("UPLOADING IMAGE TO SUPABASE...");
  //
  //                       final imageUrl = await _dietRecallRepository
  //                           .uploadMealImage(
  //                             file: file,
  //                             mealSlot: selectedMealType,
  //                             isPreMeal: isPreMeal,
  //                           );
  //
  //                       debugPrint("SUPABASE URL => $imageUrl");
  //
  //                       // ================= SAVE TO API =================
  //
  //                       debugPrint("CALLING IMAGE RECALL API...");
  //
  //                       await _dietRecallRepository.saveImageRecall(
  //                         imageUrlPre: isPreMeal
  //                             ? imageUrl
  //                             : (preMealImage != null
  //                                   ? await _dietRecallRepository
  //                                         .uploadMealImage(
  //                                           file: preMealImage!,
  //                                           mealSlot: selectedMealType,
  //                                           isPreMeal: true,
  //                                         )
  //                                   : ""),
  //                         imageUrlPost: !isPreMeal ? imageUrl : null,
  //                         mealSlot: selectedMealType.toLowerCase(),
  //                         planId: widget.planId ?? "",
  //                       );
  //
  //                       debugPrint("API SUCCESS");
  //
  //                       if (mounted) {
  //                         Navigator.pop(context);
  //
  //                         ScaffoldMessenger.of(context).showSnackBar(
  //                           const SnackBar(
  //                             content: Text("Meal image uploaded successfully"),
  //                           ),
  //                         );
  //                       }
  //                     } catch (e) {
  //                       debugPrint("UPLOAD ERROR => $e");
  //
  //                       if (mounted) {
  //                         ScaffoldMessenger.of(
  //                           context,
  //                         ).showSnackBar(SnackBar(content: Text("Error: $e")));
  //                       }
  //                     }
  //                   },
  //                   child: Container(
  //                     height: 78,
  //                     width: 78,
  //                     decoration: BoxDecoration(
  //                       shape: BoxShape.circle,
  //                       border: Border.all(color: Colors.white, width: 5),
  //                     ),
  //                   ),
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ),
  //       );
  //     },
  //   );
  // }
  Future<void> _openCamera({required bool isPreMeal}) async {
    await _initializeCamera();
    if (_cameraController == null || !_cameraController!.value.isInitialized)
      return;
    if (!mounted) return;

    // Use a local state variable for the loader
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
                              // Inside _openCamera -> GestureDetector -> onTap
                              onTap: () async {
                                setSheetState(() => isUploading = true);
                                try {
                                  final image = await _cameraController!
                                      .takePicture();
                                  final file = File(image.path);

                                  // 1. UPLOAD IMAGE
                                  final imageUrl = await _dietRecallRepository
                                      .uploadMealImage(
                                        file: file,
                                        mealSlot: selectedMealType,
                                        isPreMeal: isPreMeal,
                                      );

                                  // 2. SAVE TO API
                                  await _dietRecallRepository.saveImageRecall(
                                    imageUrlPre: isPreMeal ? imageUrl : "",
                                    imageUrlPost: !isPreMeal ? imageUrl : null,
                                    mealSlot: selectedMealType.toLowerCase(),
                                    planId: widget.planId ?? "",
                                  );

                                  // 3. IMPORTANT: Update the Main State so the UI refreshes
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
                                    Navigator.pop(
                                      context,
                                    ); // Close the bottom sheet
                                  }
                                } catch (e) {
                                  setSheetState(() => isUploading = false);
                                  // Handle error
                                }
                              },
                              // onTap: () async {
                              //   // Trigger loader
                              //   setSheetState(() => isUploading = true);
                              //   try {
                              //     final image = await _cameraController!.takePicture();
                              //     final file = File(image.path);
                              //
                              //     // Upload logic
                              //     final imageUrl = await _dietRecallRepository.uploadMealImage(
                              //       file: file,
                              //       mealSlot: selectedMealType,
                              //       isPreMeal: isPreMeal,
                              //     );
                              //
                              //     await _dietRecallRepository.saveImageRecall(
                              //       imageUrlPre: isPreMeal ? imageUrl : "",
                              //       imageUrlPost: !isPreMeal ? imageUrl : null,
                              //       mealSlot: selectedMealType.toLowerCase(),
                              //       planId: widget.planId ?? "",
                              //     );
                              //
                              //     if (mounted) Navigator.pop(context);
                              //   } catch (e) {
                              //     setSheetState(() => isUploading = false);
                              //     // Handle error...
                              //   }
                              // },
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

      // CHANGE THESE BASED ON YOUR API RESPONSE
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

      // ================= APP BAR =================
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

            // ================= CONDITIONAL UI =================
            isImageSelected ? _buildImageUI() : _buildSearchChooseUI(),
          ],
        ),
      ),
    );
  }

  // ================= IMAGE UI =================
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

        // ================= PRE MEAL CAMERA =================
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

        // ================= POST MEAL CAMERA =================
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

        // _saveButton(),
      ],
    );
  }

  // ================= SEARCH UI =================
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
                        onTap: () {
                          searchController.text = recipe.recipeName;

                          FocusScope.of(context).unfocus();

                          setState(() {
                            selectedRecipe = recipe;
                            searchedRecipes.clear();
                          });
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
                // width: 90,
                child: TextField(
                  controller: quantityController,
                  keyboardType: TextInputType.number,

                  decoration: InputDecoration(
                    hintText: '1',

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

              Center(
                child: GestureDetector(
                  onTap: () {},
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.add_circle_outline,
                        color: Color(0xFF008C5E),
                        size: 20,
                      ),

                      SizedBox(width: 8),

                      Text(
                        'Add another item',
                        style: TextStyle(
                          color: Color(0xFF008C5E),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 34),

        // _saveButton(),
      ],
    );
  }

  // Widget _saveButton() {
  //   return SizedBox(
  //     width: double.infinity,
  //     height: 58,
  //     child: ElevatedButton(
  //       onPressed: () async {
  //         try {
  //           ScaffoldMessenger.of(context).showSnackBar(
  //             const SnackBar(
  //               content: Text(
  //                 "Your Image has been sent to out team , you'll br notified once it's processed",
  //               ),
  //             ),
  //           );
  //
  //           await _dietRecallRepository.logViaSearchChoose(
  //             recipeCode: selectedRecipe!.recipeCode,
  //             mealSlot: selectedMealType.toLowerCase(),
  //             quantity: quantityController.text.trim(),
  //             didEatAsPlanned: false,
  //             planId: widget.planId ?? "",
  //           );
  //
  //           if (!mounted) return;
  //
  //           ScaffoldMessenger.of(context).showSnackBar(
  //             const SnackBar(content: Text("Meal logged successfully")),
  //           );
  //
  //           setState(() {
  //             searchController.clear();
  //             quantityController.text = "1";
  //             selectedRecipe = null;
  //           });
  //         } catch (e, stackTrace) {
  //           debugPrint("DETAILED ERROR: $e");
  //           debugPrint("STACK TRACE: $stackTrace");
  //           ScaffoldMessenger.of(context).showSnackBar(
  //             SnackBar(content: Text("Failed to save: $e")), // This shows the actual error message
  //           );
  //         }
  //       },
  //       style: ElevatedButton.styleFrom(
  //         backgroundColor: const Color(0xFF007A50),
  //         elevation: 0,
  //         shape: RoundedRectangleBorder(
  //           borderRadius: BorderRadius.circular(14),
  //         ),
  //       ),
  //       child: const Text(
  //         'Save meal log',
  //         style: TextStyle(
  //           fontSize: 17,
  //           fontWeight: FontWeight.w600,
  //           color: Colors.white,
  //         ),
  //       ),
  //     ),
  //   );
  // }

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
