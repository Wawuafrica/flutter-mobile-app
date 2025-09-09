import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:wawu_mobile/providers/plan_provider.dart';
import 'package:wawu_mobile/providers/user_provider.dart';
import 'package:wawu_mobile/screens/account_payment/disclaimer/disclaimer.dart';
import 'package:wawu_mobile/services/onboarding_state_service.dart';
import 'package:wawu_mobile/screens/account_payment/account_payment.dart';
import 'package:wawu_mobile/widgets/plan_card/plan_card.dart';
import 'package:wawu_mobile/widgets/onboarding/onboarding_progress_indicator.dart';
import 'package:wawu_mobile/widgets/custom_snackbar.dart';
import 'package:wawu_mobile/widgets/full_ui_error_display.dart';
import 'package:wawu_mobile/utils/constants/colors.dart';

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await OnboardingStateService.saveStep('plan');

      // Initialize IAP and load store products
      await _initializeAndLoadStoreProducts();

      // Still fetch backend plans for features and descriptions
      context.read<PlanProvider>().fetchAllPlans();
    });
  }

  Future<void> _initializeAndLoadStoreProducts() async {
    setState(() {
      _isLoadingStoreProducts = true;
      _storeError = null;
    });

    try {
      final planProvider = Provider.of<PlanProvider>(context, listen: false);

      // Initialize IAP
      final bool iapInitialized = await planProvider.initializeIAP();

      if (!iapInitialized) {
        setState(() {
          _storeError = 'Unable to connect to app store';
          _isLoadingStoreProducts = false;
        });
        return;
      }

      // Get store products
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

  // Get store product details for display
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
      'formattedPrice': product.price, // Full formatted price like "$9.99/year"
    };
  }

  // Extract numeric price from formatted price string
  String _extractPriceAmount(String formattedPrice) {
    // Remove currency symbols and extract numbers
    final RegExp numberRegex = RegExp(r'[\d,]+\.?\d*');
    final match = numberRegex.firstMatch(formattedPrice);
    return match?.group(0)?.replaceAll(',', '') ?? '0';
  }

  // Extract currency symbol from formatted price
  String _extractCurrency(String formattedPrice) {
    // Common currency symbols
    if (formattedPrice.contains('\$')) return '\$';
    if (formattedPrice.contains('€')) return '€';
    if (formattedPrice.contains('£')) return '£';
    if (formattedPrice.contains('₦')) return '₦';
    if (formattedPrice.contains('¥')) return '¥';

    // Extract first non-digit, non-space character
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
                //MUST REMOVE BEFORE PRODUCTION ////////////////////////////////////
                // OnboardingStateService.saveStep('disclaimer');
                // Navigator.push(
                //   context,
                //   MaterialPageRoute(builder: (context) => Disclaimer()),
                // );
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          // Listen for errors from PlanProvider and display SnackBar
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

          // Show loading if both backend and store are loading
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

          // Show error if store products failed to load
          if (_storeError != null && _storeProducts.isEmpty) {
            return FullErrorDisplay(
              errorMessage: _storeError!,
              onRetry: () {
                _initializeAndLoadStoreProducts();
              },
              onContactSupport: () {
                _showErrorSupportDialog(
                  context,
                  'Unable to load subscription prices from the app store. Please check your internet connection and try again.',
                );
              },
            );
          }

          // Get store product information
          final storeInfo = _getStoreProductInfo();

          return Column(
            children: [
              // Header section with user info
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      clipBehavior: Clip.hardEdge,
                      decoration: const BoxDecoration(shape: BoxShape.circle),
                      child:
                          userProvider.currentUser?.profileImage != null
                              ? Image.network(
                                userProvider.currentUser!.profileImage!,
                                fit: BoxFit.cover,
                                errorBuilder:
                                    (context, error, stackTrace) => Image.asset(
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

              // Plans section - now using store prices
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
                                  onPressed: _initializeAndLoadStoreProducts,
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          )
                          : ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount:
                                1, // We'll show one plan card with store info
                            separatorBuilder:
                                (context, index) => const SizedBox(width: 20),
                            itemBuilder: (context, index) {
                              // Use backend plan features if available, otherwise use default
                              final backendPlan =
                                  planProvider.plans.isNotEmpty
                                      ? planProvider.plans.first
                                      : null;

                              return SizedBox(
                                width: 300,
                                child: PlanCard(
                                  heading: storeInfo['title'] ?? 'Wawu Premium',
                                  desc:
                                      storeInfo['description'] ??
                                      'Annual subscription with premium features',
                                  price:
                                      double.tryParse(storeInfo['price']) ??
                                      0.0,
                                  currency: storeInfo['currency'] ?? '\$',
                                  // formattedPrice: storeInfo['formattedPrice'], // Add this if PlanCard supports it
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
                                    // Create a plan object with store information
                                    final storePlan =
                                        planProvider.plans.isNotEmpty
                                            ? planProvider.plans.first.copyWith(
                                              name: storeInfo['title'],
                                              amount:
                                                  double.tryParse(
                                                    storeInfo['price'],
                                                  ) ??
                                                  0.0,
                                              currency: storeInfo['currency'],
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
    );
  }
}
