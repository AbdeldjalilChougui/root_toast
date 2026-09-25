import 'package:flutter_test/flutter_test.dart';
import 'package:root_toast/root_toast.dart';

import 'helpers.dart';

void main() {
  testWidgets('replace (default): a second toast replaces the first',
      (tester) async {
    final toasts = RootToastController();
    addTearDown(toasts.dispose);
    expect(toasts.policy, RootToastPolicy.replace);
    final ctx = await pumpHome(tester);

    final first = toasts.show('First', context: ctx);
    await settleIn(tester);
    toasts.show('Second', context: ctx);
    await settleIn(tester);

    expect(find.text('First'), findsNothing);
    expect(find.text('Second'), findsOneWidget);
    expect(first!.isActive, isFalse);
    expect(toasts.visibleCount, 1);
  });

  testWidgets('queue: the next toast waits until the current one closes',
      (tester) async {
    final toasts = RootToastController(policy: RootToastPolicy.queue);
    addTearDown(toasts.dispose);
    final ctx = await pumpHome(tester);

    final first =
        toasts.show('One', context: ctx, duration: const Duration(seconds: 1));
    toasts.show('Two', context: ctx, duration: const Duration(seconds: 1));
    toasts.show('Three', context: ctx, duration: const Duration(seconds: 1));
    await settleIn(tester);

    expect(find.text('One'), findsOneWidget);
    expect(find.text('Two'), findsNothing);
    expect(toasts.queuedCount, 2);

    first!.dismiss();
    await advance(tester, const Duration(milliseconds: 500));
    expect(find.text('One'), findsNothing);
    expect(find.text('Two'), findsOneWidget);
    expect(toasts.queuedCount, 1);

    // Two expires by itself and Three follows.
    await advance(tester, const Duration(milliseconds: 1000));
    expect(find.text('Two'), findsNothing);
    expect(find.text('Three'), findsOneWidget);
    expect(toasts.queuedCount, 0);
  });

  testWidgets('stack: up to maxVisible at once, the oldest makes room',
      (tester) async {
    final toasts =
        RootToastController(policy: RootToastPolicy.stack, maxVisible: 2);
    addTearDown(toasts.dispose);
    final ctx = await pumpHome(tester);

    toasts.show('A', context: ctx);
    toasts.show('B', context: ctx);
    await settleIn(tester);
    expect(find.text('A'), findsOneWidget);
    expect(find.text('B'), findsOneWidget);

    toasts.show('C', context: ctx);
    await settleIn(tester);
    expect(find.text('A'), findsNothing);
    expect(find.text('B'), findsOneWidget);
    expect(find.text('C'), findsOneWidget);
    expect(toasts.visibleCount, 2);

    // Stacked cards do not overlap each other.
    final b = tester.getRect(find.text('B'));
    final c = tester.getRect(find.text('C'));
    expect(b.overlaps(c), isFalse);
  });

  test('stack requires maxVisible of at least 1', () {
    expect(() => RootToastController(maxVisible: 0), throwsAssertionError);
  });

  testWidgets('dismissAll removes visible toasts and clears the queue',
      (tester) async {
    final toasts = RootToastController(policy: RootToastPolicy.queue);
    addTearDown(toasts.dispose);
    final ctx = await pumpHome(tester);
    toasts.show('X', context: ctx);
    toasts.show('Y', context: ctx);
    await settleIn(tester);

    toasts.dismissAll();
    await tester.pumpAndSettle();
    expect(find.text('X'), findsNothing);
    expect(find.text('Y'), findsNothing);
    expect(toasts.visibleCount, 0);
    expect(toasts.queuedCount, 0);
  });

  testWidgets('handle.closed completes when the toast goes away',
      (tester) async {
    final toasts = RootToastController();
    addTearDown(toasts.dispose);
    final ctx = await pumpHome(tester);
    final handle = toasts.show('Bye', context: ctx)!;
    var closed = false;
    handle.closed.then((_) => closed = true);
    await settleIn(tester);
    handle.dismiss();
    await tester.pumpAndSettle();
    expect(closed, isTrue);
  });
}
