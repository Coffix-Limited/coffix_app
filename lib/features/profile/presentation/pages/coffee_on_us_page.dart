import 'package:coffix_app/core/constants/sizes.dart';
import 'package:coffix_app/presentation/atoms/app_button.dart';
import 'package:coffix_app/presentation/atoms/app_field.dart';
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

class CoffeeOnUsView extends StatefulWidget {
  const CoffeeOnUsView({super.key});

  @override
  State<CoffeeOnUsView> createState() => _CoffeeOnUsViewState();
}

class _CoffeeOnUsViewState extends State<CoffeeOnUsView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBackHeader(title: 'Coffee On Us'),
      body: SingleChildScrollView(
        padding: AppSizes.defaultPadding,
        child: Column(
          children: [
            Text(
              "Introduce your friends to the Coffix App and get a coffee on us after their first purchase (within 7 days)",
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSizes.xl),
            AppField(hintText: "Name", name: "Name", isHorizontalAlign: true),
            SizedBox(height: AppSizes.sm),
            AppField(hintText: "Email", name: "Email", isHorizontalAlign: true),
            Divider(),
            SizedBox(height: AppSizes.xl),
            AppButton(onPressed: () {}, label: "Invite your friends"),
          ],
        ),
      ),
    );
  }
}
