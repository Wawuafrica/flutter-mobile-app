import 'package:flutter/material.dart';
import 'package:wawu_mobile/utils/constants/sizes.dart';
import 'package:wawu_mobile/utils/constants/text_string.dart';

import '../../../../common/styles/spacing_styles.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: wawuSpacingStyle.paddingWithAppBarHeight,
          child: Column(
            children: [
              //title and subtitle

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(wawuText.loginTitle, style: Theme
                      .of(context)
                      .textTheme
                      .headlineMedium,),
                  const SizedBox(height: wawuSizes.sm),
                  Text(wawuText.loginSubTitle, style: Theme
                      .of(context)
                      .textTheme
                      .bodyMedium,)
                ],
              ),

              //form
              Form(
                child: Column(
                  children: [
                    //Email
                    TextFormField(
                      decoration: InputDecoration(
                          prefixIcon: Icon(Icons.send),
                          labelText: "Email"
                      ),
                    ),

                    const SizedBox(height: wawuSizes.spaceBtwInputFieldRadius),

                    //Password
                    TextFormField(
                      decoration: InputDecoration(
                          prefixIcon: Icon(Icons.verified),
                          labelText: "Password",
                          suffixIcon: Icon(Icons.visibility)
                      ),
                    ),

                    const SizedBox(height: wawuSizes.spaceBtwInputFieldRadius / 2),

                    //Remember me and Forgot password
                    Row(
                      children: [
                        //Remember me
                        Row(
                          children: [
                            Checkbox(value: true, onChanged: (value){}),
                            const Text("Remember me"),
                          ],
                        ),

                        //Forgot Password
                        TextButton(onPressed: (){}, child: const Text("Forgot Password? ")),
                      ],
                    ),
                    const SizedBox(height: wawuSizes.spaceBtwSections,),
                    
                    //sign in
                    SizedBox(width: double.infinity, child: ElevatedButton(onPressed: (){}, child: Text("Login"),),)

                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
