import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final connectivityProvider = StreamProvider<List<ConnectivityResult>>((ref) {
  final connectivity = Connectivity();
  return connectivity.onConnectivityChanged.handleError((_) {});
});

final connectivityCheckProvider = Provider<Connectivity>((ref) {
  return Connectivity();
});

bool isOfflineResult(List<ConnectivityResult> results) {
  return results.isEmpty || results.contains(ConnectivityResult.none);
}
