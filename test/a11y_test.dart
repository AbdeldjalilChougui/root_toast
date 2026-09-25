import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:root_toast/root_toast.dart';

import 'helpers.dart';

void main() {
  late RootToastController toasts;
  setUp(() => toasts = RootToastController());
  tearDown(() => toasts.dispose());

  testWidgets('announces the message politely by default', (tester) async {
    final ctx = await pumpHome(tester);
    toasts.show('Profile saved', context: ctx);
    await settleIn(tester);
    final announcements = tester.takeAnnouncements();
    expect(announcements, hasLength(1));
    expect(announcements.single.message, 'Profile saved');
    expect(announcements.single.textDirection, TextDirection.ltr);
    expect(announcements.single.assertiveness, Assertiveness.polite);
  });

  testWidgets('politeness is configurable per controller and per call',
      (tester) async {
    final loud = RootToastController(politeness: RootToastPoliteness.assertive);
    addTearDown(loud.dispose);
    final ctx = await pumpHome(tester);
    loud.show('Payment failed', context: ctx);
    await settleIn(tester);
    expect(tester.takeAnnouncements().single.assertiveness,
        Assertiveness.assertive);

    toasts.show('Heads up',
        context: ctx, politeness: RootToastPoliteness.assertive);
    await settleIn(tester);
    expect(tester.takeAnnouncements().single.assertiveness,
        Assertiveness.assertive);
  });

  testWidgets('queued toasts are announced when they appear, not before',
      (tester) async {
    final queue = RootToastController(policy: RootToastPolicy.queue);
    addTearDown(queue.dispose);
    final ctx = await pumpHome(tester);
    final first = queue.show('first', context: ctx)!;
    queue.show('second', context: ctx);
    await settleIn(tester);
    expect(tester.takeAnnouncements().map((a) => a.message), ['first']);
    first.dismiss();
    await tester.pumpAndSettle();
    expect(tester.takeAnnouncements().map((a) => a.message), ['second']);
  });

  testWidgets('the toast is a semantics container with its message',
      (tester) async {
    final handle = tester.ensureSemantics();
    final ctx = await pumpHome(tester);
    toasts.show('Read me', context: ctx);
    await settleIn(tester);
    expect(find.bySemanticsLabel('Read me'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('RTL: the icon sits on the right of the text', (tester) async {
    final ctx = await pumpHome(tester, direction: TextDirection.rtl);
    toasts.show('تم الحفظ', context: ctx, type: RootToastType.success);
    await settleIn(tester);
    final icon =
        tester.getCenter(find.byIcon(Icons.check_circle_outline_rounded));
    final text = tester.getCenter(find.text('تم الحفظ'));
    expect(icon.dx, greaterThan(text.dx));
    expect(tester.takeAnnouncements().single.textDirection, TextDirection.rtl);
  });

  testWidgets('LTR: the icon sits on the left of the text', (tester) async {
    final ctx = await pumpHome(tester);
    toasts.show('Saved', context: ctx, type: RootToastType.success);
    await settleIn(tester);
    final icon =
        tester.getCenter(find.byIcon(Icons.check_circle_outline_rounded));
    final text = tester.getCenter(find.text('Saved'));
    expect(icon.dx, lessThan(text.dx));
  });

  testWidgets('reduced motion: fully visible on the first frame',
      (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    final ctx = await pumpHome(tester);
    toasts.show('Still', context: ctx);
    await tester.pump();
    final fade = tester.widget<FadeTransition>(find
        .ancestor(of: find.text('Still'), matching: find.byType(FadeTransition))
        .first);
    expect(fade.opacity.value, 1.0);
    final slide = tester.widget<SlideTransition>(find
        .ancestor(
            of: find.text('Still'), matching: find.byType(SlideTransition))
        .first);
    expect(slide.position.value, Offset.zero);
  });
}
