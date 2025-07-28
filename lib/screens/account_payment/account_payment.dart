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
  bool _isButtonPressed = false; // Debouncing flag
  DateTime? _lastPurchaseAttempt; // Track purchase attempts

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
      _showDebugDialog('IAP Initialization', 'Starting IAP initialization...');
      
      final bool success = await planProvider.initializeIAP();
      setState(() {
        _isIAPInitialized = success;
      });
      
      if (success) {
        _showDebugDialog('IAP Initialization', 'IAP initialized successfully!');
      } else {
        _showDebugDialog('IAP Initialization', 'IAP initialization failed');
        _showIAPInitializationError();
      }
    } catch (e) {
      setState(() {
        _isIAPInitialized = false;
      });
      _showDebugDialog('IAP Initialization Error', 'Exception: $e');
      _showIAPInitializationError();
    }
  }

  void _showDebugDialog(String title, String message) {
    // Only show debug dialogs in non-production environment
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          title: Text(
            '[DEBUG] $title',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blue,
              fontSize: 14,
            ),
          ),
          content: Text(
            message,
            style: const TextStyle(fontSize: 12),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
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
    if (_isButtonPressed) return false;
    
    // Prevent rapid successive purchases (within 5 seconds)
    if (_lastPurchaseAttempt != null) {
      final timeDiff = DateTime.now().difference(_lastPurchaseAttempt!);
      if (timeDiff.inSeconds < 5) {
        return false;
      }
    }
    
    final planProvider = Provider.of<PlanProvider>(context, listen: false);
    return !planProvider.isLoading && !planProvider.isProcessingPurchase;
  }

  Future<void> _proceedToCheckout() async {
    if (!_canPurchase()) {
      _showDebugDialog('Purchase Blocked', 'Purchase attempt blocked - conditions not met');
      return;
    }

    final planProvider = Provider.of<PlanProvider>(context, listen: false);

    if (planProvider.selectedPlan == null) {
      _showDebugDialog('No Plan Selected', 'selectedPlan is null');
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

    // Set button as pressed and record attempt time
    setState(() {
      _isButtonPressed = true;
    });
    _lastPurchaseAttempt = DateTime.now();

    _showDebugDialog('Purchase Started', 'Starting purchase process for ${planProvider.selectedPlan!.name}');

    try {
      await _processIAPPayment();
    } catch (e) {
      _showDebugDialog('Purchase Exception', 'Exception during purchase: $e');
    } finally {
      // Reset button state after a delay to prevent rapid clicking
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _isButtonPressed = false;
          });
        }
      });
    }
  }

  Future<void> _processIAPPayment() async {
    final planProvider = Provider.of<PlanProvider>(context, listen: false);

    try {
      _showDebugDialog('Purchase Processing', 'Saving onboarding step and starting purchase');
      
      // Persist onboarding step as 'payment_processing'
      await OnboardingStateService.saveStep('payment_processing');
      
      // Start IAP purchase
      await planProvider.purchaseSubscription(
        planUuid: planProvider.selectedPlan!.uuid,
        userId: widget.userId,
      );

      _showDebugDialog('Purchase Initiated', 'Purchase request sent to provider');

      // Listen for purchase completion
      _listenForPurchaseCompletion(planProvider);
      
    } catch (e) {
      _showDebugDialog('Purchase Error', 'Error during purchase process: $e');
      
      CustomSnackBar.show(
        context,
        message: 'An error occurred during purchase: ${e.toString()}',
        isError: true,
      );
      planProvider.clearError();
      
      // Reset button state on error
      setState(() {
        _isButtonPressed = false;
      });
    }
  }

  void _listenForPurchaseCompletion(PlanProvider planProvider) {
    // Wait a bit for the purchase to process
    Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      _showDebugDialog('Purchase Status Check', 
        'State: ${planProvider.state}, HasError: ${planProvider.hasError}, Processing: ${planProvider.isProcessingPurchase}');

      if (planProvider.state == LoadingState.success && 
          planProvider.subscription != null && 
          !planProvider.isProcessingPurchase) {
        timer.cancel();
        _showDebugDialog('Purchase Success', 'Purchase completed successfully!');
        _showSuccessDialog();
        setState(() {
          _isButtonPressed = false;
        });
      } else if (planProvider.hasError && !planProvider.isProcessingPurchase) {
        timer.cancel();
        _showDebugDialog('Purchase Failed', 'Error: ${planProvider.errorMessage}');
        
        CustomSnackBar.show(
          context,
          message: planProvider.errorMessage ?? 'Purchase failed. Please try again.',
          isError: true,
        );
        planProvider.clearError();
        setState(() {
          _isButtonPressed = false;
        });
      } else if (timer.tick > 120) { // 60 seconds timeout
        timer.cancel();
        _showDebugDialog('Purchase Timeout', 'Purchase process timed out');
        
        CustomSnackBar.show(
          context,
          message: 'Purchase is taking longer than expected. Please check your purchase history.',
          isError: true,
        );
        setState(() {
          _isButtonPressed = false;
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
                  _isButtonPressed = false;
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

                // Debug info (remove in production)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withAlpha(30),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.blue.withAlpha(100)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '[DEBUG INFO]',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[800],
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        'IAP Initialized: $_isIAPInitialized',
                        style: TextStyle(color: Colors.blue[700], fontSize: 11),
                      ),
                      Text(
                        'Button Pressed: $_isButtonPressed',
                        style: TextStyle(color: Colors.blue[700], fontSize: 11),
                      ),
                      Text(
                        'Provider Loading: ${planProvider.isLoading}',
                        style: TextStyle(color: Colors.blue[700], fontSize: 11),
                      ),
                      Text(
                        'Processing Purchase: ${planProvider.isProcessingPurchase}',
                        style: TextStyle(color: Colors.blue[700], fontSize: 11),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

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
                  widget: (planProvider.isLoading || planProvider.isProcessingPurchase || _isButtonPressed)
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
                              : _isButtonPressed
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
  }
}