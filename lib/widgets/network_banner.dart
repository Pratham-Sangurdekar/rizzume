import 'package:flutter/material.dart';
import '../services/network_service.dart';

class NetworkBanner extends StatefulWidget {
  const NetworkBanner({super.key});

  @override
  State<NetworkBanner> createState() => _NetworkBannerState();
}

class _NetworkBannerState extends State<NetworkBanner> {
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
    if (!_initialized) return const SizedBox.shrink();
    return StreamBuilder<bool>(
      stream: _service.online$,
      initialData: _service.isOnline,
      builder: (context, snapshot) {
        final online = snapshot.data ?? true;
        return AnimatedPositioned(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          top: online ? -60 : 0,
          left: 0,
          right: 0,
          child: _BannerContent(),
        );
      },
    );
  }
}

class _BannerContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Container(
        height: 48,
        margin: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: const LinearGradient(
            colors: [Color(0xFF6C63FF), Color(0xFF00D9FF)],
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black54,
              blurRadius: 12,
              offset: Offset(0, 6),
            )
          ],
        ),
        alignment: Alignment.center,
        child: const Text(
          'Get a better Network already broski',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
