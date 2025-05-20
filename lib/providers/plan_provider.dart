import 'package:logger/logger.dart';
import '../models/plan.dart';
import '../services/api_service.dart';
// Assuming PusherService might be needed for real-time plan updates
// import '../services/pusher_service.dart';
import 'base_provider.dart';

class PlanProvider extends BaseProvider {
  final ApiService _apiService;
  // final PusherService _pusherService; // Uncomment if Pusher is used for plans
  final Logger _logger;

  List<Plan> _plans = [];
  Plan? _selectedPlan;

  List<Plan> get plans => _plans;
  Plan? get selectedPlan => _selectedPlan;

  PlanProvider({
    required ApiService apiService,
    // required PusherService pusherService, // Uncomment if Pusher is used
    required Logger logger,
  }) : _apiService = apiService,
       // _pusherService = pusherService, // Uncomment if Pusher is used
       _logger = logger,
       super() {
    // _initPusherListeners(); // Uncomment if Pusher is used
  }

  // void _initPusherListeners() {
  //   // Example: Listen for plan updates
  //   // _pusherService.bind('plan-updated', (event) {
  //   //   if (event != null && event.data != null) {
  //   //     try {
  //   //       final planData = Map<String, dynamic>.from(jsonDecode(event.data!));
  //   //       final updatedPlan = Plan.fromJson(planData);
  //   //       updateLocalPlan(updatedPlan);
  //   //       _logger.i('Plan updated via Pusher: ${updatedPlan.name}');
  //   //     } catch (e) {
  //   //       _logger.e('Error processing Pusher plan update: $e');
  //   //     }
  //   //   }
  //   // });
  //   // Add other listeners as needed (e.g., plan-created, plan-deleted)
  // }

  Future<void> fetchAllPlans() async {
    await handleAsync(() async {
      _logger.i('Fetching all plans');
      final response = await _apiService.get('/plans');

      if (response != null && response['data'] is List) {
        _plans =
            (response['data'] as List)
                .map(
                  (planJson) => Plan.fromJson(planJson as Map<String, dynamic>),
                )
                .toList();
        _logger.i('Fetched ${_plans.length} plans.');
        return _plans;
      } else {
        _logger.w(
          'Fetch all plans response missing data or not a list: $response',
        );
        _plans = [];
        throw Exception('Failed to fetch plans: Invalid response structure');
      }
    }, errorMessage: 'Failed to fetch plans');
  }

  Future<void> fetchPlanById(String planId) async {
    await handleAsync(() async {
      _logger.i('Fetching plan by ID: $planId');
      final response = await _apiService.get('/plans/$planId');

      if (response != null && response['data'] != null) {
        _selectedPlan = Plan.fromJson(response['data'] as Map<String, dynamic>);
        _logger.i('Fetched plan: ${_selectedPlan?.name}');
        return _selectedPlan;
      } else {
        _logger.w('Fetch plan by ID response missing data: $response');
        _selectedPlan = null;
        throw Exception('Failed to fetch plan: Invalid response structure');
      }
    }, errorMessage: 'Failed to fetch plan details');
  }

  // Placeholder for create, update, delete operations
  // These would be similar to CategoryProvider, using _apiService.post, .put, .delete
  // and then updating the local _plans list and _selectedPlan, then calling notifyListeners().

  // Example for creating a plan (adapt as needed based on API)
  Future<Plan?> createPlan(Map<String, dynamic> planData) async {
    Plan? createdPlan;
    await handleAsync(() async {
      _logger.i('Creating plan with data: $planData');
      final response = await _apiService.post('/plans', data: planData);

      if (response != null && response['data'] != null) {
        createdPlan = Plan.fromJson(response['data'] as Map<String, dynamic>);
        _logger.i('Plan created: ${createdPlan?.name}');
        _plans.add(createdPlan!);
        notifyListeners(); // Important to update UI
        return createdPlan;
      } else {
        _logger.w('Create plan response missing data: $response');
        throw Exception('Failed to create plan: Invalid response structure');
      }
    }, errorMessage: 'Failed to create plan');
    return createdPlan;
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
