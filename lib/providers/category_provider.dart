import 'package:logger/logger.dart';
import '../models/category.dart';
import '../services/api_service.dart';
import 'base_provider.dart';

class CategoryProvider extends BaseProvider {
  final ApiService _apiService;
  final Logger _logger;

  List<Category> _categories = [];
  List<SubCategory> _subCategories = [];
  List<Service> _services = [];
  
  Category? _selectedCategory;
  SubCategory? _selectedSubCategory;
  Service? _selectedService;

  List<Category> get categories => _categories;
  List<SubCategory> get subCategories => _subCategories;
  List<Service> get services => _services;
  
  Category? get selectedCategory => _selectedCategory;
  SubCategory? get selectedSubCategory => _selectedSubCategory;
  Service? get selectedService => _selectedService;

  CategoryProvider({required ApiService apiService, required Logger logger})
    : _apiService = apiService,
      _logger = logger,
      super();

  Future<List<Category>> fetchCategories() async {
    final result = await handleAsync<List<Category>>(() async {
      _logger.i('Fetching all top-level categories');
      
      final response = await _apiService.get<Map<String, dynamic>>(
        '/categories',
      );
      
      if (response.containsKey('data') && response['data'] is List) {
        final categoriesJson = response['data'] as List;
        _categories = categoriesJson
            .map((json) => Category.fromJson(json as Map<String, dynamic>))
            .toList();
        _logger.i('Fetched ${_categories.length} categories.');
        return _categories;
      } else {
        _logger.w('Fetch categories response missing data or not a list: $response');
        _categories = [];
        throw Exception('Failed to fetch categories: Invalid response structure');
      }
    }, errorMessage: 'Failed to fetch categories');
    return result ?? [];
  }

  Future<Category?> fetchCategoryById(String categoryId) async {
    final result = await handleAsync<Category>(() async {
      _logger.i('Fetching category by ID: $categoryId');
      final response = await _apiService.get<Map<String, dynamic>>(
        '/categories/$categoryId',
      );

      if (response.containsKey('data')) {
        _selectedCategory = Category.fromJson(
          response['data'] as Map<String, dynamic>,
        );
        _logger.i('Fetched category: ${_selectedCategory?.name}');
        return _selectedCategory!;
      } else {
        _logger.w('Fetch category by ID response missing data: $response');
        _selectedCategory = null;
        throw Exception('Failed to fetch category: Invalid response structure');
      }
    }, errorMessage: 'Failed to fetch category details');
    return result;
  }
  
  // Get all sub-categories for a specific category
  Future<List<SubCategory>> fetchSubCategories(String categoryId) async {
    final result = await handleAsync<List<SubCategory>>(() async {
      _logger.i('Fetching sub-categories for category ID: $categoryId');
      final response = await _apiService.get<Map<String, dynamic>>(
        '/categories/$categoryId/subcategories',
      );
      
      if (response.containsKey('data') && response['data'] is List) {
        final subCategoriesJson = response['data'] as List;
        _subCategories = subCategoriesJson
            .map((json) => SubCategory.fromJson(json as Map<String, dynamic>))
            .toList();
        _logger.i('Fetched ${_subCategories.length} sub-categories.');
        return _subCategories;
      } else {
        _logger.w('Fetch sub-categories response missing data or not a list: $response');
        _subCategories = [];
        throw Exception('Failed to fetch sub-categories: Invalid response structure');
      }
    }, errorMessage: 'Failed to fetch sub-categories');
    return result ?? [];
  }
  
  // Get all services for a specific sub-category
  Future<List<Service>> fetchServices(String subCategoryId) async {
    final result = await handleAsync<List<Service>>(() async {
      _logger.i('Fetching services for sub-category ID: $subCategoryId');
      final response = await _apiService.get<Map<String, dynamic>>(
        '/subcategories/$subCategoryId/services',
      );
      
      if (response.containsKey('data') && response['data'] is List) {
        final servicesJson = response['data'] as List;
        _services = servicesJson
            .map((json) => Service.fromJson(json as Map<String, dynamic>))
            .toList();
        _logger.i('Fetched ${_services.length} services.');
        return _services;
      } else {
        _logger.w('Fetch services response missing data or not a list: $response');
        _services = [];
        throw Exception('Failed to fetch services: Invalid response structure');
      }
    }, errorMessage: 'Failed to fetch services');
    return result ?? [];
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
  
  void clearSelectedSubCategory() {
    _selectedSubCategory = null;
    notifyListeners();
  }
  
  void clearSelectedService() {
    _selectedService = null;
    notifyListeners();
  }
  
  void selectCategory(Category category) {
    _selectedCategory = category;
    notifyListeners();
  }
  
  void selectSubCategory(SubCategory subCategory) {
    _selectedSubCategory = subCategory;
    notifyListeners();
  }
  
  void selectService(Service service) {
    _selectedService = service;
    notifyListeners();
  }
}
