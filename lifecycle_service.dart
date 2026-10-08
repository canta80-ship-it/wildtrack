import 'dart:async';
import 'package:flutter/widgets.dart';

final wildTrackRoutes = RouteObserver<ModalRoute<dynamic>>();

/// Poll only while the route, app and containing tab are visible.
mixin VisiblePolling<T extends StatefulWidget> on State<T>
    implements RouteAware {
  late final _observer = _PollingObserver(didChangeAppLifecycleState);
  Timer? _pollTimer;
  ModalRoute<dynamic>? _pollRoute;
  bool _covered = false;
  bool _resumed = true;
  bool _tabVisible = false;
  Duration get pollInterval;
  Future<void> poll();
  bool get pollVisible => mounted && _resumed && !_covered && _tabVisible;

  @override
  void initState() {
    super.initState();
    _resumed =
        WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    WidgetsBinding.instance.addObserver(_observer);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != _pollRoute) {
      wildTrackRoutes.unsubscribe(this);
      _pollRoute = route;
      if (route != null) wildTrackRoutes.subscribe(this, route);
    }
    _tabVisible = TickerMode.valuesOf(context).enabled;
    _configure();
  }

  void _configure() {
    _pollTimer?.cancel();
    _pollTimer = null;
    if (pollVisible) {
      unawaited(poll());
      _pollTimer = Timer.periodic(pollInterval, (_) {
        if (pollVisible) unawaited(poll());
      });
    }
  }

  void didChangeAppLifecycleState(AppLifecycleState state) {
    _resumed = state == AppLifecycleState.resumed;
    _configure();
  }

  @override
  void didPushNext() {
    _covered = true;
    _configure();
  }

  @override
  void didPopNext() {
    _covered = false;
    _configure();
  }

  @override
  void didPush() {
    _covered = false;
    _configure();
  }

  @override
  void didPop() {
    _covered = true;
    _configure();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    wildTrackRoutes.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(_observer);
    super.dispose();
  }
}

class _PollingObserver with WidgetsBindingObserver {
  _PollingObserver(this.changed);
  final void Function(AppLifecycleState) changed;
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) => changed(state);
}
