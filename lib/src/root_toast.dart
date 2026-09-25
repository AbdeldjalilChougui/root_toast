import 'package:flutter/widgets.dart';

import 'controller.dart';
import 'scope.dart';
import 'types.dart';

/// Entry point: show toasts in the root overlay.
///
/// ```dart
/// RootToast.show(context, 'Saved', type: RootToastType.success);
/// RootToast.of(context).error('Could not save');
/// ```
///
/// Calls go to the controller of the nearest [RootToastScope], or to
/// [defaultController] when there is none.
abstract final class RootToast {
  /// The controller used when no [RootToastScope] is found. Uses
  /// [RootToastPolicy.replace]. Set its `navigatorKey` for context-free use.
  static final RootToastController defaultController = RootToastController();

  /// Shows [message] above every route, sheet, dialog and the keyboard.
  ///
  /// Returns null and prints a debug message when [context] is unmounted or
  /// has no overlay, so it is safe to call after an `await`.
  static RootToastHandle? show(
    BuildContext context,
    String message, {
    RootToastType type = RootToastType.info,
    Duration? duration,
    RootToastPosition? position,
    RootToastAction? action,
    IconData? icon,
    bool dismissOnTap = true,
    RootToastBuilder? builder,
    RootToastPoliteness? politeness,
  }) {
    return _controllerFor(context).show(
      message,
      context: context,
      type: type,
      duration: duration,
      position: position,
      action: action,
      icon: icon,
      dismissOnTap: dismissOnTap,
      builder: builder,
      politeness: politeness,
    );
  }

  /// A messenger bound to [context], with typed shortcuts.
  static RootToastMessenger of(BuildContext context) =>
      RootToastMessenger._(context, _controllerFor(context));

  /// Closes every toast of [defaultController].
  static void dismissAll() => defaultController.dismissAll();

  static RootToastController _controllerFor(BuildContext context) {
    if (!context.mounted) return defaultController;
    return RootToastScope.maybeOf(context) ?? defaultController;
  }
}

/// Shows toasts for one [BuildContext]. Obtained with [RootToast.of].
class RootToastMessenger {
  RootToastMessenger._(this._context, this.controller);

  final BuildContext _context;

  /// The controller the toasts go to.
  final RootToastController controller;

  /// Shows [message]. See [RootToast.show] for the parameters.
  RootToastHandle? show(
    String message, {
    RootToastType type = RootToastType.info,
    Duration? duration,
    RootToastPosition? position,
    RootToastAction? action,
    IconData? icon,
  }) =>
      controller.show(
        message,
        context: _context,
        type: type,
        duration: duration,
        position: position,
        action: action,
        icon: icon,
      );

  /// Shows a success toast.
  RootToastHandle? success(String message, {Duration? duration}) =>
      show(message, type: RootToastType.success, duration: duration);

  /// Shows an error toast.
  RootToastHandle? error(String message, {Duration? duration}) =>
      show(message, type: RootToastType.error, duration: duration);

  /// Shows an info toast.
  RootToastHandle? info(String message, {Duration? duration}) =>
      show(message, type: RootToastType.info, duration: duration);

  /// Shows a warning toast.
  RootToastHandle? warning(String message, {Duration? duration}) =>
      show(message, type: RootToastType.warning, duration: duration);

  /// Closes every toast of [controller].
  void dismissAll() => controller.dismissAll();
}
