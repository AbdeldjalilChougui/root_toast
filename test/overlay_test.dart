import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:root_toast/root_toast.dart';

import 'helpers.dart';

void main() {
  late RootToastController toasts;
  setUp(() => toasts = RootToastController());
  tearDown(() => toasts.dispose());

  testWidgets('shows the message and removes it once the time is up',
      (tester) async {
    final ctx = await pumpHome(tester);
    toasts.show('Saved', context: ctx, duration: const Duration(seconds: 2));
    await settleIn(tester);
    expect(find.text('Saved'), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.text('Saved'), findsNothing);
    expect(toasts.visibleCount, 0);
  });

  testWidgets('stays visible and tappable above an open modal bottom sheet',
      (tester) async {
    final ctx = await pumpHome(tester);
    unawaited(showModalBottomSheet<void>(
      context: ctx,
      builder: (_) => const SizedBox(height: 500, child: Text('sheet')),
    ));
    await tester.pumpAndSettle();

    // Bottom position overlaps the sheet: it must still win the hit test.
    toasts.show('Rejected', context: ctx, position: RootToastPosition.bottom);
    await settleIn(tester);

    expect(find.text('sheet'), findsOneWidget);
    expect(find.text('Rejected').hitTestable(), findsOneWidget);
  });

  testWidgets('stays above a dialog opened after the toast', (tester) async {
    final ctx = await pumpHome(tester);
    toasts.show('Behind?', context: ctx, position: RootToastPosition.center);
    await settleIn(tester);

    unawaited(showDialog<void>(
      context: ctx,
      builder: (_) => const AlertDialog(content: Text('dialog body')),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('dialog body'), findsOneWidget);
    expect(find.text('Behind?').hitTestable(), findsOneWidget);
  });

  testWidgets('shows above a dialog when called from inside the dialog',
      (tester) async {
    final ctx = await pumpHome(tester);
    late BuildContext dialogCtx;
    unawaited(showDialog<void>(
      context: ctx,
      builder: (context) {
        dialogCtx = context;
        return const AlertDialog(content: Text('dialog body'));
      },
    ));
    await tester.pumpAndSettle();

    toasts.show('From dialog',
        context: dialogCtx, position: RootToastPosition.center);
    await settleIn(tester);
    expect(find.text('From dialog').hitTestable(), findsOneWidget);
  });

  testWidgets('empty or blank messages show nothing', (tester) async {
    final ctx = await pumpHome(tester);
    expect(toasts.show('   ', context: ctx), isNull);
    await settleIn(tester);
    expect(toasts.visibleCount, 0);
  });

  testWidgets('top position respects the safe area', (tester) async {
    tester.view.padding = const FakeViewPadding(top: 120);
    addTearDown(tester.view.resetPadding);
    final ctx = await pumpHome(tester);
    toasts.show('Top', context: ctx);
    await settleIn(tester);
    final dpr = tester.view.devicePixelRatio;
    expect(tester.getTopLeft(find.text('Top')).dy, greaterThan(120 / dpr));
  });

  testWidgets('bottom position stays above the keyboard', (tester) async {
    final ctx = await pumpHome(tester);
    final dpr = tester.view.devicePixelRatio;
    tester.view.viewInsets = FakeViewPadding(bottom: 300 * dpr);
    addTearDown(tester.view.resetViewInsets);
    await tester.pump();

    toasts.show('Above keys', context: ctx, position: RootToastPosition.bottom);
    await settleIn(tester);

    final screenHeight = tester.view.physicalSize.height / dpr;
    final card = find.byKey(const ValueKey('root_toast_card'));
    expect(
        tester.getBottomLeft(card).dy, lessThanOrEqualTo(screenHeight - 300));
  });

  testWidgets('centre position stays centred in the space above the keyboard',
      (tester) async {
    final ctx = await pumpHome(tester);
    final dpr = tester.view.devicePixelRatio;
    tester.view.viewInsets = FakeViewPadding(bottom: 400 * dpr);
    addTearDown(tester.view.resetViewInsets);
    await tester.pump();

    toasts.show('Mid', context: ctx, position: RootToastPosition.center);
    await settleIn(tester);
    final screenHeight = tester.view.physicalSize.height / dpr;
    final card = find.byKey(const ValueKey('root_toast_card'));
    expect(
        tester.getBottomLeft(card).dy, lessThanOrEqualTo(screenHeight - 400));
  });

  testWidgets('calling with an unmounted context fails quietly',
      (tester) async {
    final ctx = await pumpHome(tester);
    late BuildContext pageCtx;
    unawaited(Navigator.of(ctx).push(MaterialPageRoute<void>(
      builder: (context) {
        pageCtx = context;
        return const Scaffold(body: Text('page'));
      },
    )));
    await tester.pumpAndSettle();
    Navigator.of(pageCtx).pop();
    await tester.pumpAndSettle();
    expect(pageCtx.mounted, isFalse);

    final logs = <String?>[];
    final original = debugPrint;
    debugPrint = (message, {wrapWidth}) => logs.add(message);
    RootToastHandle? handle;
    try {
      handle = toasts.show('Too late', context: pageCtx);
      await settleIn(tester);
    } finally {
      debugPrint = original;
    }

    expect(handle, isNull);
    expect(tester.takeException(), isNull);
    expect(find.text('Too late'), findsNothing);
    expect(logs.single, contains('unmounted'));
  });

  testWidgets('without context or navigator key it fails quietly',
      (tester) async {
    await pumpHome(tester);
    final logs = <String?>[];
    final original = debugPrint;
    debugPrint = (message, {wrapWidth}) => logs.add(message);
    try {
      expect(toasts.show('Nowhere'), isNull);
    } finally {
      debugPrint = original;
    }
    expect(logs.single, contains('no Overlay'));
  });

  testWidgets('context-free use through a navigator key', (tester) async {
    final key = GlobalKey<NavigatorState>();
    final global = RootToastController(navigatorKey: key);
    addTearDown(global.dispose);
    await pumpHome(tester, navigatorKey: key);
    global.show('No context needed');
    await settleIn(tester);
    expect(find.text('No context needed'), findsOneWidget);
  });
}
