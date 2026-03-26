import 'package:coffix_app/core/constants/colors.dart';
import 'package:coffix_app/core/constants/sizes.dart';
import 'package:coffix_app/core/theme/typography.dart';
import 'package:flutter/material.dart';

class InfoCard extends StatelessWidget {
  const InfoCard({super.key, required this.text, required this.image});

  final String text;
  final String image;


  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              border: Border.all(),
              shape: BoxShape.circle,
            ),
            child: CircleAvatar(
              backgroundColor: AppColors.white,
              radius: 40,
              child: Image.asset(
                image,
                width: AppSizes.iconSizeLarge,
                height: AppSizes.iconSizeLarge,
                fit: BoxFit.fitHeight,
              ),
            ),
          ),
          const SizedBox(height: AppSizes.md),
          Expanded(
            child: Align(
              alignment: Alignment.topCenter,
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: AppTypography.labelS.copyWith(color: AppColors.black),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
