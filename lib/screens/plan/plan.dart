import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wawu_mobile/providers/plan_provider.dart';
import 'package:wawu_mobile/screens/account_payment/account_payment.dart';
import 'package:wawu_mobile/widgets/plan_card/plan_card.dart';

class Plan extends StatelessWidget {
  const Plan({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select A Plan'), centerTitle: true),
      body: Consumer<PlanProvider>(
        builder: (context, planProvider, child) {
          if (planProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          return ListView(
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 100,
                    height: 100,
                    clipBehavior: Clip.hardEdge,
                    decoration: const BoxDecoration(shape: BoxShape.circle),
                    child: Image.asset(
                      'assets/images/other/avatar.webp',
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Mavis Nwaokorie',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Buyer',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color.fromARGB(255, 125, 125, 125),
                      fontWeight: FontWeight.w200,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 490,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: planProvider.plans.length,
                      separatorBuilder: (context, index) => const SizedBox(width: 20),
                      itemBuilder: (context, index) {
                        final plan = planProvider.plans[index];
                        return Padding(
                          padding: EdgeInsets.only(
                            left: index == 0 ? 20 : 0,
                            right: index == planProvider.plans.length - 1 ? 20 : 0,
                          ),
                          child: PlanCard(
                            heading: plan.name,
                            desc: plan.description ?? 'No description available',
                            features: plan.features
                                    ?.map((feature) => {
                                          'check': feature.value == 'yes',
                                          'text': feature.description,
                                        })
                                    .toList() ??
                                [],
                            function: () {
                              planProvider.selectPlan(plan);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const AccountPayment(),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}