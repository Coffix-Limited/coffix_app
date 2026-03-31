import 'package:flutter/material.dart';

class AppLayoutBody extends StatelessWidget {
  const AppLayoutBody({
    super.key,
    required this.child,
    this.hasSafeArea = true,
  });

  final Widget child;
  final bool hasSafeArea;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: hasSafeArea,
      bottom: hasSafeArea,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(child: child),
            ),
          );
        },
      ),
    );
  }
}
