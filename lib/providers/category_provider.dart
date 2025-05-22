import '../models/category.dart';
import '../services/api_service.dart';
import 'base_provider.dart';

class CategoryProvider extends BaseProvider {
  final ApiService _apiService;

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

  CategoryProvider({required ApiService apiService})
    : _apiService = apiService,
      super();

  Future<List<Category>> fetchCategories() async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        '/categories',
      );
      
      if (response.containsKey('data') && response['data'] is List) {
        final categoriesJson = response['data'] as List;
        _categories = categoriesJson
            .map((json) => Category.fromJson(json as Map<String, dynamic>))
            .toList();
        return _categories;
      } else {
        _categories = [];
        print('Failed to fetch categories: Invalid response structure');
        return [];
      }
    } catch (e) {
      print('Failed to fetch categories: \$e');
      return [];
    }
  }

  Future<Category?> fetchCategoryById(String categoryId) async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        '/categories/\$categoryId',
      );

      if (response.containsKey('data')) {
        _selectedCategory = Category.fromJson(
          response['data'] as Map<String, dynamic>,
        );
        return _selectedCategory!;
      } else {
        _selectedCategory = null;
        print('Failed to fetch category: Invalid response structure');
        return null;
      }
    } catch (e) {
      print('Failed to fetch category details: \$e');
      return null;
    }
  }
  
  // Get all sub-categories for a specific category
  Future<List<SubCategory>> fetchSubCategories(String categoryId) async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        '/categories/\$categoryId/subcategories',
      );
      
      if (response.containsKey('data') && response['data'] is List) {
        final subCategoriesJson = response['data'] as List;
        _subCategories = subCategoriesJson
            .map((json) => SubCategory.fromJson(json as Map<String, dynamic>))
            .toList();
        return _subCategories;
      } else {
        _subCategories = [];
        print('Failed to fetch sub-categories: Invalid response structure');
        return [];
      }
    } catch (e) {
      print('Failed to fetch sub-categories: \$e');
      return [];
    }
  }
  
  // Get all services for a specific sub-category
  Future<List<Service>> fetchServices(String subCategoryId) async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        '/subcategories/\$subCategoryId/services',
      );
      
      if (response.containsKey('data') && response['data'] is List) {
        final servicesJson = response['data'] as List;
        _services = servicesJson
            .map((json) => Service.fromJson(json as Map<String, dynamic>))
            .toList();
        return _services;
      } else {
        _services = [];
        print('Failed to fetch services: Invalid response structure');
        return [];
      }
    } catch (e) {
      print('Failed to fetch services: \$e');
      return [];
    }
  }

  Future<Category?> createCategory(Map<String, dynamic> categoryData) async {
    Category? createdCategory;
    try {
      final response = await _apiService.post(
        '/categories',
        data: categoryData,
      );

      if (response != null && response['data'] != null) {
        createdCategory = Category.fromJson(
          response['data'] as Map<String, dynamic>,
        );
        _categories.add(createdCategory!);
        notifyListeners();
        return createdCategory;
      } else {
        print(
          'Failed to create category: Invalid response structure',
        );
        return null;
      }
    } catch (e) {
      print('Failed to create category: \$e');
      return null;
    }
  }

  Future<Category?> updateCategory(
    String categoryId,
    Map<String, dynamic> categoryData,
  ) async {
    Category? updatedCategory;
    try {
      final response = await _apiService.put(
        '/categories/\$categoryId',
        data: categoryData,
      );

      if (response != null && response['data'] != null) {
        updatedCategory = Category.fromJson(
          response['data'] as Map<String, dynamic>,
        );
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
        print(
          'Failed to update category: Invalid response structure',
        );
        return null;
      }
    } catch (e) {
      print('Failed to update category: \$e');
      return null;
    }
  }

  Future<void> deleteCategory(String categoryId) async {
    try {
      await _apiService.delete('/categories/\$categoryId');
      _categories.removeWhere((cat) => cat.id == categoryId);
      if (_selectedCategory?.id == categoryId) {
        _selectedCategory = null;
      }
      notifyListeners();
    } catch (e) {
      print('Failed to delete category: \$e');
    }
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
