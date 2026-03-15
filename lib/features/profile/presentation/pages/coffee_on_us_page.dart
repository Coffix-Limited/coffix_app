import 'package:coffix_app/core/constants/sizes.dart';
import 'package:coffix_app/presentation/molecules/app_back_header.dart';
import 'package:flutter/material.dart';

class CoffeeOnUsPage extends StatelessWidget {
  static String route = 'coffee_on_us_route';
  const CoffeeOnUsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const CoffeeOnUsView();
  }
}

class CoffeeOnUsView extends StatelessWidget {
  const CoffeeOnUsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBackHeader(title: 'Coffee On Us'),
      body: Column(
        children: [
          Text(
            "Introduce your friends to the Coffix App and get a coffee on us after their first purchase (within 7 days)",
          ),
          SizedBox(height: AppSizes.xl),
        ],
      ),
    );
  }
}
