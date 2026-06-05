//
// import 'package:adam/data/models/recipe_model.dart';
// import 'package:adam/data/repositories/recipe_repository.dart';
// import 'package:adam/ui/shared_widgets/shimmer.dart';
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
//
//   final List<Recipe> _recipes = [];
//
//   final int _pageSize = 20;
//   int _page = 1;
//
//   bool _isLoading = false;
//   bool _isLoadingMore = false;
//
//   final List<String> _categories = [
//     'All',
//     'Breakfast',
//     'Lunch',
//     'South Indian',
//     'Snacks',
//   ];
//
//   @override
//   void initState() {
//     super.initState();
//     _loadPage(1);
//   }
//
//   // =========================
//   // API CALL (SINGLE SOURCE)
//   // =========================
//   Future<void> _loadPage(int page) async {
//     if (_isLoading) return;
//
//     setState(() {
//       _isLoading = true;
//       _isLoadingMore = true;
//     });
//
//     try {
//       final response = await repository.fetchRecipes(
//         page: page,
//         pageSize: _pageSize,
//       );
//
//       final List<dynamic> data = response['recipes'] ?? [];
//
//       final List<Recipe> fetched = data.map((e) => Recipe.fromJson(e)).toList();
//
//       setState(() {
//         _page = page;
//         _recipes
//           ..clear()
//           ..addAll(fetched);
//
//         _isLoading = false;
//         _isLoadingMore = false;
//       });
//     } catch (e) {
//       setState(() {
//         _isLoading = false;
//         _isLoadingMore = false;
//       });
//       debugPrint("❌ Page load error: $e");
//     }
//   }
//
//   // =========================
//   // FILTER (CLIENT SIDE)
//   // =========================
//   List<Recipe> get _filteredRecipes {
//     return _recipes.where((recipe) {
//       final title = recipe.recipeName.toLowerCase();
//       final code = recipe.recipeCode.toLowerCase();
//       final category = recipe.recipeCategory.toLowerCase();
//
//       final matchesCategory =
//           _activeCategory == 'All' ||
//           category.contains(_activeCategory.toLowerCase());
//
//       final matchesSearch =
//           title.contains(_searchQuery.toLowerCase()) ||
//           code.contains(_searchQuery.toLowerCase());
//
//       return matchesCategory && matchesSearch;
//     }).toList();
//   }
//
//   void _onSearchChanged(String value) {
//     setState(() {
//       _searchQuery = value;
//     });
//
//     if (value.isEmpty) {
//       _isSearching = false;
//       _loadPage(1); // back to normal API
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
//
//       final List<dynamic> data = response['recipes'] ?? [];
//
//       final List<Recipe> fetched = data.map((e) => Recipe.fromJson(e)).toList();
//
//       setState(() {
//         if (page == 1) {
//           _recipes.clear();
//         }
//
//         _recipes.addAll(fetched);
//         _page = page;
//
//         _isLoading = false;
//         _isLoadingMore = false;
//       });
//     } catch (e) {
//       setState(() {
//         _isLoading = false;
//         _isLoadingMore = false;
//       });
//
//       debugPrint("❌ Search error: $e");
//     }
//   }
//
//   void _onCategoryChanged(String value) {
//     setState(() => _activeCategory = value);
//   }
//
//   // =========================
//   // PAGE CONTROLS
//   // =========================
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
//   @override
//   Widget build(BuildContext context) {
//     final filtered = _filteredRecipes;
//
//     return Scaffold(
//       backgroundColor: const Color(0xFFFAFAFA),
//
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
//
//       body: _isLoading && _recipes.isEmpty
//           ?  Center(child: Shimmer.list())
//           : Padding(
//               padding: const EdgeInsets.all(16),
//               child: Column(
//                 children: [
//                   // SEARCH
//                   TextField(
//                     onChanged: _onSearchChanged,
//                     decoration: InputDecoration(
//                       hintText: 'Search recipes...',
//                       prefixIcon: const Icon(Icons.search),
//                       filled: true,
//                       fillColor: const Color(0xFFF1F1F1),
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(12),
//                         borderSide: BorderSide.none,
//                       ),
//                     ),
//                   ),
//
//                   const SizedBox(height: 16),
//
//                   // CATEGORY
//                   SizedBox(
//                     height: 40,
//                     child: ListView.builder(
//                       scrollDirection: Axis.horizontal,
//                       itemCount: _categories.length,
//                       itemBuilder: (context, index) {
//                         final cat = _categories[index];
//                         final selected = _activeCategory == cat;
//
//                         return GestureDetector(
//                           onTap: () => _onCategoryChanged(cat),
//                           child: Container(
//                             margin: const EdgeInsets.only(right: 8),
//                             padding: const EdgeInsets.symmetric(
//                               horizontal: 16,
//                               vertical: 10,
//                             ),
//                             decoration: BoxDecoration(
//                               color: selected
//                                   ? const Color(0xFF0F5132)
//                                   : Colors.white,
//                               borderRadius: BorderRadius.circular(20),
//                               border: Border.all(color: Colors.grey.shade300),
//                             ),
//                             child: Text(
//                               cat,
//                               style: TextStyle(
//                                 color: selected ? Colors.white : Colors.black,
//                               ),
//                             ),
//                           ),
//                         );
//                       },
//                     ),
//                   ),
//
//                   const SizedBox(height: 20),
//
//                   // LIST
//                   Expanded(
//                     child: filtered.isEmpty
//                         ? const Center(child: Text("No recipes found"))
//                         : ListView.builder(
//                             itemCount: filtered.length,
//                             itemBuilder: (context, index) {
//                               final recipe = filtered[index];
//
//                               return _buildRecipeCard(
//                                 context,
//                                 imageUrl:
//                                     'https://datatools.sjri.res.in/static/VD/food_images_large/${recipe.recipeCode}.jpg',
//                                 title: recipe.recipeName,
//                                 subtitle: recipe.recipeCode,
//                                 prepTime: '20 mins',
//                                 tags: [
//                                   {
//                                     'label': recipe.recipeCategory,
//                                     'color': const Color(0xFFE5EEF9),
//                                     'textColor': const Color(0xFF5C84C3),
//                                   },
//                                 ],
//                               );
//                             },
//                           ),
//                   ),
//
//                   const SizedBox(height: 10),
//
//                   // PAGE CONTROLS (IMPORTANT PART)
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       IconButton(
//                         onPressed: _page > 1 ? _prevPage : null,
//                         icon: const Icon(Icons.arrow_back_ios),
//                       ),
//
//                       Text(
//                         "Page $_page",
//                         style: const TextStyle(
//                           fontWeight: FontWeight.bold,
//                           fontSize: 16,
//                         ),
//                       ),
//
//                       IconButton(
//                         onPressed: _nextPage,
//                         icon: const Icon(Icons.arrow_forward_ios),
//                       ),
//                     ],
//                   ),
//
//                   if (_isLoadingMore)
//                     Padding(
//                       padding: const EdgeInsets.only(top: 8),
//                       child: Shimmer.list(),
//                     ),
//                 ],
//               ),
//             ),
//     );
//   }
//
//   Widget _buildRecipeCard(
//     BuildContext context, {
//     required String imageUrl,
//     required String title,
//     required String subtitle,
//     required String prepTime,
//     required List<Map<String, dynamic>> tags,
//   }) {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(color: const Color(0xFFE5E7EB)),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           ClipRRect(
//             borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
//             child: Image.network(
//               imageUrl,
//               height: 160,
//               width: double.infinity,
//               fit: BoxFit.cover,
//             ),
//           ),
//           Padding(
//             padding: const EdgeInsets.all(14),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   title,
//                   style: const TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 const SizedBox(height: 6),
//                 Text(subtitle, style: const TextStyle(color: Colors.grey)),
//                 const SizedBox(height: 10),
//                 Text(prepTime),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
import 'package:adam/data/models/recipe_model.dart';
import 'package:adam/data/repositories/recipe_repository.dart';
import 'package:adam/ui/shared_widgets/shimmer.dart';
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

  final List<String> _categories = [
    'All',
    'Breakfast',
    'Lunch',
    'South Indian',
    'Snacks',
  ];

  @override
  void initState() {
    super.initState();
    _loadPage(1);
  }

  // =========================
  // API CALL (SINGLE SOURCE)
  // =========================
  Future<void> _loadPage(int page) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await repository.fetchRecipes(
        page: page,
        pageSize: _pageSize,
      );

      final List<dynamic> data = response['recipes'] ?? [];
      final List<Recipe> fetched = data.map((e) => Recipe.fromJson(e)).toList();

      setState(() {
        _page = page;
        _recipes
          ..clear()
          ..addAll(fetched);

        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint("❌ Page load error: $e");
    }
  }

  // =========================
  // FILTER (CLIENT SIDE)
  // =========================
  List<Recipe> get _filteredRecipes {
    return _recipes.where((recipe) {
      final title = recipe.recipeName.toLowerCase();
      final code = recipe.recipeCode.toLowerCase();
      final category = recipe.recipeCategory.toLowerCase();

      final matchesCategory =
          _activeCategory == 'All' ||
              category.contains(_activeCategory.toLowerCase());

      final matchesSearch =
          title.contains(_searchQuery.toLowerCase()) ||
              code.contains(_searchQuery.toLowerCase());

      return matchesCategory && matchesSearch;
    }).toList();
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value;
    });

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
        if (page == 1) {
          _recipes.clear();
        }

        _recipes.addAll(fetched);
        _page = page;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint("❌ Search error: $e");
    }
  }

  void _onCategoryChanged(String value) {
    setState(() => _activeCategory = value);
  }

  // =========================
  // PAGE CONTROLS
  // =========================
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
            // SEARCH BAR
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

            // CATEGORY SELECTOR
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

            // DYNAMIC LIST CONTAINER
            Expanded(
              child: _isLoading
                  ? Shimmer.list() // Shows shimmer immediately when loading pages
                  : filtered.isEmpty
                  ? const Center(child: Text("No recipes found"))
                  : ListView.builder(
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final recipe = filtered[index];

                  return _buildRecipeCard(
                    context,
                    imageUrl:
                    'https://datatools.sjri.res.in/static/VD/food_images_large/${recipe.recipeCode}.jpg',
                    title: recipe.recipeName,
                    subtitle: recipe.recipeCode,
                    prepTime: '20 mins',
                    tags: [
                      {
                        'label': recipe.recipeCategory,
                        'color': const Color(0xFFE5EEF9),
                        'textColor': const Color(0xFF5C84C3),
                      },
                    ],
                  );
                },
              ),
            ),

            const SizedBox(height: 10),

            // PAGE CONTROLS
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
        required String imageUrl,
        required String title,
        required String subtitle,
        required String prepTime,
        required List<Map<String, dynamic>> tags,
      }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Image.network(
              imageUrl,
              height: 160,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(subtitle, style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 10),
                Text(prepTime),
              ],
            ),
          ),
        ],
      ),
    );
  }
}