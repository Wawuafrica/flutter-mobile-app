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
      final response = await _apiService.get<Map<String, dynamic>>('/categories');
      
      if (response.containsKey('data') && response['data'] is List) {
        final categoriesJson = response['data'] as List;
        _categories = categoriesJson
            .map((json) => Category.fromJson(json as Map<String, dynamic>))
            .toList();
        notifyListeners();
        return _categories;
      } else {
        _categories = [];
        print('Failed to fetch categories: Invalid response structure');
        return [];
      }
    } catch (e) {
      _categories = [];
      print('Failed to fetch categories: $e');
      return [];
    }
  }

  Future<Category?> fetchCategoryById(String categoryId) async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        '/categories/$categoryId',
      );

      if (response.containsKey('data')) {
        _selectedCategory = Category.fromJson(
          response['data'] as Map<String, dynamic>,
        );
        notifyListeners();
        return _selectedCategory;
      } else {
        _selectedCategory = null;
        print('Failed to fetch category: Invalid response structure');
        return null;
      }
    } catch (e) {
      _selectedCategory = null;
      print('Failed to fetch category details: $e');
      return null;
    }
  }

  Future<List<SubCategory>> fetchSubCategories(String categoryId) async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        '/categories/$categoryId/subcategories',
      );
      
      if (response.containsKey('data') && response['data'] is List) {
        final subCategoriesJson = response['data'] as List;
        _subCategories = subCategoriesJson
            .map((json) => SubCategory.fromJson(json as Map<String, dynamic>))
            .toList();
        notifyListeners();
        return _subCategories;
      } else {
        _subCategories = [];
        print('Failed to fetch sub-categories: Invalid response data');
        return [];
      }
    } catch (e) {
      _subCategories = [];
      print('Failed to fetch sub-categories: $e');
      return [];
    }
  }

  Future<List<Service>> fetchServices(String subCategoryId) async {
    try {
      List<Service> allServices = [];
      int currentPage = 1;
      bool hasMorePages = true;

      while (hasMorePages) {
        final response = await _apiService.get<Map<String, dynamic>>(
          '/subcategories/$subCategoryId/services?page=$currentPage',
        );
        
        if (response.containsKey('data') && response['data'] is List) {
          final servicesJson = response['data'] as List;
          final services = servicesJson
              .map((json) => Service.fromJson(json as Map<String, dynamic>))
              .toList();
          allServices.addAll(services);

          if (response.containsKey('pagination') && response['pagination'] is Map) {
            final pagination = response['pagination'] as Map<String, dynamic>;
            final nextPage = pagination['next_page'];
            if (nextPage != null && nextPage is int) {
              currentPage = nextPage;
            } else {
              hasMorePages = false;
            }
          } else {
            hasMorePages = false;
          }
        } else {
          print('Failed to fetch services: Invalid response structure');
          return [];
        }
      }

      _services = allServices;
      notifyListeners();
      return _services;
    } catch (e) {
      _services = [];
      print('Failed to fetch services: $e');
      return [];
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