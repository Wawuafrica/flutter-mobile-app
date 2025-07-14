import '../models/category.dart';
import '../services/api_service.dart';
import 'base_provider.dart';

class CategoryProvider extends BaseProvider {
  final ApiService _apiService;

  List<CategoryModel> _categories = [];
  List<SubCategory> _subCategories = [];
  List<Service> _services = [];

  CategoryModel? _selectedCategory;
  SubCategory? _selectedSubCategory;
  Service? _selectedService;

  List<CategoryModel> get categories => _categories;
  List<SubCategory> get subCategories => _subCategories;
  List<Service> get services => _services;

  CategoryModel? get selectedCategory => _selectedCategory;
  SubCategory? get selectedSubCategory => _selectedSubCategory;
  Service? get selectedService => _selectedService;

  CategoryProvider({required ApiService apiService})
    : _apiService = apiService,
      super();

  Future<List<CategoryModel>> fetchCategories() async {
    setLoading();
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        '/categories',
      );

      if (response.containsKey('data') && response['data'] is List) {
        final categoriesJson = response['data'] as List;
        _categories =
            categoriesJson
                .map(
                  (json) =>
                      CategoryModel.fromJson(json as Map<String, dynamic>),
                )
                .toList();
        setSuccess();
        return _categories;
      } else {
        _categories = [];
        setError(
          response['message'] ?? 'Invalid response structure',
        ); // Simplified error message
        return [];
      }
    } catch (e) {
      _categories = [];
      setError(e.toString()); // Simplified error message
      return [];
    }
  }

  Future<CategoryModel?> fetchCategoryById(String categoryId) async {
    setLoading();
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        '/categories/$categoryId',
      );

      if (response.containsKey('data')) {
        _selectedCategory = CategoryModel.fromJson(
          response['data'] as Map<String, dynamic>,
        );
        setSuccess();
        return _selectedCategory;
      } else {
        _selectedCategory = null;
        setError(
          response['message'] ?? 'Invalid response structure',
        ); // Simplified error message
        return null;
      }
    } catch (e) {
      _selectedCategory = null;
      setError(e.toString()); // Simplified error message
      return null;
    }
  }

  Future<List<SubCategory>> fetchSubCategories(String categoryId) async {
    setLoading();
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        '/categories/$categoryId/subcategories',
      );

      // print('sub_cat data with id $categoryId and response is $response');

      if (response.containsKey('data') && response['data'] is List) {
        final subCategoriesJson = response['data'] as List;
        _subCategories =
            subCategoriesJson
                .map(
                  (json) => SubCategory.fromJson(json as Map<String, dynamic>),
                )
                .toList();
        setSuccess();
        return _subCategories;
      } else {
        _subCategories = [];
        setError(
          response['message'] ?? 'Invalid response data',
        ); // Simplified error message
        return [];
      }
    } catch (e) {
      _subCategories = [];
      setError(e.toString()); // Simplified error message
      return [];
    }
  }

  Future<List<Service>> fetchServices(String subCategoryId) async {
    setLoading();
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
          final services =
              servicesJson
                  .map((json) => Service.fromJson(json as Map<String, dynamic>))
                  .toList();
          allServices.addAll(services);

          if (response.containsKey('pagination') &&
              response['pagination'] is Map) {
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
          setError(
            response['message'] ?? 'Invalid response structure',
          ); // Simplified error message
          return [];
        }
      }

      _services = allServices;
      setSuccess();
      return _services;
    } catch (e) {
      _services = [];
      setError(e.toString()); // Simplified error message
      return [];
    }
  }

  void clearError() {
    resetState();
  }

  void clearSelectedCategory() {
    _selectedCategory = null;
    setSuccess(); // Use setSuccess to notify listeners
  }

  void clearSelectedSubCategory() {
    _selectedSubCategory = null;
    setSuccess(); // Use setSuccess to notify listeners
  }

  void clearSelectedService() {
    _selectedService = null;
    setSuccess(); // Use setSuccess to notify listeners
  }

  void selectCategory(CategoryModel category) {
    _selectedCategory = category;
    setSuccess(); // Use setSuccess to notify listeners
  }

  void selectSubCategory(SubCategory subCategory) {
    _selectedSubCategory = subCategory;
    setSuccess(); // Use setSuccess to notify listeners
  }

  void selectService(Service service) {
    _selectedService = service;
    setSuccess(); // Use setSuccess to notify listeners
  }
}
