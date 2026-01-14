import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:milpress/features/widgets/network_offline_sheet.dart';
import 'package:milpress/providers/connectivity_provider.dart';

class ConnectivitySheetListener extends ConsumerStatefulWidget {
  final Widget child;
  final GlobalKey<NavigatorState> navigatorKey;

  const ConnectivitySheetListener({
    super.key,
    required this.child,
    required this.navigatorKey,
  });

  @override
  ConsumerState<ConnectivitySheetListener> createState() =>
      _ConnectivitySheetListenerState();
}

class _ConnectivitySheetListenerState
    extends ConsumerState<ConnectivitySheetListener> {
  bool _isSheetVisible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkInitialConnectivity();
    });
  }

  void _handleConnectivityChange(
    AsyncValue<List<ConnectivityResult>>? previous,
    AsyncValue<List<ConnectivityResult>> next,
  ) {
    if (next.hasError) {
      return;
    }
    next.whenData((result) {
      final isOffline = isOfflineResult(result);
      if (isOffline && !_isSheetVisible) {
        _showOfflineSheet();
      } else if (!isOffline && _isSheetVisible) {
        _hideOfflineSheet();
      }
    });
  }

  Future<void> _showOfflineSheet() async {
    if (!mounted || _isSheetVisible) {
      return;
    }
    final navigatorContext = widget.navigatorKey.currentContext;
    if (navigatorContext == null) {
      return;
    }
    _isSheetVisible = true;
    await showModalBottomSheet<void>(
      context: navigatorContext,
      useRootNavigator: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return NetworkOfflineSheet(
          onViewDownloads: _handleViewDownloads,
          onRetry: _handleRetry,
        );
      },
    );
    if (mounted) {
      _isSheetVisible = false;
    }
  }

  void _hideOfflineSheet() {
    if (!mounted || !_isSheetVisible) {
      return;
    }
    final navigatorState = widget.navigatorKey.currentState;
    if (navigatorState != null && navigatorState.canPop()) {
      navigatorState.pop();
    }
    _isSheetVisible = false;
  }

  Future<void> _handleRetry() async {
    try {
      final connectivity = ref.read(connectivityCheckProvider);
      final result = await connectivity.checkConnectivity();
      if (!isOfflineResult(result)) {
        _hideOfflineSheet();
      }
    } on MissingPluginException {
      // Plugin not registered (e.g., hot reload); ignore.
    }
  }

  Future<void> _checkInitialConnectivity() async {
    try {
      final connectivity = ref.read(connectivityCheckProvider);
      final result = await connectivity.checkConnectivity();
      if (isOfflineResult(result)) {
        _showOfflineSheet();
      }
    } on MissingPluginException {
      // Plugin not registered (e.g., hot reload); ignore.
    }
  }

  void _handleViewDownloads() {
    _hideOfflineSheet();
    final navigatorContext = widget.navigatorKey.currentContext;
    if (navigatorContext == null) {
      return;
    }
    GoRouter.of(navigatorContext).push('/downloaded-lessons');
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<List<ConnectivityResult>>>(
      connectivityProvider,
      _handleConnectivityChange,
    );
    return widget.child;
  }
}
