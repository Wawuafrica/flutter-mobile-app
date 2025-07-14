import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wawu_mobile/models/plan.dart' as plan_model;
import 'package:wawu_mobile/providers/plan_provider.dart';
import 'package:wawu_mobile/providers/base_provider.dart';
import 'package:wawu_mobile/screens/account_payment/disclaimer/disclaimer.dart';
import 'package:wawu_mobile/services/onboarding_state_service.dart';
import 'package:wawu_mobile/screens/account_payment/payment_webview.dart';
import 'package:wawu_mobile/screens/plan/plan.dart';
import 'package:wawu_mobile/utils/constants/colors.dart';
import 'package:wawu_mobile/widgets/custom_button/custom_button.dart';
import 'package:wawu_mobile/widgets/custom_row_single_column/custom_row_single_column.dart';
import 'package:wawu_mobile/widgets/onboarding/onboarding_progress_indicator.dart';
import 'package:wawu_mobile/widgets/payment/payment_success_dialog.dart';
// import 'package:wawu_mobile/widgets/payment/payment_error_dialog.dart'; // Removed
// import 'package:wawu_mobile/widgets/custom_textfield/custom_textfield.dart';
import 'package:wawu_mobile/widgets/custom_snackbar.dart'; // Import CustomSnackBar
import 'package:wawu_mobile/widgets/full_ui_error_display.dart'; // Import FullErrorDisplay

class AccountPayment extends StatefulWidget {
  final String userId; // Pass user ID from previous screen

  const AccountPayment({super.key, required this.userId});

  @override
  State<AccountPayment> createState() => _AccountPaymentState();
}

class _AccountPaymentState extends State<AccountPayment> {
  final TextEditingController _discountController = TextEditingController();
  double discountPercentage = 0.0;
  double calculatedTotal = 0.0;

  // Flag to prevent showing multiple snackbars for the same error
  bool _hasShownError = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await OnboardingStateService.saveStep('payment');
      final planProvider = Provider.of<PlanProvider>(context, listen: false);
      // --- Onboarding Plan Restore Logic ---
      if (planProvider.selectedPlan == null) {
        final planJson = await OnboardingStateService.getPlan();
        if (planJson != null) {
          try {
            final plan = plan_model.Plan.fromJson(planJson);
            planProvider.selectPlan(plan);
            _calculateTotal();
          } catch (e) {
            // ignore restore error
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

  // Function to show the support dialog (can be reused)
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

  Future<void> _proceedToCheckout() async {
    final planProvider = Provider.of<PlanProvider>(context, listen: false);

    if (planProvider.selectedPlan == null) {
      // Show full error display if no plan is selected
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => FullErrorDisplay(
              errorMessage:
                  'No plan selected. Please go back and select a plan.',
              onRetry: () {
                Navigator.of(context).pop(); // Dismiss error dialog
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

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Generate payment link
      await planProvider.generatePaymentLink(
        planUuid: planProvider.selectedPlan!.uuid,
        userId: widget.userId,
      );

      // Close loading dialog
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (planProvider.paymentLink != null &&
          planProvider.paymentLink!.link.isNotEmpty) {
        // Persist onboarding step as 'payment_processing'
        await OnboardingStateService.saveStep('payment_processing');
        // Navigate to payment webview
        final paymentResult = await Navigator.push<Map<String, String>>(
          context,
          MaterialPageRoute(
            builder:
                (context) => PaymentWebView(
                  paymentUrl: planProvider.paymentLink!.link,
                  redirectUrl:
                      'https://staging.wawuafrica.com/api/payment/callback', // Replace with your actual redirect URL
                ),
          ),
        );

        // Handle payment result
        if (paymentResult != null) {
          await _handlePaymentResult(paymentResult);
        }
      } else {
        CustomSnackBar.show(
          context,
          message:
              planProvider.errorMessage ??
              'Failed to generate payment link. Please try again.',
          isError: true,
        );
        planProvider.clearError(); // Clear error state
      }
    } catch (e) {
      // Close loading dialog
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      CustomSnackBar.show(
        context,
        message: 'An error occurred during checkout: ${e.toString()}',
        isError: true,
      );
      planProvider.clearError(); // Clear error state
    }
  }

  Future<void> _handlePaymentResult(Map<String, String> result) async {
    // Persist onboarding step as 'verify_payment'
    await OnboardingStateService.saveStep('verify_payment');
    // The full redirect URL is now passed in the 'redirectUrl' key.
    final String? redirectUrl = result['redirectUrl'];

    if (redirectUrl == null || redirectUrl.isEmpty) {
      CustomSnackBar.show(
        context,
        message: 'Payment verification failed: Missing redirect URL.',
        isError: true,
      );
      return;
    }

    // Show a loading indicator while we verify the payment.
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final planProvider = Provider.of<PlanProvider>(context, listen: false);
    try {
      // Directly call the provider with the full redirect URL.
      await planProvider.handlePaymentCallback(redirectUrl);

      // Close the loading dialog.
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (planProvider.state == LoadingState.success) {
        _showSuccessDialog();
      } else {
        CustomSnackBar.show(
          context,
          message: planProvider.errorMessage ?? 'Payment verification failed.',
          isError: true,
        );
        planProvider.clearError(); // Clear error state
      }
    } catch (e) {
      // Close the loading dialog in case of an unexpected error.
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      CustomSnackBar.show(
        context,
        message:
            'An unexpected error occurred during payment verification: ${e.toString()}',
        isError: true,
      );
      planProvider.clearError(); // Clear error state
    }
  }

  void _showSuccessDialog() async {
    final planProvider = Provider.of<PlanProvider>(context, listen: false);
    final result = await showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) =>
              PaymentSuccessDialog(planName: planProvider.selectedPlan?.name),
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
                // Assuming a method to retry the last failed operation,
                // or navigate back to select plan.
                // For simplicity, we'll just clear the error here.
                planProvider.clearError();
              },
            );
            _hasShownError = true;
            planProvider.clearError(); // Clear error state
          } else if (!planProvider.hasError && _hasShownError) {
            _hasShownError = false;
          }
        });

        final selectedPlan = planProvider.selectedPlan;

        if (selectedPlan == null) {
          // Fallback UI if no plan is selected or restored
          return Scaffold(
            appBar: AppBar(title: const Text('Payment')),
            body: FullErrorDisplay(
              errorMessage:
                  'No plan selected. Please go back and select a plan.',
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

                // // Discount code field (commented out in original, keeping it commented)
                // Row(
                //   children: [
                //     Expanded(
                //       child: CustomTextfield(
                //         labelText: 'Discount Code',
                //         controller: _discountController,
                //       ),
                //     ),
                //     const SizedBox(width: 10),
                //     ElevatedButton(
                //       onPressed: _applyDiscount,
                //       style: ElevatedButton.styleFrom(
                //         backgroundColor: wawuColors.primary,
                //         foregroundColor: Colors.white,
                //         padding: const EdgeInsets.symmetric(
                //           horizontal: 20,
                //           vertical: 15,
                //         ),
                //       ),
                //       child: const Text('Apply'),
                //     ),
                //   ],
                // ),
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
                          rightText:
                              '${discountPercentage.toStringAsFixed(0)}%',
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
                          rightText:
                              '${selectedPlan.currency} ${calculatedTotal.toStringAsFixed(0)}',
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

                // Features section (if available) (commented out in original, keeping it commented)
                // if (selectedPlan.features != null &&
                //     selectedPlan.features!.isNotEmpty) ...[
                //   Container(
                //     width: double.infinity,
                //     padding: const EdgeInsets.all(20),
                //     decoration: BoxDecoration(
                //       borderRadius: BorderRadius.circular(15),
                //       color: Colors.grey.withAlpha(30),
                //     ),
                //     child: Column(
                //       crossAxisAlignment: CrossAxisAlignment.start,
                //       children: [
                //         const Text(
                //           'Plan Features:',
                //           style: TextStyle(
                //             fontSize: 16,
                //             fontWeight: FontWeight.w600,
                //           ),
                //         ),
                //         const SizedBox(height: 12),
                //         ...selectedPlan.features!
                //             .map(
                //               (feature) => Padding(
                //                 padding: const EdgeInsets.only(bottom: 8),
                //                 child: Row(
                //                   children: [
                //                     Icon(
                //                       Icons.check_circle,
                //                       color: wawuColors.primary,
                //                       size: 16,
                //                     ),
                //                     const SizedBox(width: 8),
                //                     Expanded(
                //                       child: Text(
                //                         '${feature.name}: ${feature.value}',
                //                         style: const TextStyle(fontSize: 14),
                //                       ),
                //                     ),
                //                   ],
                //                 ),
                //               ),
                //             )
                //             .toList(),
                //       ],
                //     ),
                //   ),
                //   const SizedBox(height: 20),
                // ],

                // Proceed button
                CustomButton(
                  function: planProvider.isLoading ? null : _proceedToCheckout,
                  widget:
                      planProvider.isLoading
                          ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                          : const Text(
                            'Proceed To Checkout',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  color: wawuColors.primary,
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
