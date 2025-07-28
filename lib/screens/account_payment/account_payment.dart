import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wawu_mobile/models/plan.dart' as plan_model;
import 'package:wawu_mobile/providers/plan_provider.dart';
import 'package:wawu_mobile/providers/base_provider.dart';
import 'package:wawu_mobile/screens/account_payment/disclaimer/disclaimer.dart';
import 'package:wawu_mobile/services/onboarding_state_service.dart';
import 'package:wawu_mobile/screens/plan/plan.dart';
import 'package:wawu_mobile/utils/constants/colors.dart';
import 'package:wawu_mobile/widgets/custom_button/custom_button.dart';
import 'package:wawu_mobile/widgets/custom_row_single_column/custom_row_single_column.dart';
import 'package:wawu_mobile/widgets/onboarding/onboarding_progress_indicator.dart';
import 'package:wawu_mobile/widgets/payment/payment_success_dialog.dart';
import 'package:wawu_mobile/widgets/custom_snackbar.dart';
import 'package:wawu_mobile/widgets/full_ui_error_display.dart';

class AccountPayment extends StatefulWidget {
  final String userId;

  const AccountPayment({super.key, required this.userId});

  @override
  State<AccountPayment> createState() => _AccountPaymentState();
}

class _AccountPaymentState extends State<AccountPayment> {
  final TextEditingController _discountController = TextEditingController();
  double discountPercentage = 0.0;
  double calculatedTotal = 0.0;
  bool _hasShownError = false;
  bool _isIAPInitialized = false;
  bool _purchaseInProgress = false; // Track purchase state locally
  DateTime? _lastPurchaseAttempt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await OnboardingStateService.saveStep('payment');
      final planProvider = Provider.of<PlanProvider>(context, listen: false);
      
      // Initialize IAP
      await _initializeIAP();
      
      // Restore plan if needed
      if (planProvider.selectedPlan == null) {
        final planJson = await OnboardingStateService.getPlan();
        if (planJson != null) {
          try {
            final plan = plan_model.Plan.fromJson(planJson);
            planProvider.selectPlan(plan);
            _calculateTotal();
          } catch (e) {
            _calculateTotal();
          }
        } else {
          _calculateTotal();
        }
      } else {
        _calculateTotal();
      }
    });
  }

  Future<void> _initializeIAP() async {
    final planProvider = Provider.of<PlanProvider>(context, listen: false);
    
    try {
      final bool success = await planProvider.initializeIAP();
      setState(() {
        _isIAPInitialized = success;
      });
      
      if (!success) {
        _showIAPInitializationError();
      }
    } catch (e) {
      setState(() {
        _isIAPInitialized = false;
      });
      _showIAPInitializationError();
    }
  }

  void _showIAPInitializationError() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          title: const Text(
            'Payment Setup Issue',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: wawuColors.primary,
            ),
          ),
          content: const Text(
            'Unable to initialize in-app purchases. You can try again or contact support.',
            textAlign: TextAlign.center,
          ),
          actions: <Widget>[
            TextButton(
              child: const Text(
                'Try Again',
                style: TextStyle(color: wawuColors.primary),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                _initializeIAP();
              },
            ),
            TextButton(
              child: const Text(
                'Contact Support',
                style: TextStyle(color: wawuColors.buttonSecondary),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                _showErrorSupportDialog(
                  context,
                  'In-app purchases are not available on your device. Please contact our support team for assistance.',
                );
              },
            ),
          ],
        );
      },
    );
  }

  void _calculateTotal() {
    final planProvider = Provider.of<PlanProvider>(context, listen: false);
    if (planProvider.selectedPlan != null) {
      double baseAmount = planProvider.selectedPlan!.amount;
      double discountAmount = baseAmount * (discountPercentage / 100);
      setState(() {
        calculatedTotal = baseAmount - discountAmount;
      });
    }
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

  bool _canPurchase() {
    if (!_isIAPInitialized) return false;
    if (_purchaseInProgress) return false;
    
    // Prevent rapid successive purchases (within 5 seconds)
    if (_lastPurchaseAttempt != null) {
      final timeDiff = DateTime.now().difference(_lastPurchaseAttempt!);
      if (timeDiff.inSeconds < 5) {
        return false;
      }
    }
    
    final planProvider = Provider.of<PlanProvider>(context, listen: false);
    return !planProvider.isLoading;
  }

  Future<void> _proceedToCheckout() async {
    if (!_canPurchase()) {
      return;
    }

    final planProvider = Provider.of<PlanProvider>(context, listen: false);

    if (planProvider.selectedPlan == null) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => FullErrorDisplay(
          errorMessage: 'No plan selected. Please go back and select a plan.',
          onRetry: () {
            Navigator.of(context).pop();
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const Plan()),
            );
          },
          onContactSupport: () {
            _showErrorSupportDialog(
              context,
              'You must select a plan before proceeding to checkout. If you are having trouble selecting a plan, please contact support.',
            );
          },
        ),
      );
      return;
    }

    // Set purchase as in progress
    setState(() {
      _purchaseInProgress = true;
    });
    _lastPurchaseAttempt = DateTime.now();

    try {
      await _processIAPPayment();
    } catch (e) {
      debugPrint('Purchase exception: $e');
      CustomSnackBar.show(
        context,
        message: 'An error occurred during purchase: ${e.toString()}',
        isError: true,
      );
      setState(() {
        _purchaseInProgress = false;
      });
    }
  }

  Future<void> _processIAPPayment() async {
    final planProvider = Provider.of<PlanProvider>(context, listen: false);

    try {
      // Persist onboarding step as 'payment_processing'
      await OnboardingStateService.saveStep('payment_processing');
      
      // Start IAP purchase
      await planProvider.purchaseSubscription(
        planUuid: planProvider.selectedPlan!.uuid,
        userId: widget.userId,
      );

      // Listen for purchase completion using addListener instead of periodic timer
      _listenForPurchaseCompletion(planProvider);
      
    } catch (e) {
      debugPrint('Error during purchase process: $e');
      
      CustomSnackBar.show(
        context,
        message: 'An error occurred during purchase: ${e.toString()}',
        isError: true,
      );
      planProvider.clearError();
      
      // Reset purchase state on error
      setState(() {
        _purchaseInProgress = false;
      });
    }
  }

  void _listenForPurchaseCompletion(PlanProvider planProvider) {
    // Add a one-time listener to the provider
    void listener() {
      if (!mounted) {
        planProvider.removeListener(listener);
        return;
      }

      // Check if purchase completed successfully
      if (planProvider.state == LoadingState.success && !planProvider.isProcessingPurchase) {
        planProvider.removeListener(listener);
        _showSuccessDialog();
        setState(() {
          _purchaseInProgress = false;
        });
      } 
      // Check if purchase failed
      else if (planProvider.hasError && !planProvider.isProcessingPurchase) {
        planProvider.removeListener(listener);
        
        CustomSnackBar.show(
          context,
          message: planProvider.errorMessage ?? 'Purchase failed. Please try again.',
          isError: true,
        );
        planProvider.clearError();
        setState(() {
          _purchaseInProgress = false;
        });
      }
    }

    planProvider.addListener(listener);

    // Set a timeout to prevent infinite waiting
    Timer(const Duration(seconds: 60), () {
      if (mounted && _purchaseInProgress) {
        planProvider.removeListener(listener);
        
        CustomSnackBar.show(
          context,
          message: 'Purchase is taking longer than expected. Please check your purchase history.',
          isError: true,
        );
        setState(() {
          _purchaseInProgress = false;
        });
      }
    });
  }

  void _showSuccessDialog() async {
    final planProvider = Provider.of<PlanProvider>(context, listen: false);
    final result = await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PaymentSuccessDialog(planName: planProvider.selectedPlan?.name),
    );
    if (result == true) {
      await OnboardingStateService.setComplete();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const Disclaimer()),
        (Route<dynamic> route) => false,
      );
    }
  }

  @override
  void dispose() {
    _discountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PlanProvider>(
      builder: (context, planProvider, child) {
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
                planProvider.clearError();
                setState(() {
                  _purchaseInProgress = false;
                });
              },
            );
            _hasShownError = true;
            planProvider.clearError();
          } else if (!planProvider.hasError && _hasShownError) {
            _hasShownError = false;
          }
        });

        final selectedPlan = planProvider.selectedPlan;

        if (selectedPlan == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Payment')),
            body: FullErrorDisplay(
              errorMessage: 'No plan selected. Please go back and select a plan.',
              onRetry: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const Plan()),
                );
              },
              onContactSupport: () {
                _showErrorSupportDialog(
                  context,
                  'You must select a plan before proceeding to checkout. If you are having trouble selecting a plan, please contact support.',
                );
              },
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Payment',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            actions: [
              OnboardingProgressIndicator(
                currentStep: 'payment',
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
          body: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 10.0,
            ),
            child: ListView(
              children: [
                Text(
                  'Please note this is a ${selectedPlan.interval} subscription',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 20),

                // Plan details card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    color: wawuColors.primary.withAlpha(30),
                    border: Border.all(
                      color: wawuColors.primary.withAlpha(100),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selectedPlan.name,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: wawuColors.primary,
                        ),
                      ),
                      if (selectedPlan.description != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          selectedPlan.description!,
                          style: TextStyle(
                            fontSize: 14,
                            color: wawuColors.primary.withAlpha(180),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      Text(
                        '${selectedPlan.currency} ${selectedPlan.amount.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: wawuColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Payment method status
                if (!_isIAPInitialized) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.withAlpha(30),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.red.withAlpha(100)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error, color: Colors.red),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'In-app purchases are not available. Please try again or contact support.',
                            style: TextStyle(color: Colors.red[800]),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Payment summary
                Container(
                  width: double.infinity,
                  height: 160,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: wawuColors.primary,
                  ),
                  padding: const EdgeInsets.all(30.0),
                  child: Column(
                    children: [
                      Expanded(
                        child: CustomRowSingleColumn(
                          leftText: 'Subscription Plan',
                          leftTextStyle: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          rightText: selectedPlan.name,
                          rightTextStyle: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Expanded(
                        child: CustomRowSingleColumn(
                          leftText: 'Discount',
                          leftTextStyle: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                          rightText: '${discountPercentage.toStringAsFixed(0)}%',
                          rightTextStyle: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                      Expanded(
                        child: CustomRowSingleColumn(
                          leftText: 'Total',
                          leftTextStyle: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          rightText: '${selectedPlan.currency} ${calculatedTotal.toStringAsFixed(0)}',
                          rightTextStyle: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Proceed button
                CustomButton(
                  function: _canPurchase() ? _proceedToCheckout : null,
                  widget: (planProvider.isLoading || _purchaseInProgress)
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          !_isIAPInitialized 
                              ? 'In-App Purchase Unavailable'
                              : _purchaseInProgress
                                  ? 'Processing...'
                                  : 'Subscribe Now',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                  color: !_canPurchase() ? Colors.grey : wawuColors.primary,
                  textColor: Colors.white,
                ),
              ],
            ),
          ),
        );
      },
    );
  }}