import 'package:flutter/widgets.dart';

/// Classifies the space actually available to a screen, independent of device.
enum AdaptiveSize { mobile, tablet, desktop }

abstract final class AdaptiveBreakpoints {
  static const double tablet = 600;
  static const double desktop = 1024;

  static AdaptiveSize fromWidth(double width) {
    if (width < tablet) return AdaptiveSize.mobile;
    if (width < desktop) return AdaptiveSize.tablet;
    return AdaptiveSize.desktop;
  }
}

class AdaptiveLayout extends StatelessWidget {
  const AdaptiveLayout({
    super.key,
    required this.mobile,
    required this.desktop,
    this.tablet,
  });

  final Widget mobile;
  final Widget desktop;
  final Widget? tablet;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) =>
        switch (AdaptiveBreakpoints.fromWidth(constraints.maxWidth)) {
          AdaptiveSize.mobile => mobile,
          AdaptiveSize.tablet => tablet ?? desktop,
          AdaptiveSize.desktop => desktop,
        },
  );
}
