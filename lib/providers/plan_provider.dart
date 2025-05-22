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
  }) : _apiService = apiService,
       super();

  Future<void> fetchAllPlans() async {
    try {
      final response = await _apiService.get('/plans');

      if (response != null && response['data'] is List) {
        _plans =
            (response['data'] as List)
                .map(
                  (planJson) => Plan.fromJson(planJson as Map<String, dynamic>),
                )
                .toList();
        return;
      } else {
        _plans = [];
        print('Failed to fetch plans: Invalid response structure');
        return;
      }
    } catch (e) {
      print('Failed to fetch plans: $e');
      return;
    }
  }

  Future<void> fetchPlanById(String planId) async {
    try {
      final response = await _apiService.get('/plans/$planId');

      if (response != null && response['data'] != null) {
        _selectedPlan = Plan.fromJson(response['data'] as Map<String, dynamic>);
        return;
      } else {
        _selectedPlan = null;
        print('Failed to fetch plan: Invalid response structure');
        return;
      }
    } catch (e) {
      print('Failed to fetch plan details: $e');
      return;
    }
  }

  Future<Plan?> createPlan(Map<String, dynamic> planData) async {
    Plan? createdPlan;
    try {
      final response = await _apiService.post('/plans', data: planData);

      if (response != null && response['data'] != null) {
        createdPlan = Plan.fromJson(response['data'] as Map<String, dynamic>);
        _plans.add(createdPlan!);
        notifyListeners(); // Important to update UI
        return createdPlan;
      } else {
        print('Create plan response missing data: $response');
        return null;
      }
    } catch (e) {
      print('Failed to create plan: $e');
      return null;
    }
  }

  void updateLocalPlan(Plan plan) {
    final index = _plans.indexWhere((p) => p.id == plan.id);
    if (index != -1) {
      _plans[index] = plan;
      if (_selectedPlan?.id == plan.id) {
        _selectedPlan = plan;
      }
      notifyListeners();
    } else {
      // Optionally add if not found, or handle as an error
      _plans.add(plan); // Or log an error if expected to always exist
      notifyListeners();
    }
  }

  void clearSelectedPlan() {
    _selectedPlan = null;
    notifyListeners();
  }
}
