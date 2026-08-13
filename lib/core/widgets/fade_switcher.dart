import 'package:flutter/material.dart';

class FadeSwitcher extends StatelessWidget {
  const FadeSwitcher({
    required this.child,
    super.key,
  });

  final Widget child;

  static const duration = Duration(milliseconds: 280);

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      layoutBuilder: _layoutBuilder,
      child: child,
    );
  }

  static Widget _layoutBuilder(
    Widget? currentChild,
    List<Widget> previousChildren,
  ) {
    return Stack(
      alignment: Alignment.center,
      children: [
        for (final child in previousChildren)
          if (child.key != currentChild?.key) IgnorePointer(child: child),
        ?currentChild,
      ],
    );
  }
}
