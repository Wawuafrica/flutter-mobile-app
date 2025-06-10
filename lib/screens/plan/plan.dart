import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wawu_mobile/providers/plan_provider.dart';
import 'package:wawu_mobile/providers/user_provider.dart';
import 'package:wawu_mobile/screens/account_payment/account_payment.dart';
import 'package:wawu_mobile/widgets/plan_card/plan_card.dart';

class Plan extends StatefulWidget {
  const Plan({super.key});

  @override
  _PlanState createState() => _PlanState();
}

class _PlanState extends State<Plan> {
  @override
  void initState() {
    super.initState();
    // Fetch plans when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PlanProvider>().fetchAllPlans();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select A Plan'), centerTitle: true),
      body: Consumer2<PlanProvider, UserProvider>(
        builder: (context, planProvider, userProvider, child) {
          if (planProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (planProvider.hasError) {
            return Center(
              child: Text(
                planProvider.errorMessage ?? 'Failed to load plans',
                style: const TextStyle(color: Colors.red),
              ),
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
                                              'check': feature.value == 'yes',
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
