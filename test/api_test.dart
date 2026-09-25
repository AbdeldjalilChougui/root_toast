import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:root_toast/root_toast.dart';

import 'helpers.dart';

void main() {
  tearDown(RootToast.dismissAll);

  testWidgets('RootToast.show uses the default controller', (tester) async {
    final ctx = await pumpHome(tester);
    final handle = RootToast.show(ctx, 'Static', type: RootToastType.success);
    await settleIn(tester);
    expect(handle, isNotNull);
    expect(find.text('Static'), findsOneWidget);
    expect(RootToast.defaultController.visibleCount, 1);
    RootToast.dismissAll();
    await tester.pumpAndSettle();
    expect(find.text('Static'), findsNothing);
  });

  testWidgets('RootToast.of offers typed shortcuts', (tester) async {
    final ctx = await pumpHome(tester);
    final messenger = RootToast.of(ctx);
    messenger.error('Oops');
    await settleIn(tester);
    expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
    messenger.success('Yay');
    await settleIn(tester);
    expect(find.byIcon(Icons.check_circle_outline_rounded), findsOneWidget);
    messenger.warning('Hmm');
    await settleIn(tester);
    expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    messenger.info('Fyi');
    await settleIn(tester);
    expect(find.byIcon(Icons.info_outline_rounded), findsOneWidget);
    messenger.dismissAll();
    await tester.pumpAndSettle();
    expect(find.text('Fyi'), findsNothing);
  });

  testWidgets('RootToastScope supplies its controller to RootToast.show',
      (tester) async {
    final scoped = RootToastController(policy: RootToastPolicy.stack);
    addTearDown(scoped.dispose);
    final ctx = await pumpHome(
      tester,
      builder: (context, child) =>
          RootToastScope(controller: scoped, child: child!),
    );
    expect(RootToastScope.maybeOf(ctx), same(scoped));
    RootToast.show(ctx, 'one');
    RootToast.show(ctx, 'two');
    await settleIn(tester);
    expect(scoped.visibleCount, 2);
    expect(find.text('one'), findsOneWidget);
    expect(find.text('two'), findsOneWidget);
  });

  testWidgets('RootToastScope can create and own its controller',
      (tester) async {
    final key = GlobalKey<NavigatorState>();
    final ctx = await pumpHome(
      tester,
      navigatorKey: key,
      builder: (context, child) => RootToastScope(
        navigatorKey: key,
        policy: RootToastPolicy.queue,
        child: child!,
      ),
    );
    final controller = RootToastScope.of(ctx);
    expect(controller.policy, RootToastPolicy.queue);
    controller.show('context-free');
    await settleIn(tester);
    expect(find.text('context-free'), findsOneWidget);
  });

  testWidgets('RootToastTheme colours and shape are applied', (tester) async {
    const theme = RootToastTheme(
      errorBackground: Color(0xFF123456),
      errorForeground: Color(0xFFFEDCBA),
      borderRadius: BorderRadius.all(Radius.circular(3)),
    );
    final ctx = await pumpHome(
      tester,
      theme: ThemeData(extensions: const [theme]),
    );
    RootToast.show(ctx, 'Themed', type: RootToastType.error);
    await settleIn(tester);
    final material = tester.widget<Material>(
      find.byKey(const ValueKey('root_toast_card')),
    );
    expect(material.color, const Color(0xFF123456));
    expect(material.borderRadius, const BorderRadius.all(Radius.circular(3)));
    final text = tester.widget<Text>(find.text('Themed'));
    final style = DefaultTextStyle.of(tester.element(find.text('Themed')))
        .style
        .merge(text.style);
    expect(style.color, const Color(0xFFFEDCBA));
  });

  testWidgets('defaults follow the Material 3 colour scheme', (tester) async {
    final data = ThemeData(colorSchemeSeed: Colors.indigo);
    final ctx = await pumpHome(tester, theme: data);
    RootToast.show(ctx, 'Err', type: RootToastType.error);
    await settleIn(tester);
    final material = tester.widget<Material>(
      find.byKey(const ValueKey('root_toast_card')),
    );
    expect(material.color, data.colorScheme.error);
  });

  test('RootToastTheme copyWith and lerp', () {
    const a = RootToastTheme(infoBackground: Color(0xFF000000), elevation: 0);
    const b = RootToastTheme(infoBackground: Color(0xFFFFFFFF), elevation: 10);
    final mid = a.lerp(b, 0.5);
    expect(mid.elevation, 5);
    expect(mid.infoBackground, isNotNull);
    expect(a.copyWith(elevation: 2).elevation, 2);
    expect(a.copyWith(elevation: 2).infoBackground, const Color(0xFF000000));
  });

  testWidgets('a custom builder replaces the default card', (tester) async {
    final ctx = await pumpHome(tester);
    RootToast.show(
      ctx,
      'Custom',
      type: RootToastType.warning,
      builder: (context, toast) => GestureDetector(
        onTap: toast.dismiss,
        child: Text('${toast.type.name}: ${toast.message}'),
      ),
    );
    await settleIn(tester);
    expect(find.text('warning: Custom'), findsOneWidget);
    expect(find.byKey(const ValueKey('root_toast_card')), findsNothing);
    await tester.tap(find.text('warning: Custom'));
    await tester.pumpAndSettle();
    expect(find.text('warning: Custom'), findsNothing);
  });

  testWidgets('the toast inherits a local Theme from the calling context',
      (tester) async {
    late BuildContext inner;
    await pumpHome(tester);
    await tester.pumpWidget(MaterialApp(
      home: Theme(
        data: ThemeData(
          extensions: const [RootToastTheme(infoBackground: Color(0xFF00FF00))],
        ),
        child: Builder(builder: (context) {
          inner = context;
          return const Scaffold();
        }),
      ),
    ));
    RootToast.show(inner, 'Local');
    await settleIn(tester);
    final material = tester.widget<Material>(
      find.byKey(const ValueKey('root_toast_card')),
    );
    expect(material.color, const Color(0xFF00FF00));
  });
}
