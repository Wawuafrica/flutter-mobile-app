import 'package:flutter/material.dart';
import 'package:wawu_mobile/screens/account_payment/verify_payment/verify_payment.dart';
import 'package:wawu_mobile/utils/constants/colors.dart';
import 'package:wawu_mobile/widgets/custom_button/custom_button.dart';
import 'package:wawu_mobile/widgets/custom_intro_text/custom_intro_text.dart';
import 'package:wawu_mobile/widgets/custom_row_single_column/custom_row_single_column.dart';
import 'package:wawu_mobile/widgets/custom_textfield/custom_textfield.dart';

class AccountPaymentCheckout extends StatefulWidget {
  const AccountPaymentCheckout({super.key});

  @override
  _AccountPaymentCheckoutState createState() => _AccountPaymentCheckoutState();
}

class _AccountPaymentCheckoutState extends State<AccountPaymentCheckout> {
  String? _selectedPaymentMethod;
  final _formKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  final _expiryDateController = TextEditingController();
  final _cvvController = TextEditingController();
  bool _isFormValid = false;

  void _validateForm() {
    bool isCardNumberValid = _cardNumberController.text.isNotEmpty;
    bool isExpiryDateValid = _expiryDateController.text.isNotEmpty;
    bool isCvvValid = _cvvController.text.isNotEmpty;

    setState(() {
      _isFormValid = isCardNumberValid && isExpiryDateValid && isCvvValid;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Checkout')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: ListView(
          children: [
            CustomIntroText(text: 'Final Details'),
            SizedBox(height: 20),
            Container(
              width: double.infinity,
              height: 200,
              padding: EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: wawuColors.primary,
              ),
              child: Column(
                children: [
                  Expanded(
                    child: CustomRowSingleColumn(
                      leftText: 'SubTotal',
                      leftTextStyle: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                      rightText: '#5000',
                      rightTextStyle: TextStyle(color: Colors.white),
                    ),
                  ),
                  Expanded(
                    child: CustomRowSingleColumn(
                      leftText: 'Discount',
                      leftTextStyle: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                      rightText: '-#500',
                      rightTextStyle: TextStyle(color: Colors.white),
                    ),
                  ),
                  Expanded(
                    child: CustomRowSingleColumn(
                      leftText: 'Total',
                      leftTextStyle: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                      rightText: '#4500',
                      rightTextStyle: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            CustomIntroText(text: 'Payment'),
            SizedBox(height: 20),
            _buildPaymentOption('PayPal', 'PayPal'),
            _buildPaymentOption('Bank Transfer', 'Wema Bank'),
            _buildPaymentOption('Credit Card', 'Credit Card'),
            if (_selectedPaymentMethod == 'Credit Card') _buildCreditCardForm(),
            SizedBox(height: 20),

            if (_selectedPaymentMethod != 'Credit Card')
              CustomButton(
                widget: Text(
                  'Transfer',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                color: wawuColors.primary,
                textColor: Colors.white,
                function: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => VerifyPayment()),
                  );
                },
              )
            else
              CustomButton(
                widget: Text(
                  'Pay \$7,030',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _isFormValid ? Colors.white : Colors.black,
                  ),
                ),
                color:
                    _isFormValid
                        ? wawuColors.primary
                        : wawuColors.primary.withAlpha(50),
                textColor: Colors.white,
                function: _isFormValid ? _processPayment : null,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOption(String title, String value) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPaymentMethod = value;
        });
      },
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 8),
        padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 25.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: wawuColors.primary.withAlpha(30),
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                    _selectedPaymentMethod == value
                        ? wawuColors.primary
                        : Colors.white,
              ),
              child: Center(
                child:
                    _selectedPaymentMethod == value
                        ? Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                        )
                        : null,
              ),
            ),
            SizedBox(width: 10),
            Text(
              title,
              style: TextStyle(
                color:
                    _selectedPaymentMethod == value
                        ? wawuColors.primary
                        : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreditCardForm() {
    return Form(
      key: _formKey,
      onChanged: _validateForm,
      child: Column(
        children: [
          CustomTextfield(
            labelText: 'Card Number',
            hintText: 'Enter card number',
            controller: _cardNumberController,
            onChanged: (value) {
              _validateForm();
            },
          ),
          // SizedBox(height: 10),
          Row(
            spacing: 10.0,
            children: [
              Expanded(
                child: CustomTextfield(
                  labelText: 'Expiration Date',
                  hintText: 'MM/YY',
                  controller: _expiryDateController,
                  onChanged: (value) {
                    _validateForm();
                  },
                ),
              ),
              Expanded(
                child: CustomTextfield(
                  labelText: 'CVV',
                  hintText: '123',
                  controller: _cvvController,
                  onChanged: (value) {
                    _validateForm();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _processPayment() {
    if (_formKey.currentState!.validate()) {
      // Process payment logic here
    }
  }
}
