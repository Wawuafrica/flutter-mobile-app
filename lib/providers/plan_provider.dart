import '../models/plan.dart';
import '../models/subscription.dart';
import '../services/api_service.dart';
import 'package:wawu_mobile/providers/base_provider.dart';
import 'package:wawu_mobile/services/onboarding_state_service.dart';

class PlanProvider extends BaseProvider {
  final ApiService _apiService;

  List<Plan> _plans = [];
  Plan? _selectedPlan;
  PaymentLink? _paymentLink;
  Subscription? _subscription;

  List<Plan> get plans => _plans;
  Plan? get selectedPlan => _selectedPlan;
  PaymentLink? get paymentLink => _paymentLink;
  Subscription? get subscription => _subscription;

  PlanProvider({required ApiService apiService})
    : _apiService = apiService,
      super();

  Future<void> fetchAllPlans() async {
    // print('fetchAllPlans: Starting fetch');
    setLoading();
    try {
      final response = await _apiService.get('/plans');
      // print('fetchAllPlans: Response received: $response');
      if (response != null && response['data'] is List) {
        _plans =
            (response['data'] as List)
                .map(
                  (planJson) => Plan.fromJson(planJson as Map<String, dynamic>),
                )
                .toList();
        // print('fetchAllPlans: Parsed ${_plans.length} plans');
        setSuccess();
      } else {
        _plans = [];
        // print('fetchAllPlans: Invalid response structure, setting empty plans');
        setError(
          response['message'] ??
              'Failed to fetch plans: Invalid response structure',
        ); // Simplified error message
      }
    } catch (e) {
      _plans = [];
      // print('fetchAllPlans: Error occurred: $e');
      setError(e.toString()); // Simplified error message
    }
  }

  Future<void> generatePaymentLink({
    required String planUuid,
    required String userId,
  }) async {
    // print('generatePaymentLink: Starting for plan: $planUuid, user: $userId');
    setLoading();
    try {
      final response = await _apiService.post(
        '/subscribe/$planUuid',
        data: {'user_id': userId},
      );
      // print('generatePaymentLink: Response received: $response');

      if (response != null && response['data'] != null) {
        _paymentLink = PaymentLink.fromJson(
          response['data'] as Map<String, dynamic>,
        );
        // print(
        //   'generatePaymentLink: Payment link generated: ${_paymentLink!.link}',
        // );
        setSuccess();
      } else {
        _paymentLink = null;
        // print('generatePaymentLink: Invalid response structure');
        setError(
          response['message'] ??
              'Failed to generate payment link: Invalid response structure',
        ); // Simplified error message
      }
    } catch (e) {
      _paymentLink = null;
      // print('generatePaymentLink: Error occurred: $e');
      setError(e.toString()); // Simplified error message
    }
  }

  Future<void> handlePaymentCallback(String callbackUrl) async {
    // print('handlePaymentCallback: Processing callback URL: $callbackUrl');
    setLoading();
    try {
      final uri = Uri.parse(callbackUrl);
      String path = uri.path;

      // The ApiService expects paths relative to the base API URL.
      // The incoming URL path might be /api/payment/callback, so we remove the /api prefix if it exists.
      if (path.startsWith('/api/')) {
        path = path.substring(4);
      }
      final pathWithQuery = path + (uri.hasQuery ? '?${uri.query}' : '');

      final response = await _apiService.get(pathWithQuery);
      // print('handlePaymentCallback: Callback response: $response');

      if (response != null) {
        final statusCode = response['statusCode'];

        if (statusCode == 200) {
          // On success, the subscription object is directly in the 'data' field.
          if (response['data'] != null) {
            // Check if the data contains subscription information
            final dataMap = response['data'] as Map<String, dynamic>;

            // The subscription data is directly in the 'data' field, not nested under 'subscription'
            _subscription = Subscription.fromJson(dataMap);

            // print(
            //   'handlePaymentCallback: Subscription created successfully: ${_subscription!.uuid}',
            // );
            setSuccess();
            // Mark the next onboarding step after successful payment
            await OnboardingStateService.saveStep('disclaimer');
          } else {
            setError(
              response['message'] ??
                  'Failed to fetch subscription details.', // Simplified error message
            );
          }
        } else {
          // Handle failure cases (e.g., statusCode 400 or others).
          final errorMessage = response['message'] ?? 'Payment failed';
          // print(
          //   'handlePaymentCallback: Payment failed with message: $errorMessage',
          // );
          setError(errorMessage); // Use direct error message
        }
      } else {
        // Handle cases where the response is null or not in the expected format.
        setError(
          'Payment verification failed: Invalid response from server.',
        ); // Simplified error message
      }
    } catch (e) {
      // print('handlePaymentCallback: Error occurred: $e');
      setError(e.toString()); // Simplified error message
    }
  }

  Future<void> fetchUserSubscriptionDetails(String userId, int role) async {
    // print('fetchUserSubscriptionDetails: Starting fetch for user: $userId');
    setLoading();
    try {
      final response = await _apiService.get(
        '/user/subscription/details/$userId',
        // data: {'role': role}, // Payload as specified
      );
      // print('fetchUserSubscriptionDetails: Response received: $response');

      if (response != null &&
          response['data'] != null &&
          response['data']['subscription'] != null) {
        _subscription = Subscription.fromJson(
          response['data']['subscription'] as Map<String, dynamic>,
        );
        // print(
        //   'fetchUserSubscriptionDetails: Subscription details fetched: ${_subscription!.uuid}',
        // );
        setSuccess();
      } else {
        _subscription = null;
        // print(
        //   'fetchUserSubscriptionDetails: Invalid response structure or no subscription data',
        // );
        setError(
          response['message'] ??
              'Failed to fetch subscription details: Invalid response structure or no subscription data', // Simplified error message
        );
      }
    } catch (e) {
      _subscription = null;
      // print('fetchUserSubscriptionDetails: Error occurred: $e');
      setError(e.toString()); // Simplified error message
    }
  }

  void selectPlan(Plan plan) {
    _selectedPlan = plan;
    // print('selectPlan: Selected plan: ${plan.name}');
    setSuccess(); // Use setSuccess to notify listeners
  }

  void clearPaymentLink() {
    _paymentLink = null;
    // print('clearPaymentLink: Payment link cleared');
    setSuccess(); // Use setSuccess to notify listeners
  }

  void clearSubscription() {
    _subscription = null;
    // print('clearSubscription: Subscription cleared');
    setSuccess(); // Use setSuccess to notify listeners
  }

  void clearError() {
    resetState(); // Use setSuccess to notify listeners
  }

  void reset() {
    _plans = [];
    _selectedPlan = null;
    _paymentLink = null;
    _subscription = null;
    // print('reset: Cleared all plan data');
    resetState(); // Use resetState to clear error and set to idle, which also calls notifyListeners
  }
}
