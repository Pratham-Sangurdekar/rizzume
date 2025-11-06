import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

/// NetworkService provides a simple stream of online/offline state
/// It relies on connectivity_plus which uses Android BroadcastReceiver under the hood.
class NetworkService {
  NetworkService._internal();
  static final NetworkService _instance = NetworkService._internal();
  factory NetworkService() => _instance;

  final Connectivity _connectivity = Connectivity();
  final StreamController<bool> _onlineController = StreamController<bool>.broadcast();

  StreamSubscription<List<ConnectivityResult>>? _subscription;

  /// Stream of online (true) / offline (false)
  Stream<bool> get online$ => _onlineController.stream;

  /// Returns the last known online state if available.
  bool _isOnline = true;
  bool get isOnline => _isOnline;

  Future<void> initialize() async {
    // Emit current state
    final initial = await _connectivity.checkConnectivity();
    _isOnline = initial != ConnectivityResult.none;
    _onlineController.add(_isOnline);

    // Listen for changes
    _subscription?.cancel();
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      final result = results.isNotEmpty ? results.first : ConnectivityResult.none;
      final online = result != ConnectivityResult.none;
      if (online != _isOnline) {
        _isOnline = online;
        _onlineController.add(online);
      }
    });
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    await _onlineController.close();
  }
}
