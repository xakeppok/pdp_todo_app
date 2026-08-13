import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdp_todo_app/core/widgets/fade_switcher.dart';

void main() {
  testWidgets('does not throw when returning to the same key mid-animation', (
    tester,
  ) async {
    var childKey = 'error';
    late StateSetter setState;

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, set) {
            setState = set;
            return FadeSwitcher(
              child: SizedBox(
                key: ValueKey(childKey),
                width: 10,
                height: 10,
              ),
            );
          },
        ),
      ),
    );

    setState(() => childKey = 'loading');
    await tester.pump();
    setState(() => childKey = 'error');
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}
