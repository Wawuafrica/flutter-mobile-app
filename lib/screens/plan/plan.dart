import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:wawu_mobile/providers/plan_provider.dart';
import 'package:wawu_mobile/providers/user_provider.dart';
import 'package:wawu_mobile/screens/main_screen/main_screen.dart';
import 'package:wawu_mobile/services/onboarding_state_service.dart';
import 'package:wawu_mobile/screens/account_payment/account_payment.dart';
import 'package:wawu_mobile/widgets/plan_card/plan_card.dart';
import 'package:wawu_mobile/widgets/onboarding/onboarding_progress_indicator.dart';
import 'package:wawu_mobile/widgets/custom_snackbar.dart';
import 'package:wawu_mobile/widgets/full_ui_error_display.dart';
import 'package:wawu_mobile/utils/constants/colors.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class Plan extends StatefulWidget {
  const Plan({super.key});

  @override
  State<Plan> createState() => _PlanState();
}

class _PlanState extends State<Plan> {
  bool _hasShownError = false;
  bool _isLoadingStoreProducts = false;
  List<ProductDetails> _storeProducts = [];
  String? _storeError;
  bool _subscriptionCheckInProgress = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // First, verify if the user already has a subscription.
      await _verifySubscriptionStatus();

      // If they don't, proceed with loading plans.
      await OnboardingStateService.saveStep('plan');
      await _initializeAndLoadStoreProducts();
      context.read<PlanProvider>().fetchAllPlans();
    });
  }

  /// Verifies the user's current subscription status. If a subscription is active,
  /// it redirects the user back to the MainScreen.
  Future<void> _verifySubscriptionStatus() async {
    if (_subscriptionCheckInProgress) return;

    setState(() {
      _subscriptionCheckInProgress = true;
    });

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentUser = userProvider.currentUser;

    if (currentUser == null || currentUser.role?.toLowerCase() == 'buyer') {
      debugPrint('[PlanScreen] No user or user is a buyer, stopping check.');
      setState(() => _subscriptionCheckInProgress = false);
      return;
    }

    final connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.none) {
      debugPrint('[PlanScreen] No internet. Cannot verify subscription.');
      if (mounted) {
        CustomSnackBar.show(
          context,
          message: 'No internet. Cannot verify current subscription status.',
          isError: true,
        );
      }
      setState(() => _subscriptionCheckInProgress = false);
      return;
    }

    int getRoleId(String? roleName) {
      switch (roleName?.toUpperCase()) {
        case 'BUYER':
          return 1;
        case 'PROFESSIONAL':
          return 2;
        case 'ARTISAN':
          return 3;
        default:
          return 0;
      }
    }

    final int roleId = getRoleId(currentUser.role);

    try {
      final planProvider = Provider.of<PlanProvider>(context, listen: false);
      await planProvider.fetchUserSubscriptionDetails(currentUser.uuid, roleId);

      if (planProvider.hasActiveSubscription && mounted) {
        debugPrint(
          '[PlanScreen] Active subscription found. Redirecting to MainScreen.',
        );
        CustomSnackBar.show(
          context,
          message: 'Active subscription found. Redirecting...',
          isError: false,
        );
        await OnboardingStateService.setComplete();
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
      } else {
        debugPrint(
          '[PlanScreen] No active subscription. User can select a plan.',
        );
      }
    } catch (e) {
      debugPrint('[PlanScreen] Error during subscription verification: $e');
      if (mounted) {
        CustomSnackBar.show(
          context,
          message:
              'Could not verify subscription status. Please select a plan.',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _subscriptionCheckInProgress = false;
        });
      }
    }
  }

  Future<void> _initializeAndLoadStoreProducts() async {
    setState(() {
      _isLoadingStoreProducts = true;
      _storeError = null;
    });

    try {
      final planProvider = Provider.of<PlanProvider>(context, listen: false);
      final bool iapInitialized = await planProvider.initializeIAP();

      if (!iapInitialized) {
        setState(() {
          _storeError = 'Unable to connect to app store';
          _isLoadingStoreProducts = false;
        });
        return;
      }

      _storeProducts = planProvider.iapProducts;

      setState(() {
        _isLoadingStoreProducts = false;
      });
    } catch (e) {
      debugPrint('Error loading store products: $e');
      setState(() {
        _storeError = 'Failed to load store prices: $e';
        _isLoadingStoreProducts = false;
      });
    }
  }

  Map<String, dynamic> _getStoreProductInfo() {
    if (_storeProducts.isEmpty) {
      return {
        'price': 'Loading...',
        'currency': '',
        'title': 'Wawu Premium',
        'description': 'Annual subscription to Wawu premium features',
      };
    }

    final product = _storeProducts.first;
    return {
      'price': _extractPriceAmount(product.price),
      'currency': _extractCurrency(product.price),
      'title': product.title,
      'description':
          product.description.isNotEmpty
              ? product.description
              : 'Annual subscription to Wawu premium features',
      'formattedPrice': product.price,
    };
  }

  String _extractPriceAmount(String formattedPrice) {
    final RegExp numberRegex = RegExp(r'[\d,]+\.?\d*');
    final match = numberRegex.firstMatch(formattedPrice);
    return match?.group(0)?.replaceAll(',', '') ?? '0';
  }

  String _extractCurrency(String formattedPrice) {
    if (formattedPrice.contains('\$')) return '\$';
    if (formattedPrice.contains('€')) return '€';
    if (formattedPrice.contains('£')) return '£';
    if (formattedPrice.contains('₦')) return '₦';
    if (formattedPrice.contains('¥')) return '¥';

    final RegExp currencyRegex = RegExp(r'[^\d\s.,]+');
    final match = currencyRegex.firstMatch(formattedPrice);
    return match?.group(0) ?? '\$';
  }

  void _showErrorSupportDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          title: const Text(
            'Contact Support',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: wawuColors.primary,
            ),
          ),
          content: Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[700]),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text(
                'OK',
                style: TextStyle(color: wawuColors.buttonSecondary),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: const Text(
              'Select A Plan',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            centerTitle: true,
            actions: [
              OnboardingProgressIndicator(
                currentStep: 'plan',
                steps: const [
                  'account_type',
                  'category_selection',
                  'subcategory_selection',
                  'profile_update',
                  'plan',
                  'payment',
                  'payment_processing',
                  'verify_payment',
                  'disclaimer',
                ],
                stepLabels: const {
                  'account_type': 'Account',
                  'category_selection': 'Category',
                  'subcategory_selection': 'Subcategory',
                  'profile_update': 'Profile',
                  'plan': 'Plan',
                  'payment': 'Payment',
                  'payment_processing': 'Processing',
                  'verify_payment': 'Verify',
                  'disclaimer': 'Disclaimer',
                },
              ),
            ],
          ),
          body: Consumer2<PlanProvider, UserProvider>(
            builder: (context, planProvider, userProvider, child) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (planProvider.hasError &&
                    planProvider.errorMessage != null &&
                    !_hasShownError) {
                  CustomSnackBar.show(
                    context,
                    message: planProvider.errorMessage!,
                    isError: true,
                    actionLabel: 'RETRY',
                    onActionPressed: () {
                      planProvider.fetchAllPlans();
                    },
                  );
                  _hasShownError = true;
                  planProvider.clearError();
                } else if (!planProvider.hasError && _hasShownError) {
                  _hasShownError = false;
                }
              });

              if ((planProvider.isLoading && planProvider.plans.isEmpty) ||
                  _isLoadingStoreProducts) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Loading subscription plans...'),
                    ],
                  ),
                );
              }

              if (_storeError != null && _storeProducts.isEmpty) {
                return FullErrorDisplay(
                  errorMessage: _storeError!,
                  onRetry: _initializeAndLoadStoreProducts,
                  onContactSupport: () {
                    _showErrorSupportDialog(
                      context,
                      'Unable to load subscription prices. Please check your internet connection and try again.',
                    );
                  },
                );
              }

              final storeInfo = _getStoreProductInfo();

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          clipBehavior: Clip.hardEdge,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                          ),
                          child:
                              userProvider.currentUser?.profileImage != null
                                  ? Image.network(
                                    userProvider.currentUser!.profileImage!,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            Image.asset(
                                              'assets/images/other/avatar.webp',
                                              fit: BoxFit.cover,
                                            ),
                                  )
                                  : Image.asset(
                                    'assets/images/other/avatar.webp',
                                    fit: BoxFit.cover,
                                  ),
                        ),
                        const SizedBox(height: 15),
                        Text(
                          userProvider.currentUser != null
                              ? '${userProvider.currentUser!.firstName} ${userProvider.currentUser!.lastName}'
                              : 'Guest User',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          userProvider.currentUser?.role ?? 'Unknown',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color.fromARGB(255, 125, 125, 125),
                            fontWeight: FontWeight.w200,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child:
                          _storeProducts.isEmpty
                              ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.store_outlined,
                                      size: 64,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'No subscription plans available',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Please check your internet connection and try again',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 24),
                                    ElevatedButton(
                                      onPressed:
                                          _initializeAndLoadStoreProducts,
                                      child: const Text('Retry'),
                                    ),
                                  ],
                                ),
                              )
                              : ListView.separated(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                ),
                                itemCount: 1,
                                separatorBuilder:
                                    (context, index) =>
                                        const SizedBox(width: 20),
                                itemBuilder: (context, index) {
                                  final backendPlan =
                                      planProvider.plans.isNotEmpty
                                          ? planProvider.plans.first
                                          : null;

                                  return SizedBox(
                                    width: 300,
                                    child: PlanCard(
                                      heading:
                                          storeInfo['title'] ?? 'Wawu Premium',
                                      desc:
                                          storeInfo['description'] ??
                                          'Annual subscription with premium features',
                                      price:
                                          double.tryParse(storeInfo['price']) ??
                                          0.0,
                                      currency: storeInfo['currency'] ?? '\$',
                                      features:
                                          backendPlan?.features
                                              ?.map(
                                                (feature) => {
                                                  'check':
                                                      feature.value == 'yes' ||
                                                      (double.tryParse(
                                                            feature.value
                                                                .toString(),
                                                          ) !=
                                                          null),
                                                  'text':
                                                      feature.description ??
                                                      feature.name,
                                                },
                                              )
                                              .toList() ??
                                          [
                                            {
                                              'check': true,
                                              'text': 'Verified Badge',
                                            },
                                            {
                                              'check': true,
                                              'text': 'Standard Account',
                                            },
                                            {
                                              'check': true,
                                              'text': '4 Active Gigs per User',
                                            },
                                            {
                                              'check': true,
                                              'text': 'Basic Support',
                                            },
                                          ],
                                      function: () {
                                        final storePlan =
                                            planProvider.plans.isNotEmpty
                                                ? planProvider.plans.first
                                                    .copyWith(
                                                      name: storeInfo['title'],
                                                      amount:
                                                          double.tryParse(
                                                            storeInfo['price'],
                                                          ) ??
                                                          0.0,
                                                      currency:
                                                          storeInfo['currency'],
                                                    )
                                                : null;

                                        if (storePlan != null) {
                                          planProvider.selectPlan(storePlan);
                                        }

                                        final userId =
                                            userProvider.currentUser?.uuid;
                                        if (userId != null) {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder:
                                                  (context) => AccountPayment(
                                                    userId: userId,
                                                  ),
                                            ),
                                          );
                                        } else {
                                          CustomSnackBar.show(
                                            context,
                                            message:
                                                'User not logged in. Please log in to select a plan.',
                                            isError: true,
                                          );
                                        }
                                      },
                                    ),
                                  );
                                },
                              ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              );
            },
          ),
        ),
        if (_subscriptionCheckInProgress)
          Material(
            child: Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'Verifying current subscription...',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
