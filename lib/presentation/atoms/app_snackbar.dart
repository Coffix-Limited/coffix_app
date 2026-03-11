// import 'package:coffix_app/core/constants/colors.dart';
// import 'package:coffix_app/core/constants/sizes.dart';
// import 'package:flutter/material.dart';

// class AppSnackbar {
//   AppSnackbar._();

//   static SnackBar error(String message) => _build(
//     message: message,
//     icon: Icons.error_outline_rounded,
//     backgroundColor: AppColors.error,
//   );

//   static SnackBar success(String message) => _build(
//     message: message,
//     icon: Icons.check_circle_outline_rounded,
//     backgroundColor: AppColors.success,
//   );

//   static SnackBar info(String message) => _build(
//     message: message,
//     icon: Icons.info_outline_rounded,
//     backgroundColor: AppColors.accent,
//   );

//   static SnackBar _build({
//     required String message,
//     required IconData icon,
//     required Color backgroundColor,
//   }) {
//     return SnackBar(
//       backgroundColor: backgroundColor,
//       behavior: SnackBarBehavior.floating,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(AppSizes.md),
//       ),
//       content: Row(
//         children: [
//           Icon(icon, color: AppColors.white, size: AppSizes.iconSizeMedium),
//           const SizedBox(width: AppSizes.sm),
//           Expanded(
//             child: Text(
//               message,
//               style: const TextStyle(color: AppColors.white),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   static void showError(BuildContext context, String message) {
//     ScaffoldMessenger.of(context).showSnackBar(error(message));
//   }

//   static void showSuccess(BuildContext context, String message) {
//     ScaffoldMessenger.of(context).showSnackBar(success(message));
//   }

//   static void showInfo(BuildContext context, String message) {
//     ScaffoldMessenger.of(context).showSnackBar(info(message));
//   }
// }
