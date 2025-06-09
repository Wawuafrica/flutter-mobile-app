import '../models/plan.dart';
import '../models/subscription.dart';
import '../services/api_service.dart';
import 'base_provider.dart';

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
    print('fetchAllPlans: Starting fetch');
    setLoading();
    try {
      final response = await _apiService.get('/plans');
      print('fetchAllPlans: Response received: $response');
      if (response != null && response['data'] is List) {
        _plans =
            (response['data'] as List)
                .map(
                  (planJson) => Plan.fromJson(planJson as Map<String, dynamic>),
                )
                .toList();
        print('fetchAllPlans: Parsed ${_plans.length} plans');
        setSuccess();
      } else {
        _plans = [];
        print('fetchAllPlans: Invalid response structure, setting empty plans');
        setError('Failed to fetch plans: Invalid response structure');
      }
    } catch (e) {
      _plans = [];
      print('fetchAllPlans: Error occurred: $e');
      setError('Failed to fetch plans: $e');
    }
  }

  Future<void> generatePaymentLink({
    required String planUuid,
    required String userId,
  }) async {
    print('generatePaymentLink: Starting for plan: $planUuid, user: $userId');
    setLoading();
    try {
      final response = await _apiService.post(
        '/subscribe/$planUuid',
        data: {'user_id': userId},
      );
      print('generatePaymentLink: Response received: $response');

      if (response != null && response['data'] != null) {
        _paymentLink = PaymentLink.fromJson(
          response['data'] as Map<String, dynamic>,
        );
        print(
          'generatePaymentLink: Payment link generated: ${_paymentLink!.link}',
        );
        setSuccess();
      } else {
        _paymentLink = null;
        print('generatePaymentLink: Invalid response structure');
        setError('Failed to generate payment link: Invalid response structure');
      }
    } catch (e) {
      _paymentLink = null;
      print('generatePaymentLink: Error occurred: $e');
      setError('Failed to generate payment link: $e');
    }
  }

  Future<void> handlePaymentCallback(String callbackUrl) async {
    print('handlePaymentCallback: Processing callback URL: $callbackUrl');
    setLoading();
    try {
      // Parse the callback URL to extract parameters
      Uri uri = Uri.parse(callbackUrl);
      Map<String, String> params = uri.queryParameters;

      String? status = params['status'];
      String? txRef = params['tx_ref'];
      String? transactionId = params['transaction_id'];

      print(
        'handlePaymentCallback: Status: $status, TxRef: $txRef, TransactionId: $transactionId',
      );

      if (status == 'successful' && txRef != null) {
        // Make API call to confirm the subscription
        final response = await _apiService.get(
          '/payment/callback?status=$status&tx_ref=$txRef&transaction_id=$transactionId',
        );
        print('handlePaymentCallback: Callback response: $response');

        if (response != null && response['data'] != null) {
          _subscription = Subscription.fromJson(
            response['data'] as Map<String, dynamic>,
          );
          print(
            'handlePaymentCallback: Subscription created successfully: ${_subscription!.uuid}',
          );
          setSuccess();
        } else {
          print('handlePaymentCallback: Invalid callback response structure');
          setError(
            'Failed to process payment callback: Invalid response structure',
          );
        }
      } else {
        print(
          'handlePaymentCallback: Payment was not successful or missing transaction reference',
        );
        setError('Payment was not successful or missing transaction reference');
      }
    } catch (e) {
      print('handlePaymentCallback: Error occurred: $e');
      setError('Failed to process payment callback: $e');
    }
  }

  void selectPlan(Plan plan) {
    _selectedPlan = plan;
    print('selectPlan: Selected plan: ${plan.name}');
    notifyListeners();
  }

  void clearPaymentLink() {
    _paymentLink = null;
    print('clearPaymentLink: Payment link cleared');
    notifyListeners();
  }

  void clearSubscription() {
    _subscription = null;
    print('clearSubscription: Subscription cleared');
    notifyListeners();
  }

  void reset() {
    _plans = [];
    _selectedPlan = null;
    _paymentLink = null;
    _subscription = null;
    print('reset: Cleared all plan data');
    resetState();
  }
}
