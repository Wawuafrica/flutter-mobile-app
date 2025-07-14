import '../models/country.dart';
import '../models/state_province.dart';
import '../services/api_service.dart';
import 'base_provider.dart'; // Import BaseProvider

// LocationProvider now extends BaseProvider for standardized state management.
class LocationProvider extends BaseProvider {
  final ApiService apiService;
  LocationProvider({required this.apiService});

  List<Country> _countries = [];
  List<StateProvince> _states = [];
  // Removed multiple _isLoading and _error fields as BaseProvider handles a single state.
  // bool _isLoadingCountries = false;
  // bool _isLoadingStates = false;
  // String? _errorCountries;
  // String? _errorStates;

  List<Country> get countries => _countries;
  List<StateProvince> get states => _states;
  // Getters for isLoading and error are now inherited from BaseProvider.
  // bool get isLoadingCountries => _isLoadingCountries; // No longer needed directly
  // bool get isLoadingStates => _isLoadingStates; // No longer needed directly
  // String? get errorCountries => _errorCountries; // No longer needed directly
  // String? get errorStates => _errorStates; // No longer needed directly

  Future<void> fetchCountries() async {
    setLoading(); // Use BaseProvider's setLoading
    try {
      final response = await apiService.get<Map<String, dynamic>>('/countries');
      if (response['statusCode'] == 200 && response['data'] is List) {
        _countries =
            (response['data'] as List)
                .map((item) => Country.fromJson(item))
                .toList();
        setSuccess(); // Use BaseProvider's setSuccess
      } else {
        // Use BaseProvider's setError with the message from the response
        setError(response['message'] ?? 'Failed to fetch countries');
      }
    } catch (e) {
      setError(
        e.toString(),
      ); // Use BaseProvider's setError with the caught exception
    }
    // Removed manual _isLoadingCountries = false; notifyListeners(); as BaseProvider methods handle this.
  }

  Future<void> fetchStates(int countryId) async {
    setLoading(); // Use BaseProvider's setLoading
    try {
      final response = await apiService.get<Map<String, dynamic>>(
        '/states/$countryId',
      );
      if (response['statusCode'] == 200 && response['data'] is List) {
        _states =
            (response['data'] as List)
                .map((item) => StateProvince.fromJson(item))
                .toList();
        setSuccess(); // Use BaseProvider's setSuccess
      } else {
        // Use BaseProvider's setError with the message from the response
        setError(response['message'] ?? 'Failed to fetch states');
      }
    } catch (e) {
      setError(
        e.toString(),
      ); // Use BaseProvider's setError with the caught exception
    }
    // Removed manual _isLoadingStates = false; notifyListeners(); as BaseProvider methods handle this.
  }

  void clearStates() {
    _states = [];
    setSuccess(); // Use setSuccess to notify listeners about the cleared states
  }

  void clearError() {
    resetState(); // Calls resetState from BaseProvider
  }
}
