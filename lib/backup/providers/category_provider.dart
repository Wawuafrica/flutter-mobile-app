import 'package:logger/logger.dart';
import '../models/category.dart';
import '../services/api_service.dart';
import 'base_provider.dart';

class CategoryProvider extends BaseProvider {
  final ApiService _apiService;
  final Logger _logger;

  List<Category> _categories = [];
  Category? _selectedCategory;

  List<Category> get categories => _categories;
  Category? get selectedCategory => _selectedCategory;

  CategoryProvider({required ApiService apiService, required Logger logger})
    : _apiService = apiService,
      _logger = logger,
      super();

  Future<void> fetchAllCategories({String? type}) async {
    await handleAsync(() async {
      _logger.i('Fetching all categories, type: $type');
      final queryParams = <String, dynamic>{};
      if (type != null && type.isNotEmpty) {
        queryParams['type'] = type;
      }

      final response = await _apiService.get(
        '/categories',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      if (response != null && response['data'] is List) {
        _categories =
            (response['data'] as List)
                .map(
                  (categoryJson) =>
                      Category.fromJson(categoryJson as Map<String, dynamic>),
                )
                .toList();
        _logger.i('Fetched ${_categories.length} categories.');
        return _categories;
      } else {
        _logger.w(
          'Fetch all categories response missing data or not a list: $response',
        );
        _categories = [];
        throw Exception(
          'Failed to fetch categories: Invalid response structure',
        );
      }
    }, errorMessage: 'Failed to fetch categories');
  }

  Future<void> fetchCategoryById(String categoryId) async {
    await handleAsync(() async {
      _logger.i('Fetching category by ID: $categoryId');
      final response = await _apiService.get('/categories/$categoryId');

      if (response != null && response['data'] != null) {
        _selectedCategory = Category.fromJson(
          response['data'] as Map<String, dynamic>,
        );
        _logger.i('Fetched category: ${_selectedCategory?.name}');
        return _selectedCategory;
      } else {
        _logger.w('Fetch category by ID response missing data: $response');
        _selectedCategory = null;
        throw Exception('Failed to fetch category: Invalid response structure');
      }
    }, errorMessage: 'Failed to fetch category details');
  }

  Future<Category?> createCategory(Map<String, dynamic> categoryData) async {
    Category? createdCategory;
    await handleAsync(() async {
      _logger.i('Creating category with data: $categoryData');
      final response = await _apiService.post(
        '/categories',
        data: categoryData,
      );

      if (response != null && response['data'] != null) {
        createdCategory = Category.fromJson(
          response['data'] as Map<String, dynamic>,
        );
        _logger.i('Category created: ${createdCategory?.name}');
        _categories.add(createdCategory!);
        notifyListeners();
        return createdCategory;
      } else {
        _logger.w('Create category response missing data: $response');
        throw Exception(
          'Failed to create category: Invalid response structure',
        );
      }
    }, errorMessage: 'Failed to create category');
    return createdCategory;
  }

  Future<Category?> updateCategory(
    String categoryId,
    Map<String, dynamic> categoryData,
  ) async {
    Category? updatedCategory;
    await handleAsync(() async {
      _logger.i('Updating category $categoryId with data: $categoryData');
      final response = await _apiService.put(
        '/categories/$categoryId',
        data: categoryData,
      );

      if (response != null && response['data'] != null) {
        updatedCategory = Category.fromJson(
          response['data'] as Map<String, dynamic>,
        );
        _logger.i('Category updated: ${updatedCategory?.name}');
        final index = _categories.indexWhere((cat) => cat.id == categoryId);
        if (index != -1) {
          _categories[index] = updatedCategory!;
        }
        if (_selectedCategory?.id == categoryId) {
          _selectedCategory = updatedCategory;
        }
        notifyListeners();
        return updatedCategory;
      } else {
        _logger.w('Update category response missing data: $response');
        throw Exception(
          'Failed to update category: Invalid response structure',
        );
      }
    }, errorMessage: 'Failed to update category');
    return updatedCategory;
  }

  Future<void> deleteCategory(String categoryId) async {
    await handleAsync(() async {
      _logger.i('Deleting category: $categoryId');
      await _apiService.delete('/categories/$categoryId');
      _logger.i('Category deleted: $categoryId');
      _categories.removeWhere((cat) => cat.id == categoryId);
      if (_selectedCategory?.id == categoryId) {
        _selectedCategory = null;
      }
      notifyListeners();
    }, errorMessage: 'Failed to delete category');
  }

  void clearSelectedCategory() {
    _selectedCategory = null;
    notifyListeners();
  }
}
