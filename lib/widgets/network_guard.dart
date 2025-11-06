import 'package:flutter/material.dart';
import '../services/network_service.dart';

/// NetworkGuard shows "Get a better Network already broski" message
/// only when isLoading=true AND network is offline.
/// Use this to wrap loading states in screens that need network.
class NetworkGuard extends StatefulWidget {
  final bool isLoading;
  final Widget child;

  const NetworkGuard({
    super.key,
    required this.isLoading,
    required this.child,
  });

  @override
  State<NetworkGuard> createState() => _NetworkGuardState();
}

class _NetworkGuardState extends State<NetworkGuard> {
  final _service = NetworkService();
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _service.initialize().then((_) {
      if (mounted) setState(() => _initialized = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) return widget.child;

    return StreamBuilder<bool>(
      stream: _service.online$,
      initialData: _service.isOnline,
      builder: (context, snapshot) {
        final isOnline = snapshot.data ?? true;
        final showMessage = widget.isLoading && !isOnline;

        if (!showMessage) {
          return widget.child;
        }

        // Show blocking message when loading + offline
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6C63FF), Color(0xFF00D9FF)],
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black45,
                      blurRadius: 20,
                      offset: Offset(0, 10),
                    )
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.wifi_off,
                      size: 64,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Get a better Network already broski',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Waiting for connection...',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
