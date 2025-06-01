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
                    child: userProvider.currentUser?.profileImage != null
                        ? Image.network(
                            userProvider.currentUser!.profileImage!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
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
                  const SizedBox(height: 10),
                  Text(
                    userProvider.currentUser != null
                        ? '${userProvider.currentUser!.firstName} ${userProvider.currentUser!.lastName}'
                        : 'Guest User',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    userProvider.currentUser?.role ?? 'Unknown',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color.fromARGB(255, 125, 125, 125),
                      fontWeight: FontWeight.w200,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 490,
                    child: planProvider.plans.isEmpty
                        ? const Center(child: Text('No plans available'))
                        : ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: planProvider.plans.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(width: 20),
                            itemBuilder: (context, index) {
                              final plan = planProvider.plans[index];
                              return Padding(
                                padding: EdgeInsets.only(
                                  left: index == 0 ? 20 : 0,
                                  right: index == planProvider.plans.length - 1
                                      ? 20
                                      : 0,
                                ),
                                child: PlanCard(
                                  heading: plan.name,
                                  desc:
                                      plan.description ?? 'No description available',
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
                                        builder: (context) =>
                                            const AccountPayment(),
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

// import 'package:flutter/material.dart';
// import 'package:wawu_mobile/screens/account_payment/account_payment.dart';
// import 'package:wawu_mobile/widgets/plan_card/plan_card.dart';

// class Plan extends StatelessWidget {
//   const Plan({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final List<Map<String, dynamic>> features = [
//       {'check': false, 'text': 'Verified Badge'},
//       {'check': true, 'text': 'Standard Account'},
//       {'check': true, 'text': 'Basic Account Support'},
//       {'check': false, 'text': 'Gig Of The Day'},
//       {'check': false, 'text': 'Enhanced Support'},
//       {'check': false, 'text': 'Gig Purchase SMS'},
//     ];
//     return Scaffold(
//       appBar: AppBar(title: const Text('Select A Plan'), centerTitle: true),
//       body: ListView(
//         children: [
//           Column(
//             children: [
//               SizedBox(height: 10),
//               Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 crossAxisAlignment: CrossAxisAlignment.center,
//                 children: [
//                   Container(
//                     width: 100,
//                     height: 100,
//                     clipBehavior: Clip.hardEdge,
//                     decoration: BoxDecoration(shape: BoxShape.circle),
//                     child: Image.asset(
//                       'assets/images/other/avatar.webp',
//                       fit: BoxFit.cover,
//                     ),
//                   ),
//                   SizedBox(height: 10),
//                   Text(
//                     'Mavis Nwaokorie',
//                     style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//                   ),
//                   SizedBox(height: 10),
//                   Text(
//                     'Buyer',
//                     style: TextStyle(
//                       fontSize: 13,
//                       color: const Color.fromARGB(255, 125, 125, 125),
//                       fontWeight: FontWeight.w200,
//                     ),
//                   ),
//                   SizedBox(height: 10),
//                   Container(
//                     width: double.infinity,
//                     height: 490,
//                     child: ListView(
//                       scrollDirection: Axis.horizontal,
//                       children: [
//                         SizedBox(width: 20),
//                         PlanCard(
//                           heading: 'Wawu Standard',
//                           desc: 'Our Foundational Package',
//                           features: features,
//                           function: () {
//                             Navigator.push(
//                               context,
//                               MaterialPageRoute(
//                                 builder: (context) => AccountPayment(),
//                               ),
//                             );
//                           },
//                         ),
//                         SizedBox(width: 20),
//                         PlanCard(
//                           heading: 'Wawu Plus',
//                           desc: 'Our Foundational Package',
//                           // features: features,
//                         ),
//                         SizedBox(width: 20),
//                         PlanCard(
//                           heading: 'Wawu Premium',
//                           desc: 'Our Foundational Package',
//                           // features: features,
//                         ),
//                         SizedBox(width: 20),
//                       ],
//                     ),
//                   ),
//                   SizedBox(height: 30),
//                 ],
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }
