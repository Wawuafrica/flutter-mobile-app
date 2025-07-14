import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wawu_mobile/providers/plan_provider.dart';
import 'package:wawu_mobile/providers/user_provider.dart';
import 'package:wawu_mobile/services/onboarding_state_service.dart';
import 'package:wawu_mobile/screens/account_payment/account_payment.dart';
import 'package:wawu_mobile/widgets/plan_card/plan_card.dart';
import 'package:wawu_mobile/widgets/onboarding/onboarding_progress_indicator.dart';
// import 'package:wawu_mobile/utils/error_utils.dart'; // This utility might be replaced or integrated
import 'package:wawu_mobile/widgets/custom_snackbar.dart'; // Import CustomSnackBar
import 'package:wawu_mobile/widgets/full_ui_error_display.dart'; // Import FullErrorDisplay
import 'package:wawu_mobile/utils/constants/colors.dart'; // Import wawuColors

class Plan extends StatefulWidget {
  const Plan({super.key});

  @override
  State<Plan> createState() => _PlanState();
}

class _PlanState extends State<Plan> {
  // Flag to prevent showing multiple snackbars for the same error
  bool _hasShownError = false;

  @override
  void initState() {
    super.initState();
    // Persist onboarding step as 'plan' when user lands here
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await OnboardingStateService.saveStep('plan');
      context.read<PlanProvider>().fetchAllPlans();
    });
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
              planProvider.clearError(); // Clear error state
            } else if (!planProvider.hasError && _hasShownError) {
              _hasShownError = false;
            }
          });

          if (planProvider.isLoading && planProvider.plans.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          // Display full error screen for critical loading failures for plans
          if (planProvider.hasError &&
              planProvider.plans.isEmpty &&
              !planProvider.isLoading) {
            return FullErrorDisplay(
              errorMessage:
                  planProvider.errorMessage ??
                  'Failed to load plans. Please try again.',
              onRetry: () {
                planProvider.fetchAllPlans();
              },
              onContactSupport: () {
                _showErrorSupportDialog(
                  context,
                  'If this problem persists, please contact our support team. We are here to help!',
                );
              },
            );
          }

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

              // Plans section - takes remaining space
              Expanded(
                child:
                    planProvider.plans.isEmpty
                        ? const Center(child: Text('No plans available'))
                        : Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: planProvider.plans.length,
                            separatorBuilder:
                                (context, index) => const SizedBox(width: 20),
                            itemBuilder: (context, index) {
                              final plan = planProvider.plans[index];
                              return SizedBox(
                                width: 300, // Fixed width for cards
                                child: PlanCard(
                                  heading: plan.name,
                                  desc:
                                      plan.description ??
                                      'No description available',
                                  price: plan.amount,
                                  currency: plan.currency,
                                  features:
                                      plan.features
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
                                      [],
                                  function: () {
                                    planProvider.selectPlan(plan);
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
