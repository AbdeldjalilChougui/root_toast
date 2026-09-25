import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pumps a MaterialApp whose home exposes its [BuildContext] and returns it.
Future<BuildContext> pumpHome(
  WidgetTester tester, {
  TextDirection direction = TextDirection.ltr,
  ThemeData? theme,
  GlobalKey<NavigatorState>? navigatorKey,
  TransitionBuilder? builder,
}) async {
  late BuildContext ctx;
  await tester.pumpWidget(
    MaterialApp(
      navigatorKey: navigatorKey,
      theme: theme,
      builder: (context, child) {
        final directed =
            Directionality(textDirection: direction, child: child!);
        return builder == null ? directed : builder(context, directed);
      },
      home: Builder(
        builder: (context) {
          ctx = context;
          return const Scaffold(body: SizedBox.expand());
        },
      ),
    ),
  );
  return ctx;
}

/// Lets the entrance animation finish.
Future<void> settleIn(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

/// Advances fake time by [total] in 16ms frames, so chained animations and
/// state changes all get a frame to run in.
Future<void> advance(WidgetTester tester, Duration total) async {
  const frame = Duration(milliseconds: 16);
  var left = total;
  while (left > Duration.zero) {
    final step = left < frame ? left : frame;
    await tester.pump(step);
    left -= step;
  }
}
