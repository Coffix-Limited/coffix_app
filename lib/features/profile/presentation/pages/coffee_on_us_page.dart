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
  static const int _minFriends = 3;
  static const int _maxFriends = 5;

  int _friendCount = _minFriends;

  Widget _buildFriendRow(int index) {
    final num = index + 1;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: AppField(
                hintText: "Name",
                name: "Name $num",
                isHorizontalAlign: true,
              ),
            ),
            if (_friendCount > _minFriends)
              IconButton(
                icon: const Icon(
                  Icons.remove_circle_outline,
                  color: Colors.red,
                ),
                onPressed: () => setState(() => _friendCount--),
              ),
          ],
        ),
        SizedBox(height: AppSizes.sm),
        AppField(
          hintText: "Email",
          name: "Email $num",
          isHorizontalAlign: true,
          keyboardType: TextInputType.emailAddress,
        ),
        if (index < _friendCount - 1) Divider(height: AppSizes.xxl),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBackHeader(title: 'Coffee On Us', showLocation: false),
      body: SingleChildScrollView(
        padding: AppSizes.defaultPadding,
        child: Column(
          children: [
            const Text(
              "Introduce your friends to the Coffix App and get a coffee on us after their first purchase (within 7 days)",
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSizes.xl),
            ...List.generate(_friendCount, _buildFriendRow),

            SizedBox(height: AppSizes.xl),
            AppButton(onPressed: () {}, label: "Invite your friends"),
          ],
        ),
      ),
    );
  }
}
