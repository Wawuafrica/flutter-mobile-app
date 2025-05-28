import '../models/plan.dart';
import '../services/api_service.dart';
import 'base_provider.dart';

class PlanProvider extends BaseProvider {
  final ApiService _apiService;

  List<Plan> _plans = [];
  Plan? _selectedPlan;

  List<Plan> get plans => _plans;
  Plan? get selectedPlan => _selectedPlan;

  PlanProvider({
    required ApiService apiService,
  }) : _apiService = apiService, super();

  Future<void> fetchAllPlans() async {
    setLoading();
    try {
      final response = await _apiService.get('/plans');
      if (response != null && response['data'] is List) {
        _plans = (response['data'] as List)
            .map((planJson) => Plan.fromJson(planJson as Map<String, dynamic>))
            .toList();
        setSuccess();
      } else {
        _plans = [];
        setError('Failed to fetch plans: Invalid response structure');
      }
    } catch (e) {
      _plans = [];
      setError('Failed to fetch plans: $e');
    }
  }

  void selectPlan(Plan plan) {
    _selectedPlan = plan;
    notifyListeners();
  }

  void reset() {
    _plans = [];
    _selectedPlan = null;
    resetState();
  }
}