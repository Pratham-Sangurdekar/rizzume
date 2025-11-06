import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../profile/user_profile_view_screen.dart';

class SearchTab extends StatefulWidget {
  final String? initialUserId;

  const SearchTab({super.key, this.initialUserId});

  @override
  State<SearchTab> createState() => SearchTabState();
}

class SearchTabState extends State<SearchTab> {
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentUserId = widget.initialUserId;
  }

  void showUserProfile(String userId) {
    setState(() {
      _currentUserId = userId;
    });
  }

  void clearProfile() {
    setState(() {
      _currentUserId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUserId != null) {
      return UserProfileViewScreen(
        userId: _currentUserId!,
        onBack: clearProfile,
      );
    }

    // Default search/empty state
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.person_search_rounded,
                size: 80,
                color: Colors.white.withOpacity(0.3),
              ),
              const SizedBox(height: 24),
              Text(
                'Search & Discover',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  'Tap on any username or profile picture\nin the app to view their profile here',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
