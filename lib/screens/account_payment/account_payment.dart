import 'package:flutter/material.dart';
import 'package:wawu_mobile/screens/account_payment/account_payment_checkout/account_payment_checkout.dart';
import 'package:wawu_mobile/screens/account_payment/disclaimer/disclaimer.dart';
import 'package:wawu_mobile/utils/constants/colors.dart';
import 'package:wawu_mobile/widgets/custom_button/custom_button.dart';
import 'package:wawu_mobile/widgets/custom_row_single_column/custom_row_single_column.dart';
import 'package:wawu_mobile/widgets/custom_textfield/custom_textfield.dart';

class AccountPayment extends StatefulWidget {
  const AccountPayment({super.key});

  @override
  State<AccountPayment> createState() => _AccountPaymentState();
}

class _AccountPaymentState extends State<AccountPayment> {
  int activeIndex = 0; // No active item initially
  String subscriptionType = 'Monthly';

  final List<String> items = ["Monthly", "Yearly"];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Payment')),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
        child: ListView(
          children: [
            Text(
              'Please note this is a $subscriptionType subsription',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20),
            Container(
              width: double.infinity,
              height: 40,
              decoration: BoxDecoration(
                color: wawuColors.primary.withAlpha(30),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: List.generate(items.length, (index) {
                  bool isActive = activeIndex == index;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          activeIndex = index;
                          subscriptionType = items[index];
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color:
                              isActive
                                  ? wawuColors.primary
                                  : Colors.transparent,
                        ),
                        child: Center(
                          child: Text(
                            items[index],
                            style: TextStyle(
                              color: isActive ? wawuColors.white : Colors.black,
                              // fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            SizedBox(height: 20),
            CustomTextfield(labelText: 'Discount Code'),
            SizedBox(height: 20),
            Container(
              width: double.infinity,
              height: 160,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: wawuColors.primary.withAlpha(50),
              ),
              padding: EdgeInsets.all(30.0),
              child: Column(
                spacing: 20,
                children: [
                  Expanded(
                    child: CustomRowSingleColumn(
                      leftText: 'Subscription Plan',
                      leftTextStyle: TextStyle(
                        color: wawuColors.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      rightText: 'Wawu Standard',
                      rightTextStyle: TextStyle(
                        color: wawuColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(
                    child: CustomRowSingleColumn(
                      leftText: 'Discount',
                      leftTextStyle: TextStyle(
                        color: wawuColors.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                      rightText: '8%',
                      rightTextStyle: TextStyle(
                        color: wawuColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                  Expanded(
                    child: CustomRowSingleColumn(
                      leftText: 'Total',
                      leftTextStyle: TextStyle(
                        color: wawuColors.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      rightText: '#5000',
                      rightTextStyle: TextStyle(
                        color: wawuColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            CustomButton(
              function: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => Disclaimer()),
                );
              },
              widget: Text(
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
  }
}
