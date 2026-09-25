/// @docImport 'root_toast.dart';
library;

import 'package:flutter/widgets.dart';

import 'controller.dart';
import 'types.dart';

/// Makes a [RootToastController] available to [RootToast.show] and
/// [RootToast.of] below it.
///
/// Put it in `MaterialApp.builder` so every route can see it. Either pass a
/// [controller] you own (and can call without a context), or let the scope
/// create one from [policy], [maxVisible] and [navigatorKey].
class RootToastScope extends StatefulWidget {
  /// Creates a scope.
  const RootToastScope({
    super.key,
    this.controller,
    this.policy = RootToastPolicy.replace,
    this.maxVisible = 3,
    this.navigatorKey,
    required this.child,
  });

  /// A controller owned by the caller. When null, the scope owns one.
  final RootToastController? controller;

  /// Policy of the scope-owned controller.
  final RootToastPolicy policy;

  /// Stack limit of the scope-owned controller.
  final int maxVisible;

  /// Navigator key of the scope-owned controller, for context-free use.
  final GlobalKey<NavigatorState>? navigatorKey;

  /// The subtree that can show toasts.
  final Widget child;

  /// The nearest scope's controller, or null.
  ///
  /// Does not register a dependency, so it is safe to call from callbacks
  /// and `initState`.
  static RootToastController? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<_RootToastInherited>()?.controller;

  /// The nearest scope's controller. Throws if there is none.
  static RootToastController of(BuildContext context) {
    final controller = maybeOf(context);
    assert(controller != null, 'No RootToastScope found in context');
    return controller!;
  }

  @override
  State<RootToastScope> createState() => _RootToastScopeState();
}

class _RootToastScopeState extends State<RootToastScope> {
  RootToastController? _owned;

  RootToastController get _controller =>
      widget.controller ??
      (_owned ??= RootToastController(
        policy: widget.policy,
        maxVisible: widget.maxVisible,
        navigatorKey: widget.navigatorKey,
      ));

  @override
  void didUpdateWidget(RootToastScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    _owned?.navigatorKey = widget.navigatorKey;
  }

  @override
  void dispose() {
    _owned?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      _RootToastInherited(controller: _controller, child: widget.child);
}

class _RootToastInherited extends InheritedWidget {
  const _RootToastInherited({required this.controller, required super.child});

  final RootToastController controller;

  @override
  bool updateShouldNotify(_RootToastInherited oldWidget) =>
      controller != oldWidget.controller;
}
