import '../models/link_item.dart';
import '../services/api_service.dart';
import 'base_provider.dart'; // Import BaseProvider

// LinksProvider now extends BaseProvider for standardized state management.
class LinksProvider extends BaseProvider {
  final ApiService apiService;
  List<LinkItem> _links = [];
  // Removed _isLoading and _error fields as BaseProvider handles them.
  // bool _isLoading = false;
  // String? _error;

  LinksProvider({required this.apiService});

  List<LinkItem> get links => _links;
  // Getters for isLoading and error are now inherited from BaseProvider.
  // bool get isLoading => _isLoading;
  // String? get error => _error;

  Future<void> fetchLinks() async {
    setLoading(); // Use BaseProvider's setLoading
    try {
      final response = await apiService.get('/links');
      if (response['statusCode'] == 200 && response['data'] is List) {
        _links =
            (response['data'] as List)
                .map((item) => LinkItem.fromJson(item))
                .toList();
        setSuccess(); // Use BaseProvider's setSuccess
      } else {
        // Use BaseProvider's setError with the message from the response
        setError(response['message']?.toString() ?? 'Unknown error');
      }
    } catch (e) {
      setError(
        e.toString(),
      ); // Use BaseProvider's setError with the caught exception
    }
    // Removed manual _isLoading = false; notifyListeners(); as BaseProvider methods handle this.
  }

  LinkItem? getLinkByName(String name) {
    try {
      return _links.firstWhere(
        (l) => l.name.toLowerCase() == name.toLowerCase(),
      );
    } catch (_) {
      // No need to set error state for a simple getter that returns null on not found.
      return null;
    }
  }

  /// Clears the current error message and resets the state to idle.
  void clearError() {
    resetState(); // Calls resetState from BaseProvider
  }
}
