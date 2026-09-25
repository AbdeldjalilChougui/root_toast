import 'package:flutter/widgets.dart';

/// What a toast is telling the user. Picks the default colours and icon.
enum RootToastType {
  /// Something finished well.
  success,

  /// Something failed.
  error,

  /// Neutral information.
  info,

  /// Something needs attention but did not fail.
  warning,
}

/// Where on the screen a toast is anchored.
enum RootToastPosition {
  /// Below the top safe-area inset.
  top,

  /// Above the bottom safe-area inset and the keyboard.
  bottom,

  /// Centred in the space left above the keyboard.
  center,
}

/// What happens when a toast is shown while others are already visible.
enum RootToastPolicy {
  /// The new toast replaces every visible toast immediately.
  replace,

  /// Toasts are shown one at a time, in order.
  queue,

  /// Toasts are shown together, up to a maximum; the oldest makes room.
  stack,
}

/// How urgently assistive technology announces a toast.
enum RootToastPoliteness {
  /// Announced when the screen reader is idle.
  polite,

  /// Interrupts whatever the screen reader is saying.
  assertive,
}

/// A button shown inside a toast, such as "Undo".
@immutable
class RootToastAction {
  /// Creates an action with a [label] and a callback.
  const RootToastAction({required this.label, required this.onPressed});

  /// The button text.
  final String label;

  /// Called when the button is pressed. The toast is dismissed afterwards.
  final VoidCallback onPressed;
}

/// Everything a [RootToastBuilder] needs to draw one toast.
@immutable
class RootToastData {
  /// Creates the data for one toast. Normally created by the package.
  const RootToastData({
    required this.message,
    required this.type,
    required this.icon,
    required this.position,
    required this.dismiss,
    required this.remaining,
    this.action,
  });

  /// The text to show.
  final String message;

  /// The toast type.
  final RootToastType type;

  /// The resolved icon: the caller's icon or the type's default.
  final IconData icon;

  /// Where the toast is anchored.
  final RootToastPosition position;

  /// The optional action button.
  final RootToastAction? action;

  /// Closes the toast with its exit animation.
  final VoidCallback dismiss;

  /// Goes from 1.0 down to 0.0 while the toast is on screen. It stops while
  /// the toast is pressed. Useful for a progress bar.
  final Animation<double> remaining;
}

/// Draws the body of a toast. Positioning, animation, gestures and semantics
/// announcements stay handled by the package.
typedef RootToastBuilder = Widget Function(
  BuildContext context,
  RootToastData toast,
);
