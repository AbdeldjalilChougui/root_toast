# root_toast

Toasts drawn in the root `Overlay`, so modal bottom sheets, dialogs and the
keyboard never hide them. That is a known problem with `ScaffoldMessenger`
SnackBars, which are painted by the Scaffold underneath any route pushed on
top of it.

[![pub package](https://img.shields.io/pub/v/root_toast.svg)](https://pub.dev/packages/root_toast)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

## Features

- Drawn in the **root overlay**, above every route: sheets, dialogs, menus.
  Stays on top of routes pushed after it appears.
- Four types (`success`, `error`, `info`, `warning`) and three positions
  (`top`, `bottom`, `center`), an optional action button and a custom icon.
- Three policies: **replace** (the default), **queue** (one at a time, in
  order) and **stack** (several at once, up to `maxVisible`).
- Swipe to dismiss (sideways, or towards the nearest edge), tap to dismiss.
- The timer **pauses while the toast is pressed** and resumes on release.
- Stays **above the keyboard** (`viewInsets`) and inside the safe area.
- **Safe after `await`**: an unmounted context returns `null` and prints a
  debug message instead of throwing.
- Material 3 defaults from the `ColorScheme`, a `RootToastTheme`
  `ThemeExtension`, and a custom builder for a completely different look.
- Inherits the caller's `Theme` and `Directionality` (RTL ready).
- Screen-reader announcements through `SemanticsService` with configurable
  politeness (`polite` / `assertive`).
- Honours **reduced motion** (`MediaQuery.disableAnimations`).
- `dismissAll()`, and a handle per toast with `dismiss()` and `closed`.

## Install

```yaml
dependencies:
  root_toast: ^0.1.0
```

## Usage

### From a widget

```dart
import 'package:root_toast/root_toast.dart';

RootToast.show(context, 'Saved', type: RootToastType.success);

RootToast.show(
  context,
  'Item deleted',
  position: RootToastPosition.bottom,
  duration: const Duration(seconds: 5),
  action: RootToastAction(label: 'UNDO', onPressed: restore),
);

// Typed shortcuts.
RootToast.of(context).error('Could not reach the server');
```

It is safe to call right after an `await`, even if the screen was popped:

```dart
Future<void> submit(BuildContext context) async {
  await api.save();
  RootToast.show(context, 'Saved'); // no-op with a debug message if unmounted
}
```

### Policy, and use without a BuildContext

Put a `RootToastScope` in `MaterialApp.builder`. `RootToast.show` and
`RootToast.of` below it use its controller. Give the controller the app's
navigator key to show toasts from services, blocs or interceptors:

```dart
final navigatorKey = GlobalKey<NavigatorState>();
final toasts = RootToastController(
  policy: RootToastPolicy.stack,
  maxVisible: 3,
  navigatorKey: navigatorKey,
);

MaterialApp(
  navigatorKey: navigatorKey,
  builder: (context, child) =>
      RootToastScope(controller: toasts, child: child!),
  home: const HomePage(),
);

// Anywhere, no context needed:
toasts.show('Sync finished', type: RootToastType.success);
toasts.dismissAll();
```

Without a scope, calls go to `RootToast.defaultController` (replace policy).
Set `RootToast.defaultController.navigatorKey = navigatorKey` to use it
without a context.

### Theming

```dart
ThemeData(
  colorSchemeSeed: Colors.teal,
  extensions: const [
    RootToastTheme(
      successBackground: Color(0xFF1B5E20),
      borderRadius: BorderRadius.all(Radius.circular(20)),
      elevation: 2,
      maxWidth: 480,
    ),
  ],
);
```

Unset fields default to: error = `ColorScheme.error`/`onError`, info =
`inverseSurface`/`onInverseSurface`, success = green 800, warning = amber,
text = `bodyMedium` semi-bold.

### Custom builder

Positioning, animation, gestures, pause-on-press and announcements stay
handled; you draw the body.

```dart
RootToast.show(
  context,
  'Uploading',
  builder: (context, toast) => Card(
    child: ListTile(
      leading: Icon(toast.icon),
      title: Text(toast.message),
      subtitle: AnimatedBuilder(
        animation: toast.remaining,
        builder: (_, __) => LinearProgressIndicator(value: toast.remaining.value),
      ),
      trailing: IconButton(icon: const Icon(Icons.close), onPressed: toast.dismiss),
    ),
  ),
);
```

A controller-wide `builder` can be passed to `RootToastController`.

### Accessibility

Each toast is announced once when it appears (queued toasts when their turn
comes). Choose urgency per controller or per call:

```dart
RootToastController(politeness: RootToastPoliteness.assertive);
RootToast.show(context, 'Payment failed', politeness: RootToastPoliteness.assertive);
```

Without an explicit `duration`, the time on screen grows with the message
length (2.6 to 6 seconds; at least 4 seconds with an action).

## Limitations

- One overlay entry per controller; toasts of two different controllers are
  independent and may overlap if both use the same position.
- Announcements use `SemanticsService.announce`, which newer Flutter
  releases are replacing with a view-aware API; it works on Flutter 3.24 to
  3.35, the range this package is tested against (3.35.6).
- Swipe thresholds (80 px sideways, 40 px vertically, or a 700 px/s fling)
  are fixed.
- In **replace** and **stack** mode, a toast that is pushed out disappears
  without an exit animation, so the layout does not jump twice.

## License

MIT, see [LICENSE](LICENSE).

Made by [Abdeldjalil Chougui](https://abdeldjalilchougui.biz/).
