/// @docImport 'root_toast.dart';
/// @docImport 'scope.dart';
library;

import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import 'theme.dart';
import 'types.dart';

part 'toast_view.dart';

/// Owns the toasts of one app: which are visible, which wait in the queue,
/// and the single overlay entry that draws them in the root [Overlay].
///
/// Most apps use [RootToast.show], which goes through
/// [RootToast.defaultController] or the controller of the nearest
/// [RootToastScope]. Create your own controller to pick a [policy], or to
/// show toasts without a [BuildContext] through a [navigatorKey].
class RootToastController extends ChangeNotifier {
  /// Creates a controller.
  ///
  /// [maxVisible] only matters for [RootToastPolicy.stack].
  RootToastController({
    this.policy = RootToastPolicy.replace,
    this.maxVisible = 3,
    this.navigatorKey,
    this.politeness = RootToastPoliteness.polite,
    this.defaultPosition = RootToastPosition.top,
    this.builder,
    this.announce = true,
  }) : assert(maxVisible >= 1, 'maxVisible must be at least 1');

  /// What happens when a toast is shown while others are visible.
  final RootToastPolicy policy;

  /// How many toasts [RootToastPolicy.stack] shows at once.
  final int maxVisible;

  /// Used to find the root overlay when [show] is called without a context.
  ///
  /// Pass the same key to `MaterialApp.navigatorKey`.
  GlobalKey<NavigatorState>? navigatorKey;

  /// Default announcement politeness for screen readers.
  final RootToastPoliteness politeness;

  /// Position used when [show] is not given one.
  final RootToastPosition defaultPosition;

  /// Default body builder. Per-call builders take precedence.
  final RootToastBuilder? builder;

  /// Whether toasts are announced through [SemanticsService.announce].
  final bool announce;

  final List<_ToastRequest> _visible = <_ToastRequest>[];
  final Queue<_ToastRequest> _queue = Queue<_ToastRequest>();
  OverlayEntry? _entry;
  OverlayState? _overlay;
  int _nextId = 0;
  bool _disposed = false;

  /// The number of toasts on screen, including ones animating out.
  int get visibleCount => _visible.length;

  /// The number of toasts waiting under [RootToastPolicy.queue].
  int get queuedCount => _queue.length;

  /// How long a message stays up when no duration is given: longer messages
  /// need longer to read, bounded to 2.6 to 6 seconds.
  static Duration readingTime(String message) => Duration(
        milliseconds: (2200 + message.length * 45).clamp(2600, 6000),
      );

  /// Shows [message] and returns a handle to it, or `null` if nothing could
  /// be shown.
  ///
  /// With a [context], the toast goes into that context's root overlay and
  /// inherits its themes and text direction. Without one, [navigatorKey] is
  /// used. An unmounted context, a blank message or a missing overlay return
  /// `null` and print a debug message instead of throwing, so this is safe
  /// to call after an `await`.
  RootToastHandle? show(
    String message, {
    BuildContext? context,
    RootToastType type = RootToastType.info,
    Duration? duration,
    RootToastPosition? position,
    RootToastAction? action,
    IconData? icon,
    bool dismissOnTap = true,
    RootToastBuilder? builder,
    RootToastPoliteness? politeness,
  }) {
    assert(!_disposed, 'RootToastController used after dispose');
    if (message.trim().isEmpty) return null;

    OverlayState? overlay;
    CapturedThemes? themes;
    TextDirection? direction;
    if (context != null) {
      if (!context.mounted) {
        _debug('show("$message") was called with an unmounted context; '
            'nothing was shown.');
        return null;
      }
      overlay = Overlay.maybeOf(context, rootOverlay: true);
      if (overlay != null) {
        themes = InheritedTheme.capture(from: context, to: overlay.context);
        direction = Directionality.maybeOf(context);
      }
    }
    overlay ??= navigatorKey?.currentState?.overlay;
    if (overlay == null || !overlay.mounted) {
      _debug('no Overlay found for show("$message"). Pass a mounted context '
          'below a Navigator, or set navigatorKey.');
      return null;
    }

    direction ??= Directionality.maybeOf(overlay.context) ?? TextDirection.ltr;
    final request = _ToastRequest(
      id: _nextId++,
      message: message,
      type: type,
      duration: duration ?? _defaultDuration(message, action),
      position: position ?? defaultPosition,
      action: action,
      icon: icon,
      dismissOnTap: dismissOnTap,
      builder: builder ?? this.builder,
      politeness: politeness ?? this.politeness,
      themes: themes,
      direction: direction,
    );

    _attach(overlay);
    switch (policy) {
      case RootToastPolicy.replace:
        for (final old in List.of(_visible)) {
          _finish(old);
        }
        _reveal(request);
      case RootToastPolicy.queue:
        if (_visible.isEmpty) {
          _reveal(request);
        } else {
          _queue.add(request);
        }
      case RootToastPolicy.stack:
        while (_visible.length >= maxVisible) {
          _finish(_visible.first);
        }
        _reveal(request);
    }
    notifyListeners();
    return RootToastHandle._(this, request);
  }

  /// Closes every visible toast and drops every queued one.
  void dismissAll() {
    while (_queue.isNotEmpty) {
      _queue.removeFirst()._complete();
    }
    for (final request in List.of(_visible)) {
      _requestClose(request);
    }
  }

  @override
  void dispose() {
    _disposed = true;
    while (_queue.isNotEmpty) {
      _queue.removeFirst()._complete();
    }
    for (final request in _visible) {
      request._complete();
    }
    _visible.clear();
    _detach();
    super.dispose();
  }

  Duration _defaultDuration(String message, RootToastAction? action) {
    final reading = readingTime(message);
    // An action needs time to be found and reached.
    if (action != null && reading < const Duration(seconds: 4)) {
      return const Duration(seconds: 4);
    }
    return reading;
  }

  void _reveal(_ToastRequest request) {
    _visible.add(request);
    if (announce) {
      unawaited(SemanticsService.announce(
        request.message,
        request.direction,
        assertiveness: request.politeness == RootToastPoliteness.assertive
            ? Assertiveness.assertive
            : Assertiveness.polite,
      ));
    }
  }

  /// Asks a visible toast to animate out, or drops a queued one.
  void _requestClose(_ToastRequest request) {
    if (request.isClosed) return;
    if (_queue.remove(request)) {
      request._complete();
      notifyListeners();
      return;
    }
    final close = request.onCloseRequested;
    if (close != null) {
      close();
    } else {
      _closed(request);
    }
  }

  /// Removes [request] without an exit animation.
  void _finish(_ToastRequest request) {
    _visible.remove(request);
    request._complete();
  }

  /// Called by the toast view once its exit animation has finished.
  void _closed(_ToastRequest request) {
    if (_disposed) return;
    _finish(request);
    if (policy == RootToastPolicy.queue &&
        _visible.isEmpty &&
        _queue.isNotEmpty) {
      _reveal(_queue.removeFirst());
    }
    if (_visible.isEmpty && _queue.isEmpty) {
      _detach();
    }
    notifyListeners();
  }

  void _attach(OverlayState overlay) {
    if (_entry != null && identical(_overlay, overlay) && overlay.mounted) {
      return;
    }
    // A new overlay (hot restart, a new app in tests): whatever was showing
    // in the old one is gone with it.
    for (final request in List.of(_visible)) {
      _finish(request);
    }
    _detach();
    _overlay = overlay;
    _entry = OverlayEntry(builder: (_) => _ToastHost(controller: this));
    overlay.insert(_entry!);
  }

  void _detach() {
    final entry = _entry;
    _entry = null;
    _overlay = null;
    if (entry == null) return;
    entry.remove();
    entry.dispose();
  }

  void _debug(String text) {
    assert(() {
      debugPrint('RootToast: $text');
      return true;
    }());
  }
}

/// A reference to one shown (or queued) toast.
class RootToastHandle {
  RootToastHandle._(this._controller, this._request);

  final RootToastController _controller;
  final _ToastRequest _request;

  /// Whether the toast is still visible or waiting in the queue.
  bool get isActive => !_request.isClosed;

  /// Completes once the toast has left the screen, or was dropped from the
  /// queue.
  Future<void> get closed => _request.done.future;

  /// Closes the toast with its exit animation, or drops it from the queue.
  void dismiss() => _controller._requestClose(_request);
}

/// Internal state of one toast.
class _ToastRequest {
  _ToastRequest({
    required this.id,
    required this.message,
    required this.type,
    required this.duration,
    required this.position,
    required this.action,
    required this.icon,
    required this.dismissOnTap,
    required this.builder,
    required this.politeness,
    required this.themes,
    required this.direction,
  });

  /// Unique within its controller; keys the view.
  final int id;

  /// See [RootToastData.message].
  final String message;

  /// See [RootToastData.type].
  final RootToastType type;

  /// How long the toast stays up, not counting pauses.
  final Duration duration;

  /// See [RootToastData.position].
  final RootToastPosition position;

  /// See [RootToastData.action].
  final RootToastAction? action;

  /// Custom icon, if any.
  final IconData? icon;

  /// Whether a tap closes the toast.
  final bool dismissOnTap;

  /// Custom body builder, if any.
  final RootToastBuilder? builder;

  /// Announcement politeness.
  final RootToastPoliteness politeness;

  /// Themes captured from the calling context.
  final CapturedThemes? themes;

  /// Text direction captured from the calling context.
  final TextDirection direction;

  /// Set by the mounted view so the controller can trigger its exit.
  VoidCallback? onCloseRequested;

  /// Completes when the toast is gone.
  final Completer<void> done = Completer<void>();

  /// Whether the toast is gone.
  bool get isClosed => done.isCompleted;

  void _complete() {
    if (!done.isCompleted) done.complete();
  }
}
