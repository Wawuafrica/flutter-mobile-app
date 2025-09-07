import '../models/wawu_africa_nest.dart';
import '../services/api_service.dart';
import 'base_provider.dart';
import 'user_provider.dart'; // Import UserProvider

class WawuAfricaProvider extends BaseProvider {
  final ApiService _apiService;
  final UserProvider _userProvider; // Add UserProvider

  // Base URL for the Node.js/Express backend
  static const String _tsBackendBaseUrl =
      'https://wawu-ts-backend-sable.vercel.app/api';

  List<WawuAfricaCategory> _categories = [];
  List<WawuAfricaSubCategory> _subCategories = [];
  List<WawuAfricaInstitution> _institutions = [];
  List<WawuAfricaInstitutionContent> _institutionContents = [];

  WawuAfricaCategory? _selectedCategory;
  WawuAfricaSubCategory? _selectedSubCategory;
  WawuAfricaInstitution? _selectedInstitution;

  List<WawuAfricaCategory> get categories => _categories;
  List<WawuAfricaSubCategory> get subCategories => _subCategories;
  List<WawuAfricaInstitution> get institutions => _institutions;
  List<WawuAfricaInstitutionContent> get institutionContents =>
      _institutionContents;

  WawuAfricaCategory? get selectedCategory => _selectedCategory;
  WawuAfricaSubCategory? get selectedSubCategory => _selectedSubCategory;
  WawuAfricaInstitution? get selectedInstitution => _selectedInstitution;

  WawuAfricaProvider(
      {required ApiService apiService, required UserProvider userProvider})
      : _apiService = apiService,
        _userProvider = userProvider,
        super();

  Future<List<WawuAfricaCategory>> fetchCategories() async {
    setLoading();
    try {
      final response = await _apiService.get<List<dynamic>>(
        '$_tsBackendBaseUrl/categories',
      );

      _categories = response
          .map((json) =>
              WawuAfricaCategory.fromJson(json as Map<String, dynamic>))
          .toList();
      setSuccess();
      return _categories;
    } catch (e) {
      _categories = [];
      setError(e.toString());
      return [];
    }
  }

  Future<List<WawuAfricaSubCategory>> fetchSubCategories(
      String categoryId) async {
    setLoading();
    try {
      final response = await _apiService.get<List<dynamic>>(
        '$_tsBackendBaseUrl/sub-categories/category/$categoryId',
      );

      _subCategories = response
          .map((json) =>
              WawuAfricaSubCategory.fromJson(json as Map<String, dynamic>))
          .toList();
      setSuccess();
      return _subCategories;
    } catch (e) {
      _subCategories = [];
      setError(e.toString());
      return [];
    }
  }

  Future<List<WawuAfricaInstitution>> fetchInstitutionsBySubCategory(
      String subCategoryId) async {
    setLoading();
    try {
      final response = await _apiService.get<List<dynamic>>(
        '$_tsBackendBaseUrl/institutions/sub-category/$subCategoryId',
      );
      _institutions = response
          .map((json) =>
              WawuAfricaInstitution.fromJson(json as Map<String, dynamic>))
          .toList();
      setSuccess();
      return _institutions;
    } catch (e) {
      _institutions = [];
      setError(e.toString());
      return [];
    }
  }

  Future<List<WawuAfricaInstitutionContent>>
      fetchInstitutionContentsByInstitutionId(String institutionId) async {
    setLoading();
    try {
      final response = await _apiService.get<List<dynamic>>(
        '$_tsBackendBaseUrl/institution-contents/institution/$institutionId',
      );

      _institutionContents = response
          .map((json) => WawuAfricaInstitutionContent.fromJson(
              json as Map<String, dynamic>))
          .toList();
      setSuccess();
      return _institutionContents;
    } catch (e) {
      _institutionContents = [];
      setError(e.toString());
      return [];
    }
  }

  Future<bool> registerForContent(int institutionContentId) async {
    setLoading();
    try {
      final currentUserId = _userProvider.currentUser?.uuid ?? '';
      final firstName = _userProvider.currentUser?.firstName ?? '';
      final lastName = _userProvider.currentUser?.lastName ?? '';
      final userFullName = '$firstName $lastName'.trim();
      final userEmail = _userProvider.currentUser?.email ?? '';

      if (currentUserId.isEmpty || userFullName.isEmpty || userEmail.isEmpty) {
        setError('User information is missing. Please log in again.');
        return false;
      }

      final registrationData = {
        'user_id': currentUserId,
        'user_full_name': userFullName,
        'user_email': userEmail,
        'wawu_africa_institution_content_id': institutionContentId,
      };

      await _apiService.post<Map<String, dynamic>>(
        '$_tsBackendBaseUrl/user-content-registrations',
        data: registrationData,
      );

      setSuccess();
      return true;
    } catch (e) {
      setError(e.toString());
      return false;
    }
  }

  void clearError() {
    resetState();
  }

  void selectCategory(WawuAfricaCategory category) {
    _selectedCategory = category;
    setSuccess();
  }

  void selectSubCategory(WawuAfricaSubCategory subCategory) {
    _selectedSubCategory = subCategory;
    setSuccess();
  }

  void selectInstitution(WawuAfricaInstitution institution) {
    _selectedInstitution = institution;
    setSuccess();
  }
}

