import 'package:flutter/material.dart';
import 'package:wawu_mobile/screens/account_payment/account_payment.dart';
import 'package:wawu_mobile/widgets/plan_card/plan_card.dart';

class Plan extends StatelessWidget {
  const Plan({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> features = [
      {'check': false, 'text': 'Verified Badge'},
      {'check': true, 'text': 'Standard Account'},
      {'check': true, 'text': 'Basic Account Support'},
      {'check': false, 'text': 'Gig Of The Day'},
      {'check': false, 'text': 'Enhanced Support'},
      {'check': false, 'text': 'Gig Purchase SMS'},
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Select A Plan'), centerTitle: true),
      body: ListView(
        children: [
          Column(
            children: [
              SizedBox(height: 10),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    clipBehavior: Clip.hardEdge,
                    decoration: BoxDecoration(shape: BoxShape.circle),
                    child: Image.asset(
                      'assets/images/other/avatar.jpg',
                      fit: BoxFit.cover,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Mavis Nwaokorie',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Buyer',
                    style: TextStyle(
                      fontSize: 13,
                      color: const Color.fromARGB(255, 125, 125, 125),
                      fontWeight: FontWeight.w200,
                    ),
                  ),
                  SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    height: 490,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        SizedBox(width: 20),
                        PlanCard(
                          heading: 'Wawu Standard',
                          desc: 'Our Foundational Package',
                          features: features,
                          function: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AccountPayment(),
                              ),
                            );
                          },
                        ),
                        SizedBox(width: 20),
                        PlanCard(
                          heading: 'Wawu Plus',
                          desc: 'Our Foundational Package',
                          // features: features,
                        ),
                        SizedBox(width: 20),
                        PlanCard(
                          heading: 'Wawu Premium',
                          desc: 'Our Foundational Package',
                          // features: features,
                        ),
                        SizedBox(width: 20),
                      ],
                    ),
                  ),
                  SizedBox(height: 30),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
