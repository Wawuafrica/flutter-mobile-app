import 'package:wawu_mobile/models/skill.dart';
import 'package:wawu_mobile/services/api_service.dart';
import 'base_provider.dart'; // Import BaseProvider

// SkillProvider now extends BaseProvider for standardized state management.
class SkillProvider extends BaseProvider {
  final ApiService apiService;
  SkillProvider({required this.apiService});

  List<Skill> _skills = [];
  // Removed _isLoading and _error fields as BaseProvider handles them.
  // bool _isLoading = false;
  // String? _error;

  List<Skill> get skills => _skills;
  // Getters for isLoading and error are now inherited from BaseProvider.
  // bool get isLoading => _isLoading;
  // String? get error => _error;

  Future<void> fetchSkills() async {
    setLoading(); // Use BaseProvider's setLoading
    try {
      final response = await apiService.get<Map<String, dynamic>>('/skill');
      if (response['statusCode'] == 200 && response['data'] is List) {
        _skills =
            (response['data'] as List)
                .map(
                  (item) => Skill(
                    id: item['id'].toString(),
                    name: item['name'] ?? '',
                  ),
                )
                .toList();
        setSuccess(); // Use BaseProvider's setSuccess
      } else {
        // Use BaseProvider's setError with the message from the response
        setError(response['message'] ?? 'Failed to fetch skills');
      }
    } catch (e) {
      setError(
        e.toString(),
      ); // Use BaseProvider's setError with the caught exception
    }
    // Removed manual _isLoading = false; notifyListeners(); as BaseProvider methods handle this.
  }

  void clearError() {
    resetState();
  }
}
