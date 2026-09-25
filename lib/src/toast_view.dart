part of 'controller.dart';

const double _kEdgeGap = 8;
const double _kSideGap = 12;
const Duration _kEnter = Duration(milliseconds: 260);
const Duration _kExit = Duration(milliseconds: 200);

/// The single overlay entry of a controller. Lays its toasts out per
/// position and lets touches through everywhere else.
class _ToastHost extends StatefulWidget {
  const _ToastHost({required this.controller});

  final RootToastController controller;

  @override
  State<_ToastHost> createState() => _ToastHostState();
}

class _ToastHostState extends State<_ToastHost> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_changed);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_changed);
    super.dispose();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final toasts = widget.controller._visible;
    List<_ToastRequest> at(RootToastPosition p) =>
        toasts.where((t) => t.position == p).toList();

    final top = at(RootToastPosition.top);
    final bottom = at(RootToastPosition.bottom);
    final center = at(RootToastPosition.center);
    final left = media.padding.left + _kSideGap;
    final right = media.padding.right + _kSideGap;
    // `padding.bottom` already shrinks to zero when the keyboard is up, so
    // the sum is "safe area or keyboard", whichever is showing.
    final bottomInset = media.viewInsets.bottom + media.padding.bottom;

    return Stack(
      children: [
        if (top.isNotEmpty)
          Positioned(
            top: media.padding.top + _kEdgeGap,
            left: left,
            right: right,
            child: _column(top.reversed),
          ),
        if (bottom.isNotEmpty)
          Positioned(
            bottom: bottomInset + _kEdgeGap,
            left: left,
            right: right,
            child: _column(bottom),
          ),
        if (center.isNotEmpty)
          Positioned(
            top: media.padding.top,
            bottom: bottomInset,
            left: left,
            right: right,
            child: Center(child: _column(center)),
          ),
      ],
    );
  }

  Widget _column(Iterable<_ToastRequest> requests) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final request in requests)
          _ToastView(
            key: ValueKey<int>(request.id),
            request: request,
            controller: widget.controller,
          ),
      ],
    );
  }
}

/// One toast: animation, countdown, gestures and the card.
class _ToastView extends StatefulWidget {
  const _ToastView({
    super.key,
    required this.request,
    required this.controller,
  });

  final _ToastRequest request;
  final RootToastController controller;

  @override
  State<_ToastView> createState() => _ToastViewState();
}

class _ToastViewState extends State<_ToastView> with TickerProviderStateMixin {
  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: _kEnter,
    reverseDuration: _kExit,
  );
  late final AnimationController _countdown = AnimationController(
    vsync: this,
    duration: widget.request.duration,
  )..addStatusListener((status) {
      if (status == AnimationStatus.completed) _close();
    });
  late final AnimationController _snap = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 180),
  )..addListener(() => setState(() {}));

  late final Animation<double> _remaining = ReverseAnimation(_countdown);

  bool _started = false;
  bool _closing = false;
  bool _reduceMotion = false;
  int _pointers = 0;
  Offset _drag = Offset.zero;
  Offset _snapFrom = Offset.zero;

  @override
  void initState() {
    super.initState();
    widget.request.onCloseRequested = _close;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (_reduceMotion) {
      _entrance.duration = Duration.zero;
      _entrance.reverseDuration = Duration.zero;
    }
    if (!_started) {
      _started = true;
      _entrance.forward();
      _countdown.forward();
    }
  }

  @override
  void dispose() {
    if (widget.request.onCloseRequested == _close) {
      widget.request.onCloseRequested = null;
    }
    _entrance.dispose();
    _countdown.dispose();
    _snap.dispose();
    super.dispose();
  }

  Future<void> _close() async {
    if (_closing || !mounted) return;
    _closing = true;
    _countdown.stop();
    await _entrance.reverse().orCancel.catchError((Object _) {});
    if (!mounted) return;
    widget.controller._closed(widget.request);
  }

  void _pointerDown(PointerDownEvent _) {
    _pointers++;
    _countdown.stop();
  }

  void _pointerUp(PointerEvent _) {
    if (_pointers > 0) _pointers--;
    if (_pointers == 0 && !_closing && mounted) _countdown.forward();
  }

  Offset get _offset {
    if (_snap.isAnimating) {
      return Offset.lerp(
        _snapFrom,
        Offset.zero,
        Curves.easeOut.transform(_snap.value),
      )!;
    }
    return _drag;
  }

  void _dragUpdate(DragUpdateDetails details) {
    _snap.stop();
    final next = _drag + details.delta;
    setState(() {
      _drag = Offset(
          next.dx,
          switch (widget.request.position) {
            RootToastPosition.top => next.dy < 0 ? next.dy : 0,
            RootToastPosition.bottom => next.dy > 0 ? next.dy : 0,
            RootToastPosition.center => 0,
          });
    });
  }

  void _dragEnd(DragEndDetails details) {
    final velocity = details.velocity.pixelsPerSecond;
    final vertical = switch (widget.request.position) {
      RootToastPosition.top => -velocity.dy,
      RootToastPosition.bottom => velocity.dy,
      RootToastPosition.center => 0.0,
    };
    final far = _drag.dx.abs() > 80 || _drag.dy.abs() > 40;
    final fast = velocity.dx.abs() > 700 || vertical > 700;
    if (far || fast) {
      _close();
      return;
    }
    _snapFrom = _drag;
    _drag = Offset.zero;
    _snap.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final request = widget.request;
    Widget child = Builder(builder: _buildBody);

    child = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: request.dismissOnTap ? _close : null,
      // Claims long presses so releasing after reading does not count as a
      // tap and dismiss the toast.
      onLongPress: () {},
      onPanUpdate: _dragUpdate,
      onPanEnd: _dragEnd,
      child: child,
    );
    child = Listener(
      onPointerDown: _pointerDown,
      onPointerUp: _pointerUp,
      onPointerCancel: _pointerUp,
      child: child,
    );

    final offset = _offset;
    child = Transform.translate(
      offset: offset,
      child: Opacity(
        opacity: (1 - offset.distance / 240).clamp(0.2, 1.0),
        child: child,
      ),
    );

    final curved = CurvedAnimation(
      parent: _entrance,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    final begin = switch (request.position) {
      RootToastPosition.top => const Offset(0, -0.6),
      RootToastPosition.bottom => const Offset(0, 0.6),
      RootToastPosition.center => const Offset(0, 0.15),
    };
    child = SlideTransition(
      position: _reduceMotion
          ? const AlwaysStoppedAnimation<Offset>(Offset.zero)
          : Tween<Offset>(begin: begin, end: Offset.zero).animate(curved),
      child: FadeTransition(opacity: _entrance, child: child),
    );

    child = Padding(
      padding: const EdgeInsets.symmetric(vertical: _kEdgeGap / 2),
      child: Semantics(container: true, child: child),
    );
    child = Directionality(textDirection: request.direction, child: child);
    return request.themes?.wrap(child) ?? child;
  }

  Widget _buildBody(BuildContext context) {
    final request = widget.request;
    final theme = RootToastTheme.resolve(context);
    final data = RootToastData(
      message: request.message,
      type: request.type,
      icon: request.icon ?? _defaultIcon(request.type),
      position: request.position,
      action: request.action,
      dismiss: _close,
      remaining: _remaining,
    );
    final custom = request.builder;
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: theme.maxWidth ?? 560),
        child: custom != null
            ? custom(context, data)
            : _DefaultToastCard(data: data, theme: theme),
      ),
    );
  }

  static IconData _defaultIcon(RootToastType type) => switch (type) {
        RootToastType.success => Icons.check_circle_outline_rounded,
        RootToastType.error => Icons.error_outline_rounded,
        RootToastType.info => Icons.info_outline_rounded,
        RootToastType.warning => Icons.warning_amber_rounded,
      };
}

class _DefaultToastCard extends StatelessWidget {
  const _DefaultToastCard({required this.data, required this.theme});

  final RootToastData data;
  final RootToastTheme theme;

  @override
  Widget build(BuildContext context) {
    final foreground = theme.foregroundFor(data.type) ?? Colors.white;
    final action = data.action;
    return Material(
      key: const ValueKey('root_toast_card'),
      color: theme.backgroundFor(data.type),
      elevation: theme.elevation ?? 6,
      borderRadius: theme.borderRadius,
      child: Padding(
        padding: theme.padding ?? const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(data.icon, color: foreground, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                data.message,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: (theme.textStyle ?? const TextStyle())
                    .copyWith(color: foreground),
              ),
            ),
            if (action != null) ...[
              const SizedBox(width: 8),
              TextButton(
                style: TextButton.styleFrom(foregroundColor: foreground),
                onPressed: () {
                  action.onPressed();
                  data.dismiss();
                },
                child: Text(action.label),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
