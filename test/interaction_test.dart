import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:root_toast/root_toast.dart';

import 'helpers.dart';

void main() {
  late RootToastController toasts;
  setUp(() => toasts = RootToastController());
  tearDown(() => toasts.dispose());

  group('durations', () {
    testWidgets('an explicit duration is honoured', (tester) async {
      final ctx = await pumpHome(tester);
      toasts.show('Brief',
          context: ctx, duration: const Duration(milliseconds: 1500));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1400));
      expect(find.text('Brief'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();
      expect(find.text('Brief'), findsNothing);
    });

    test('automatic duration grows with message length and is bounded', () {
      expect(RootToastController.readingTime('Ok'),
          const Duration(milliseconds: 2600));
      final medium = RootToastController.readingTime('x' * 60);
      expect(medium, const Duration(milliseconds: 2200 + 60 * 45));
      expect(RootToastController.readingTime('x' * 1000),
          const Duration(seconds: 6));
    });

    testWidgets('automatic duration is used when none is given',
        (tester) async {
      final ctx = await pumpHome(tester);
      toasts.show('Ok', context: ctx);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 2500));
      expect(find.text('Ok'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();
      expect(find.text('Ok'), findsNothing);
    });
  });

  testWidgets('tap dismisses', (tester) async {
    final ctx = await pumpHome(tester);
    toasts.show('Tap me', context: ctx);
    await settleIn(tester);
    await tester.tap(find.text('Tap me'));
    await tester.pumpAndSettle();
    expect(find.text('Tap me'), findsNothing);
  });

  testWidgets('tap dismiss can be turned off', (tester) async {
    final ctx = await pumpHome(tester);
    toasts.show('Stay', context: ctx, dismissOnTap: false);
    await settleIn(tester);
    await tester.tap(find.text('Stay'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Stay'), findsOneWidget);
  });

  group('swipe', () {
    testWidgets('a horizontal fling dismisses', (tester) async {
      final ctx = await pumpHome(tester);
      toasts.show('Swipe me', context: ctx);
      await settleIn(tester);
      await tester.drag(find.text('Swipe me'), const Offset(250, 0));
      await tester.pumpAndSettle();
      expect(find.text('Swipe me'), findsNothing);
    });

    testWidgets('an upward swipe dismisses a top toast', (tester) async {
      final ctx = await pumpHome(tester);
      toasts.show('Up', context: ctx);
      await settleIn(tester);
      await tester.drag(find.text('Up'), const Offset(0, -120));
      await tester.pumpAndSettle();
      expect(find.text('Up'), findsNothing);
    });

    testWidgets('a downward swipe dismisses a bottom toast', (tester) async {
      final ctx = await pumpHome(tester);
      toasts.show('Down', context: ctx, position: RootToastPosition.bottom);
      await settleIn(tester);
      await tester.drag(find.text('Down'), const Offset(0, 120));
      await tester.pumpAndSettle();
      expect(find.text('Down'), findsNothing);
    });

    testWidgets('a short drag snaps back and keeps the toast', (tester) async {
      final ctx = await pumpHome(tester);
      toasts.show('Nudge', context: ctx, duration: const Duration(seconds: 10));
      await settleIn(tester);
      final before = tester.getTopLeft(find.text('Nudge'));
      final gesture =
          await tester.startGesture(tester.getCenter(find.text('Nudge')));
      await gesture.moveBy(const Offset(30, 0));
      await gesture.moveBy(const Offset(20, 0));
      await tester.pump(const Duration(milliseconds: 600));
      await gesture.up();
      await advance(tester, const Duration(milliseconds: 400));
      expect(find.text('Nudge'), findsOneWidget);
      expect(tester.getTopLeft(find.text('Nudge')), before);
    });
  });

  testWidgets('the timer pauses while the toast is pressed', (tester) async {
    final ctx = await pumpHome(tester);
    toasts.show('Hold', context: ctx, duration: const Duration(seconds: 1));
    await settleIn(tester);

    final gesture =
        await tester.startGesture(tester.getCenter(find.text('Hold')));
    await tester.pump(const Duration(seconds: 3));
    expect(find.text('Hold'), findsOneWidget);

    // Releasing after a long press resumes the timer, it does not dismiss.
    await gesture.up();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Hold'), findsOneWidget);

    // Roughly the remaining 600ms of the original second, then it goes.
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();
    expect(find.text('Hold'), findsNothing);
  });

  testWidgets('an action runs its callback and dismisses the toast',
      (tester) async {
    final ctx = await pumpHome(tester);
    var undone = 0;
    toasts.show(
      'Deleted',
      context: ctx,
      action: RootToastAction(label: 'UNDO', onPressed: () => undone++),
    );
    await settleIn(tester);
    await tester.tap(find.text('UNDO'));
    await tester.pumpAndSettle();
    expect(undone, 1);
    expect(find.text('Deleted'), findsNothing);
  });

  testWidgets('each type has its own default icon, overridable',
      (tester) async {
    final stack =
        RootToastController(policy: RootToastPolicy.stack, maxVisible: 5);
    addTearDown(stack.dispose);
    final ctx = await pumpHome(tester);
    stack.show('s', context: ctx, type: RootToastType.success);
    stack.show('e', context: ctx, type: RootToastType.error);
    stack.show('i', context: ctx, type: RootToastType.info);
    stack.show('w', context: ctx, type: RootToastType.warning);
    stack.show('c', context: ctx, icon: Icons.cake);
    await settleIn(tester);
    expect(find.byIcon(Icons.check_circle_outline_rounded), findsOneWidget);
    expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
    expect(find.byIcon(Icons.info_outline_rounded), findsOneWidget);
    expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    expect(find.byIcon(Icons.cake), findsOneWidget);
  });
}
