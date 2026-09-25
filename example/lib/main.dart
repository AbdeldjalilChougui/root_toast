import 'package:flutter/material.dart';
import 'package:root_toast/root_toast.dart';

void main() => runApp(const ExampleApp());

/// The example app.
class ExampleApp extends StatefulWidget {
  /// Creates the example app.
  const ExampleApp({super.key});

  @override
  State<ExampleApp> createState() => _ExampleAppState();
}

class _ExampleAppState extends State<ExampleApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  RootToastPolicy _policy = RootToastPolicy.replace;
  bool _rtl = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'root_toast example',
      navigatorKey: _navigatorKey,
      theme: ThemeData(
        colorSchemeSeed: Colors.teal,
        extensions: const [
          RootToastTheme(borderRadius: BorderRadius.all(Radius.circular(16))),
        ],
      ),
      builder: (context, child) => Directionality(
        textDirection: _rtl ? TextDirection.rtl : TextDirection.ltr,
        // A new key per policy gives a fresh scope-owned controller.
        child: RootToastScope(
          key: ValueKey(_policy),
          policy: _policy,
          navigatorKey: _navigatorKey,
          child: child!,
        ),
      ),
      home: DemoPage(
        policy: _policy,
        rtl: _rtl,
        onPolicy: (p) => setState(() => _policy = p),
        onRtl: (v) => setState(() => _rtl = v),
      ),
    );
  }
}

/// Buttons that exercise every feature.
class DemoPage extends StatelessWidget {
  /// Creates the demo page.
  const DemoPage({
    super.key,
    required this.policy,
    required this.rtl,
    required this.onPolicy,
    required this.onRtl,
  });

  /// Current queueing policy.
  final RootToastPolicy policy;

  /// Whether the app is right-to-left.
  final bool rtl;

  /// Changes the policy.
  final ValueChanged<RootToastPolicy> onPolicy;

  /// Toggles RTL.
  final ValueChanged<bool> onRtl;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('root_toast')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SegmentedButton<RootToastPolicy>(
            segments: [
              for (final p in RootToastPolicy.values)
                ButtonSegment(value: p, label: Text(p.name)),
            ],
            selected: {policy},
            onSelectionChanged: (s) => onPolicy(s.first),
          ),
          SwitchListTile(
            title: const Text('Right-to-left'),
            value: rtl,
            onChanged: onRtl,
          ),
          for (final type in RootToastType.values)
            FilledButton.tonal(
              onPressed: () => RootToast.show(
                context,
                rtl ? 'رسالة من نوع ${type.name}' : 'A ${type.name} message',
                type: type,
              ),
              child: Text('Show ${type.name}'),
            ),
          FilledButton.tonal(
            onPressed: () => RootToast.show(
              context,
              'Item deleted',
              position: RootToastPosition.bottom,
              action: RootToastAction(
                label: 'UNDO',
                onPressed: () => RootToast.of(context).success('Restored'),
              ),
            ),
            child: const Text('Bottom toast with action'),
          ),
          FilledButton.tonal(
            onPressed: () => _openSheet(context),
            child: const Text('Toast above a modal bottom sheet'),
          ),
          FilledButton.tonal(
            onPressed: () => _openDialog(context),
            child: const Text('Toast above a dialog'),
          ),
          FilledButton.tonal(
            onPressed: () => RootToastScope.of(context).show(
              'Shown without a BuildContext',
              position: RootToastPosition.center,
            ),
            child: const Text('Context-free (navigator key)'),
          ),
          FilledButton.tonal(
            onPressed: () => RootToast.show(
              context,
              'Custom builder',
              builder: (context, toast) => Card(
                child: ListTile(
                  leading: Icon(toast.icon),
                  title: Text(toast.message),
                  subtitle: AnimatedBuilder(
                    animation: toast.remaining,
                    builder: (_, __) =>
                        LinearProgressIndicator(value: toast.remaining.value),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: toast.dismiss,
                  ),
                ),
              ),
            ),
            child: const Text('Custom builder'),
          ),
          const Padding(
            padding: EdgeInsets.only(top: 16),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Focus me, then show a bottom toast',
              ),
            ),
          ),
          TextButton(
            onPressed: () => RootToast.of(context).dismissAll(),
            child: const Text('Dismiss all'),
          ),
        ].expand((w) => [w, const SizedBox(height: 8)]).toList(),
      ),
    );
  }

  void _openSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SizedBox(
        height: 320,
        child: Center(
          child: FilledButton(
            onPressed: () => RootToast.show(
              sheetContext,
              'Minimum price not met',
              type: RootToastType.error,
              position: RootToastPosition.bottom,
            ),
            child: const Text('Validate'),
          ),
        ),
      ),
    );
  }

  void _openDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Dialog'),
        content: const Text('The toast appears above this dialog.'),
        actions: [
          TextButton(
            onPressed: () => RootToast.of(dialogContext).warning('Heads up'),
            child: const Text('Toast'),
          ),
        ],
      ),
    );
  }
}
