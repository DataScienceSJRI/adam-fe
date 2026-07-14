// import 'package:adam/data/models/recipe_model.dart';
// import 'package:adam/data/repositories/recipe_repository.dart';
// import 'package:adam/ui/utils/shimmer.dart';
// import 'package:flutter/material.dart';
//
// class RecipesScreen extends StatefulWidget {
//   const RecipesScreen({super.key});
//
//   @override
//   State<RecipesScreen> createState() => _RecipesScreenState();
// }
//
// class _RecipesScreenState extends State<RecipesScreen> {
//   bool _isSearching = false;
//   String _activeCategory = 'All';
//   String _searchQuery = '';
//
//   final RecipeRepository repository = RecipeRepository();
//   final List<Recipe> _recipes = [];
//   final int _pageSize = 20;
//   int _page = 1;
//   bool _isLoading = false;
//
//   final List<String> _categories = ['All', 'Liked', 'Disliked'];
//   Map<String, bool?> recipeReactions = {};
//
//   @override
//   void initState() {
//     super.initState();
//     _loadPage(1);
//   }
//
//   Future<void> _loadPage(int page) async {
//     if (_isLoading) return;
//     setState(() => _isLoading = true);
//
//     try {
//       final response = await repository.fetchRecipes(
//         page: page,
//         pageSize: _pageSize,
//       );
//       final List<dynamic> data = response['recipes'] ?? [];
//       final List<Recipe> fetched = data.map((e) => Recipe.fromJson(e)).toList();
//
//       setState(() {
//         _page = page;
//         _recipes
//           ..clear()
//           ..addAll(fetched);
//         _isLoading = false;
//       });
//     } catch (e) {
//       setState(() => _isLoading = false);
//       debugPrint("❌ Page load error: $e");
//     }
//   }
//
//   List<Recipe> get _filteredRecipes {
//     return _recipes.where((recipe) {
//       final title = recipe.recipeName.toLowerCase();
//       final code = recipe.recipeCode.toLowerCase();
//       final category = recipe.recipeCategory.toLowerCase();
//
//       final matchesCategory =
//           _activeCategory == 'All' ||
//           category.contains(_activeCategory.toLowerCase());
//       final matchesSearch =
//           title.contains(_searchQuery.toLowerCase()) ||
//           code.contains(_searchQuery.toLowerCase());
//
//       return matchesCategory && matchesSearch;
//     }).toList();
//   }
//
//   void _onSearchChanged(String value) {
//     setState(() => _searchQuery = value);
//     if (value.isEmpty) {
//       _isSearching = false;
//       _loadPage(1);
//     } else {
//       _searchRecipes(value, 1);
//     }
//   }
//
//   Future<void> _searchRecipes(String query, int page) async {
//     setState(() {
//       _isLoading = true;
//       _isSearching = true;
//     });
//
//     try {
//       final response = await repository.searchRecipes(
//         query: query,
//         page: page,
//         pageSize: _pageSize,
//       );
//       final List<dynamic> data = response['recipes'] ?? [];
//       final List<Recipe> fetched = data.map((e) => Recipe.fromJson(e)).toList();
//
//       setState(() {
//         if (page == 1) _recipes.clear();
//         _recipes.addAll(fetched);
//         _page = page;
//         _isLoading = false;
//       });
//     } catch (e) {
//       setState(() => _isLoading = false);
//       debugPrint("❌ Search error: $e");
//     }
//   }
//
//   void _onCategoryChanged(String value) {
//     setState(() => _activeCategory = value);
//   }
//
//   void _nextPage() {
//     if (_isSearching) {
//       _searchRecipes(_searchQuery, _page + 1);
//     } else {
//       _loadPage(_page + 1);
//     }
//   }
//
//   void _prevPage() {
//     if (_page > 1) {
//       if (_isSearching) {
//         _searchRecipes(_searchQuery, _page - 1);
//       } else {
//         _loadPage(_page - 1);
//       }
//     }
//   }
//
//   void _showIngredientsBottomSheet(BuildContext context, Recipe recipe) {
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
//       ),
//       builder: (context) {
//         return FutureBuilder<List<Map<String, dynamic>>>(
//           future: repository.fetchIngredients(recipe.recipeCode),
//           builder: (context, snapshot) {
//             if (snapshot.connectionState == ConnectionState.waiting) {
//               return const SizedBox(
//                 height: 250,
//                 child: Center(
//                   child: Column(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       SizedBox(
//                         width: 28,
//                         height: 28,
//                         child: CircularProgressIndicator(
//                           color: Color(0xFF0F5132),
//                           strokeWidth: 3,
//                         ),
//                       ),
//                       SizedBox(height: 16),
//                       Text(
//                         "Gathering ingredients...",
//                         style: TextStyle(color: Colors.grey, fontSize: 14),
//                       ),
//                     ],
//                   ),
//                 ),
//               );
//             }
//
//             if (snapshot.hasError ||
//                 snapshot.data == null ||
//                 snapshot.data!.isEmpty) {
//               return const SizedBox(
//                 height: 200,
//                 child: Center(
//                   child: Text(
//                     "No ingredients details found for this recipe.",
//                     style: TextStyle(color: Colors.grey),
//                   ),
//                 ),
//               );
//             }
//
//             final ingredients = snapshot.data!;
//
//             ingredients.sort((a, b) {
//               double getDoubleValue(dynamic rawQty) {
//                 if (rawQty == null) return 0.0;
//                 if (rawQty is num) return rawQty.toDouble();
//                 if (rawQty is String) return double.tryParse(rawQty) ?? 0.0;
//                 return 0.0;
//               }
//
//               return getDoubleValue(
//                 b['Ing_raw_amounts_g'],
//               ).compareTo(getDoubleValue(a['Ing_raw_amounts_g']));
//             });
//
//             return ConstrainedBox(
//               constraints: BoxConstraints(
//                 maxHeight: MediaQuery.of(context).size.height * 0.75,
//               ),
//               child: Padding(
//                 padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Center(
//                       child: Container(
//                         width: 40,
//                         height: 4,
//                         margin: const EdgeInsets.only(bottom: 16),
//                         decoration: BoxDecoration(
//                           color: Colors.grey.shade300,
//                           borderRadius: BorderRadius.circular(2),
//                         ),
//                       ),
//                     ),
//                     Text(
//                       recipe.recipeName,
//                       style: const TextStyle(
//                         fontSize: 20,
//                         fontWeight: FontWeight.bold,
//                         color: Color(0xFF0F5132),
//                       ),
//                     ),
//                     const SizedBox(height: 12),
//                     const Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         Text(
//                           "Ingredients List",
//                           style: TextStyle(
//                             color: Colors.grey,
//                             fontWeight: FontWeight.w500,
//                             fontSize: 13,
//                           ),
//                         ),
//                         Text(
//                           "Quantity in Grams",
//                           style: TextStyle(
//                             color: Colors.grey,
//                             fontWeight: FontWeight.w500,
//                             fontSize: 13,
//                           ),
//                         ),
//                       ],
//                     ),
//                     const Divider(height: 20, thickness: 1),
//                     Flexible(
//                       child: ListView.builder(
//                         shrinkWrap: true,
//                         physics: const BouncingScrollPhysics(),
//                         itemCount: ingredients.length,
//                         itemBuilder: (context, idx) {
//                           final item = ingredients[idx];
//                           final name =
//                               item['Ingredients'] ?? 'Unknown Ingredient';
//                           final rawQty = item['Ing_raw_amounts_g'];
//                           String qty = '0';
//
//                           if (rawQty != null) {
//                             double? parsedValue;
//                             if (rawQty is num) parsedValue = rawQty.toDouble();
//                             if (rawQty is String)
//                               parsedValue = double.tryParse(rawQty);
//                             qty = parsedValue != null
//                                 ? parsedValue.ceil().toString()
//                                 : rawQty.toString();
//                           }
//
//                           final delayMs = (idx * 60).clamp(0, 600);
//
//                           return TweenAnimationBuilder<double>(
//                             tween: Tween<double>(begin: 0.0, end: 1.0),
//                             curve: Curves.easeOutCubic,
//                             duration: Duration(milliseconds: 400 + delayMs),
//                             builder: (context, animationValue, child) {
//                               final double slideTranslation =
//                                   24.0 * (1.0 - animationValue);
//                               return Opacity(
//                                 opacity: animationValue,
//                                 child: Transform.translate(
//                                   offset: Offset(0.0, slideTranslation),
//                                   child: child,
//                                 ),
//                               );
//                             },
//                             child: Padding(
//                               padding: const EdgeInsets.symmetric(
//                                 vertical: 8.0,
//                               ),
//                               child: Row(
//                                 children: [
//                                   Container(
//                                     width: 6,
//                                     height: 6,
//                                     decoration: const BoxDecoration(
//                                       color: Color(0xFF0F5132),
//                                       shape: BoxShape.circle,
//                                     ),
//                                   ),
//                                   const SizedBox(width: 14),
//                                   Expanded(
//                                     child: Text(
//                                       name.isNotEmpty
//                                           ? '${name[0].toUpperCase()}${name.substring(1)}'
//                                           : '',
//                                       style: const TextStyle(
//                                         fontSize: 15,
//                                         fontWeight: FontWeight.w500,
//                                         color: Color(0xFF1F2937),
//                                       ),
//                                     ),
//                                   ),
//                                   Container(
//                                     padding: const EdgeInsets.symmetric(
//                                       horizontal: 10,
//                                       vertical: 4,
//                                     ),
//                                     decoration: BoxDecoration(
//                                       color: const Color(0xFFF3F4F6),
//                                       borderRadius: BorderRadius.circular(8),
//                                     ),
//                                     child: Text(
//                                       "${qty}g",
//                                       style: const TextStyle(
//                                         fontSize: 13,
//                                         fontWeight: FontWeight.bold,
//                                         color: Color(0xFF374151),
//                                       ),
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           );
//                         },
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             );
//           },
//         );
//       },
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final filtered = _filteredRecipes;
//
//     return Scaffold(
//       backgroundColor: const Color(0xFFFAFAFA),
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         centerTitle: true,
//         elevation: 0,
//         title: const Text(
//           'RECIPES',
//           style: TextStyle(
//             color: Color(0xFF0F5132),
//             fontSize: 24,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           children: [
//             TextField(
//               onChanged: _onSearchChanged,
//               decoration: InputDecoration(
//                 hintText: 'Search recipes...',
//                 prefixIcon: const Icon(Icons.search),
//                 filled: true,
//                 fillColor: const Color(0xFFF1F1F1),
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(12),
//                   borderSide: BorderSide.none,
//                 ),
//               ),
//             ),
//             const SizedBox(height: 16),
//             SizedBox(
//               height: 40,
//               child: ListView.builder(
//                 scrollDirection: Axis.horizontal,
//                 itemCount: _categories.length,
//                 itemBuilder: (context, index) {
//                   final cat = _categories[index];
//                   final selected = _activeCategory == cat;
//
//                   return GestureDetector(
//                     onTap: () => _onCategoryChanged(cat),
//                     child: Container(
//                       margin: const EdgeInsets.only(right: 8),
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 16,
//                         vertical: 10,
//                       ),
//                       decoration: BoxDecoration(
//                         color: selected
//                             ? const Color(0xFF0F5132)
//                             : Colors.white,
//                         borderRadius: BorderRadius.circular(20),
//                         border: Border.all(color: Colors.grey.shade300),
//                       ),
//                       child: Text(
//                         cat,
//                         style: TextStyle(
//                           color: selected ? Colors.white : Colors.black,
//                         ),
//                       ),
//                     ),
//                   );
//                 },
//               ),
//             ),
//             const SizedBox(height: 20),
//             Expanded(
//               child: _isLoading
//                   ? Shimmer.list()
//                   : filtered.isEmpty
//                   ? const Center(child: Text("No recipes found"))
//                   : GridView.builder(
//                       padding: const EdgeInsets.only(bottom: 16),
//                       gridDelegate:
//                           const SliverGridDelegateWithFixedCrossAxisCount(
//                             crossAxisCount: 2,
//                             crossAxisSpacing: 12,
//                             mainAxisSpacing: 12,
//                             childAspectRatio: 0.95,
//                           ),
//                       itemCount: filtered.length,
//                       itemBuilder: (context, index) {
//                         final recipe = filtered[index];
//
//                         return _buildRecipeCard(
//                           context,
//                           imageUrl:
//                               'https://datatools.sjri.res.in/static/VD/food_images_large/${recipe.recipeCode}.jpg',
//                           title: recipe.recipeName,
//                           onTap: () =>
//                               _showIngredientsBottomSheet(context, recipe),
//                           isLiked: recipeReactions[recipe.recipeCode],
//                           onReactionChanged: (newStatus) {
//                             setState(() {
//                               recipeReactions[recipe.recipeCode] = newStatus;
//                             });
//                           },
//                           recipeCode: recipe.recipeCode,
//                         );
//                       },
//                     ),
//             ),
//             const SizedBox(height: 10),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 IconButton(
//                   onPressed: !_isLoading && _page > 1 ? _prevPage : null,
//                   icon: const Icon(Icons.arrow_back_ios),
//                 ),
//                 Text(
//                   "Page $_page",
//                   style: const TextStyle(
//                     fontWeight: FontWeight.bold,
//                     fontSize: 16,
//                   ),
//                 ),
//                 IconButton(
//                   onPressed: !_isLoading ? _nextPage : null,
//                   icon: const Icon(Icons.arrow_forward_ios),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   // Widget _buildRecipeCard(
//   //   BuildContext context, {
//   //   required String imageUrl,
//   //   required String title,
//   //   required VoidCallback onTap,
//   // }) {
//   //   return InkWell(
//   //     onTap: onTap,
//   //     borderRadius: BorderRadius.circular(16),
//   //     child: Container(
//   //       decoration: BoxDecoration(
//   //         color: Colors.white,
//   //         borderRadius: BorderRadius.circular(16),
//   //         border: Border.all(color: const Color(0xFFE5E7EB)),
//   //       ),
//   //       child: Column(
//   //         crossAxisAlignment: CrossAxisAlignment.start,
//   //         children: [
//   //           Expanded(
//   //             child: SizedBox(
//   //               width: double.infinity,
//   //               child: ClipRRect(
//   //                 borderRadius: const BorderRadius.vertical(
//   //                   top: Radius.circular(15),
//   //                 ),
//   //                 child: Image.network(
//   //                   imageUrl,
//   //                   fit: BoxFit.cover,
//   //                   errorBuilder: (context, error, stackTrace) {
//   //                     return Container(
//   //                       color: Colors.grey.shade200,
//   //                       child: const Icon(
//   //                         Icons.broken_image,
//   //                         color: Colors.grey,
//   //                       ),
//   //                     );
//   //                   },
//   //                 ),
//   //               ),
//   //             ),
//   //           ),
//   //
//   //           Padding(
//   //             padding: const EdgeInsets.all(10),
//   //             child: Column(
//   //               crossAxisAlignment: CrossAxisAlignment.start,
//   //               mainAxisSize: MainAxisSize.min,
//   //               children: [
//   //                 Text(
//   //                   title,
//   //                   maxLines: 2,
//   //                   overflow: TextOverflow.ellipsis,
//   //                   style: const TextStyle(
//   //                     fontSize: 14,
//   //                     fontWeight: FontWeight.bold,
//   //                   ),
//   //                 ),
//   //               ],
//   //             ),
//   //           ),
//   //         ],
//   //       ),
//   //     ),
//   //   );
//   // }
//   Widget _buildRecipeCard(
//     BuildContext context, {
//     required String recipeCode,
//     required String imageUrl,
//     required String title,
//     required VoidCallback onTap,
//     bool? isLiked, // true if liked, false if disliked, null if no action taken
//     required Function(bool? newStatus)
//     onReactionChanged, // Callback to update state in your UI
//   }) {
//     final RecipeRepository repository = RecipeRepository();
//
//     // Unified handler to toggle likes/dislikes utilizing your repository layer
//     Future<void> handleReaction(bool targetLike) async {
//       // Optimistic UI updates feel instant and fluid
//       bool? originalState = isLiked;
//       bool isRemovingReaction =
//           (targetLike && isLiked == true) || (!targetLike && isLiked == false);
//
//       onReactionChanged(isRemovingReaction ? null : targetLike);
//
//       try {
//         if (isRemovingReaction) {
//           // Handle un-reacting if your backend supports a toggle or fallback,
//           // otherwise default fires the target action below.
//         }
//
//         if (targetLike) {
//           await repository.likeRecipe(recipeCode);
//         } else {
//           await repository.dislikeRecipe(recipeCode);
//         }
//       } catch (e) {
//         // Revert state if the network request fails gracefully
//         onReactionChanged(originalState);
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text("Action failed: ${e.toString()}")),
//         );
//       }
//     }
//
//     return Container(
//       margin: const EdgeInsets.all(6),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(20),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.04),
//             blurRadius: 12,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: ClipRRect(
//         borderRadius: BorderRadius.circular(20),
//         child: Material(
//           color: Colors.transparent,
//           child: InkWell(
//             onTap: onTap,
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // Media & Overlay Section
//                 Expanded(
//                   child: Stack(
//                     children: [
//                       Positioned.fill(
//                         child: Image.network(
//                           imageUrl,
//                           fit: BoxFit.cover,
//                           errorBuilder: (context, error, stackTrace) {
//                             return Container(
//                               color: const Color(0xFFF3F4F6),
//                               child: const Icon(
//                                 Icons.fastfood_rounded,
//                                 color: Color(0xFF9CA3AF),
//                                 size: 28,
//                               ),
//                             );
//                           },
//                         ),
//                       ),
//
//                       // Subtle dark gradient bottom overlay to lift any background images
//                       Positioned.fill(
//                         child: DecoratedBox(
//                           decoration: BoxDecoration(
//                             gradient: LinearGradient(
//                               begin: Alignment.topCenter,
//                               end: Alignment.bottomCenter,
//                               colors: [
//                                 Colors.transparent,
//                                 Colors.black.withOpacity(0.15),
//                               ],
//                             ),
//                           ),
//                         ),
//                       ),
//
//                       // Premium Floating Like/Dislike Capsule
//                       Positioned(
//                         top: 10,
//                         right: 10,
//                         child: Container(
//                           padding: const EdgeInsets.symmetric(
//                             horizontal: 4,
//                             vertical: 4,
//                           ),
//                           decoration: BoxDecoration(
//                             color: Colors.white.withOpacity(0.92),
//                             borderRadius: BorderRadius.circular(30),
//                             boxShadow: [
//                               BoxShadow(
//                                 color: Colors.black.withOpacity(0.08),
//                                 blurRadius: 8,
//                                 offset: const Offset(0, 2),
//                               ),
//                             ],
//                           ),
//                           child: Row(
//                             mainAxisSize: MainAxisSize.min,
//                             children: [
//                               _buildReactionItem(
//                                 isActive: isLiked == true,
//                                 activeColor: const Color(0xFF10B981),
//                                 // Premium emerald green
//                                 icon: Icons.thumb_up_rounded,
//                                 onTap: () => handleReaction(true),
//                               ),
//                               const SizedBox(width: 2),
//                               _buildReactionItem(
//                                 isActive: isLiked == false,
//                                 activeColor: const Color(0xFFEF4444),
//                                 // Clean rose red
//                                 icon: Icons.thumb_down_rounded,
//                                 onTap: () => handleReaction(false),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//
//                 // Title Section
//                 Padding(
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 12,
//                     vertical: 12,
//                   ),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       Text(
//                         title,
//                         maxLines: 2,
//                         overflow: TextOverflow.ellipsis,
//                         style: const TextStyle(
//                           fontSize: 14,
//                           fontWeight: FontWeight.w700,
//                           color: Color(0xFF1F2937),
//                           // Sophisticated near-black color
//                           height: 1.35,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   // Inline Helper subwidget for microanimated buttons inside your overlay pill
//   Widget _buildReactionItem({
//     required bool isActive,
//     required Color activeColor,
//     required IconData icon,
//     required VoidCallback onTap,
//   }) {
//     return AnimatedContainer(
//       duration: const Duration(milliseconds: 200),
//       curve: Curves.easeInOut,
//       decoration: BoxDecoration(
//         shape: BoxShape.circle,
//         color: isActive ? activeColor.withOpacity(0.12) : Colors.transparent,
//       ),
//       child: Material(
//         color: Colors.transparent,
//         child: InkWell(
//           customBorder: const CircleBorder(),
//           onTap: onTap,
//           child: Padding(
//             padding: const EdgeInsets.all(6.0),
//             child: Icon(
//               icon,
//               size: 16,
//               color: isActive ? activeColor : const Color(0xFF4B5563),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
import 'package:adam/data/models/recipe_model.dart';
import 'package:adam/data/repositories/recipe_repository.dart';
import 'package:adam/ui/utils/shimmer.dart';
import 'package:flutter/material.dart';

class RecipesScreen extends StatefulWidget {
  const RecipesScreen({super.key});

  @override
  State<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends State<RecipesScreen> {
  bool _isSearching = false;
  String _activeCategory = 'All';
  String _searchQuery = '';

  final RecipeRepository repository = RecipeRepository();
  final List<Recipe> _recipes = [];
  final int _pageSize = 20;
  int _page = 1;
  bool _isLoading = false;

  final List<String> _categories = ['All', 'Liked', 'Disliked'];
  Map<String, bool?> recipeReactions = {};

  @override
  void initState() {
    super.initState();
    _loadPage(1);
  }

  Future<void> _loadPage(int page) async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      Map<String, dynamic> response;

      if (_activeCategory == 'Liked') {
        response = await repository.fetchLikedRecipes();
      } else if (_activeCategory == 'Disliked') {
        response = await repository.fetchDislikedRecipes();
      } else {
        response = await repository.fetchRecipes(
          page: page,
          pageSize: _pageSize,
        );
      }

      final List<dynamic> data = response['items'] ?? response['recipes'] ?? [];
      final List<Recipe> fetched = data.map((e) => Recipe.fromJson(e)).toList();

      setState(() {
        _page = page;
        _recipes
          ..clear()
          ..addAll(fetched);

        for (var recipe in fetched) {
          if (_activeCategory == 'Liked') {
            recipeReactions[recipe.recipeCode] = true;
          } else if (_activeCategory == 'Disliked') {
            recipeReactions[recipe.recipeCode] = false;
          }
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint("❌ Page load error: $e");
    }
  }

  List<Recipe> get _filteredRecipes {
    return _recipes.where((recipe) {
      final title = recipe.recipeName.toLowerCase();
      final code = recipe.recipeCode.toLowerCase();

      final matchesSearch =
          title.contains(_searchQuery.toLowerCase()) ||
          code.contains(_searchQuery.toLowerCase());

      return matchesSearch;
    }).toList();
  }

  void _onSearchChanged(String value) {
    setState(() => _searchQuery = value);
    if (value.isEmpty) {
      _isSearching = false;
      _loadPage(1);
    } else {
      _searchRecipes(value, 1);
    }
  }

  Future<void> _searchRecipes(String query, int page) async {
    setState(() {
      _isLoading = true;
      _isSearching = true;
    });

    try {
      final response = await repository.searchRecipes(
        query: query,
        page: page,
        pageSize: _pageSize,
      );
      final List<dynamic> data = response['recipes'] ?? [];
      final List<Recipe> fetched = data.map((e) => Recipe.fromJson(e)).toList();

      setState(() {
        if (page == 1) _recipes.clear();
        _recipes.addAll(fetched);
        _page = page;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint("❌ Search error: $e");
    }
  }

  void _onCategoryChanged(String value) {
    if (_activeCategory == value) return;
    setState(() {
      _activeCategory = value;
      _recipes.clear();
    });
    _loadPage(1);
  }

  void _nextPage() {
    if (_isSearching) {
      _searchRecipes(_searchQuery, _page + 1);
    } else {
      _loadPage(_page + 1);
    }
  }

  void _prevPage() {
    if (_page > 1) {
      if (_isSearching) {
        _searchRecipes(_searchQuery, _page - 1);
      } else {
        _loadPage(_page - 1);
      }
    }
  }

  void _showIngredientsBottomSheet(BuildContext context, Recipe recipe) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return FutureBuilder<List<Map<String, dynamic>>>(
          future: repository.fetchIngredients(recipe.recipeCode),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 250,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                          color: Color(0xFF0F5132),
                          strokeWidth: 3,
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        "Gathering ingredients...",
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (snapshot.hasError ||
                snapshot.data == null ||
                snapshot.data!.isEmpty) {
              return const SizedBox(
                height: 200,
                child: Center(
                  child: Text(
                    "No ingredients details found for this recipe.",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              );
            }

            final ingredients = snapshot.data!;

            ingredients.sort((a, b) {
              double getDoubleValue(dynamic rawQty) {
                if (rawQty == null) return 0.0;
                if (rawQty is num) return rawQty.toDouble();
                if (rawQty is String) return double.tryParse(rawQty) ?? 0.0;
                return 0.0;
              }

              return getDoubleValue(
                b['Ing_raw_amounts_g'],
              ).compareTo(getDoubleValue(a['Ing_raw_amounts_g']));
            });

            return ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.75,
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Text(
                      recipe.recipeName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F5132),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Ingredients List",
                          style: TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          "Quantity in Grams",
                          style: TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 20, thickness: 1),
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        physics: const BouncingScrollPhysics(),
                        itemCount: ingredients.length,
                        itemBuilder: (context, idx) {
                          final item = ingredients[idx];
                          final name =
                              item['Ingredients'] ?? 'Unknown Ingredient';
                          final rawQty = item['Ing_raw_amounts_g'];
                          String qty = '0';

                          if (rawQty != null) {
                            double? parsedValue;
                            if (rawQty is num) parsedValue = rawQty.toDouble();
                            if (rawQty is String)
                              parsedValue = double.tryParse(rawQty);
                            qty = parsedValue != null
                                ? parsedValue.ceil().toString()
                                : rawQty.toString();
                          }

                          final delayMs = (idx * 60).clamp(0, 600);

                          return TweenAnimationBuilder<double>(
                            tween: Tween<double>(begin: 0.0, end: 1.0),
                            curve: Curves.easeOutCubic,
                            duration: Duration(milliseconds: 400 + delayMs),
                            builder: (context, animationValue, child) {
                              final double slideTranslation =
                                  24.0 * (1.0 - animationValue);
                              return Opacity(
                                opacity: animationValue,
                                child: Transform.translate(
                                  offset: Offset(0.0, slideTranslation),
                                  child: child,
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 8.0,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF0F5132),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Text(
                                      name.isNotEmpty
                                          ? '${name[0].toUpperCase()}${name.substring(1)}'
                                          : '',
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF1F2937),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF3F4F6),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      "${qty}g",
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF374151),
                                      ),
                                    ),
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
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredRecipes;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        title: const Text(
          'RECIPES',
          style: TextStyle(
            color: Color(0xFF0F5132),
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search recipes...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: const Color(0xFFF1F1F1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  final selected = _activeCategory == cat;

                  return GestureDetector(
                    onTap: () => _onCategoryChanged(cat),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? const Color(0xFF0F5132)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Text(
                        cat,
                        style: TextStyle(
                          color: selected ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _isLoading
                  ? Shimmer.list()
                  : filtered.isEmpty
                  ? const Center(child: Text("No recipes found"))
                  : GridView.builder(
                      padding: const EdgeInsets.only(bottom: 16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.95,
                          ),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final recipe = filtered[index];

                        return _buildRecipeCard(
                          context,
                          imageUrl:
                              'https://datatools.sjri.res.in/static/VD/food_images_large/${recipe.recipeCode}.jpg',
                          title: recipe.recipeName,
                          onTap: () =>
                              _showIngredientsBottomSheet(context, recipe),
                          isLiked: recipeReactions[recipe.recipeCode],
                          onReactionChanged: (newStatus) {
                            setState(() {
                              recipeReactions[recipe.recipeCode] = newStatus;

                              if (_activeCategory != 'All' &&
                                  newStatus == null) {
                                _recipes.removeWhere(
                                  (r) => r.recipeCode == recipe.recipeCode,
                                );
                              }
                            });
                          },
                          recipeCode: recipe.recipeCode,
                        );
                      },
                    ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: !_isLoading && _page > 1 ? _prevPage : null,
                  icon: const Icon(Icons.arrow_back_ios),
                ),
                Text(
                  "Page $_page",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                IconButton(
                  onPressed: !_isLoading ? _nextPage : null,
                  icon: const Icon(Icons.arrow_forward_ios),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecipeCard(
    BuildContext context, {
    required String recipeCode,
    required String imageUrl,
    required String title,
    required VoidCallback onTap,
    bool? isLiked,
    required Function(bool? newStatus) onReactionChanged,
  }) {
    final RecipeRepository repository = RecipeRepository();

    Future<void> handleReaction(bool targetLike) async {
      bool? originalState = isLiked;
      bool isRemovingReaction =
          (targetLike && isLiked == true) || (!targetLike && isLiked == false);

      onReactionChanged(isRemovingReaction ? null : targetLike);

      try {
        if (targetLike) {
          await repository.likeRecipe(recipeCode);
        } else {
          await repository.dislikeRecipe(recipeCode);
        }
      } catch (e) {
        onReactionChanged(originalState);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Action failed: ${e.toString()}")),
        );
      }
    }

    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            // 1. Full Bleed Background Image Frame
            Positioned.fill(
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: const Color(0xFFF3F4F6),
                    child: const Icon(
                      Icons.restaurant,
                      color: Color(0xFFD1D5DB),
                      size: 32,
                    ),
                  );
                },
              ),
            ),

            // 2. Cinematic Gradient Overlay (Darkens towards the bottom for typography safety)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.0, 0.45, 1.0],
                    colors: [
                      Colors.black.withOpacity(0.2),
                      // Protection for top status row
                      Colors.transparent,
                      Colors.black.withOpacity(0.85),
                      // Solid background for text
                    ],
                  ),
                ),
              ),
            ),

            // 3. Clean Translucent Interaction Layer (Inkwell)
            Positioned.fill(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTap,
                  splashColor: Colors.white.withOpacity(0.1),
                  highlightColor: Colors.white.withOpacity(0.05),
                ),
              ),
            ),

            Positioned(
              top: 12,
              right: 12,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildAestheticActionButton(
                    isActive: isLiked == true,
                    activeColor: const Color(0xFF34D399),
                    // Pastel Emerald
                    icon: Icons.thumb_up_alt_outlined,
                    activeIcon: Icons.thumb_up_alt_rounded,
                    onTap: () => handleReaction(true),
                  ),
                  const SizedBox(width: 6),
                  _buildAestheticActionButton(
                    isActive: isLiked == false,
                    activeColor: const Color(0xFFF87171),
                    // Soft Rose
                    icon: Icons.thumb_down_alt_outlined,
                    activeIcon: Icons.thumb_down_alt_rounded,
                    onTap: () => handleReaction(false),
                  ),
                ],
              ),
            ),

            // 6. Immersive Bottom Text Configuration
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                          letterSpacing: 0.2,
                          shadows: [
                            Shadow(
                              color: Colors.black45,
                              offset: Offset(0, 1),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAestheticActionButton({
    required bool isActive,
    required Color activeColor,
    required IconData icon,
    required IconData activeIcon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isActive ? activeColor : Colors.black.withOpacity(0.35),
          border: Border.all(
            color: isActive
                ? Colors.transparent
                : Colors.white.withOpacity(0.25),
            width: 1,
          ),
        ),
        child: Icon(
          isActive ? activeIcon : icon,
          size: 15,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildReactionItem({
    required bool isActive,
    required Color activeColor,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive ? activeColor.withOpacity(0.12) : Colors.transparent,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(6.0),
            child: Icon(
              icon,
              size: 16,
              color: isActive ? activeColor : const Color(0xFF4B5563),
            ),
          ),
        ),
      ),
    );
  }
}
