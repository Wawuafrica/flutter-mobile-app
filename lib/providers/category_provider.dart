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
        setError('Invalid response structure');
        return [];
      }
    } catch (e) {
      _categories = [];
      setError('Failed to fetch categories: $e');
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
        setError('Invalid response structure');
        return null;
      }
    } catch (e) {
      _selectedCategory = null;
      setError('Failed to fetch category: $e');
      return null;
    }
  }

  Future<List<SubCategory>> fetchSubCategories(String categoryId) async {
    setLoading();
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        '/categories/$categoryId/subcategories',
      );

      print('sub_cat data with id $categoryId and response is $response');

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
        setError('Invalid response data');
        return [];
      }
    } catch (e) {
      _subCategories = [];
      setError('Failed to fetch sub-categories: $e');
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
          setError('Invalid response structure');
          return [];
        }
      }

      _services = allServices;
      setSuccess();
      return _services;
    } catch (e) {
      _services = [];
      setError('Failed to fetch services: $e');
      return [];
    }
  }

  void clearSelectedCategory() {
    _selectedCategory = null;
    setSuccess();
  }

  void clearSelectedSubCategory() {
    _selectedSubCategory = null;
    setSuccess();
  }

  void clearSelectedService() {
    _selectedService = null;
    setSuccess();
  }

  void selectCategory(CategoryModel category) {
    _selectedCategory = category;
    setSuccess();
  }

  void selectSubCategory(SubCategory subCategory) {
    _selectedSubCategory = subCategory;
    setSuccess();
  }

  void selectService(Service service) {
    _selectedService = service;
    setSuccess();
  }
}
