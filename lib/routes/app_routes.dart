import 'package:flutter/material.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/profile/profile_choice_screen.dart';
import '../screens/profile/personal_profile_screen.dart';
import '../screens/profile/job_profile_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/home/create_post_screen.dart';
import '../screens/profile/edit_personal_screen.dart';
import '../screens/profile/edit_job_screen.dart';
import '../screens/home/settings_screen.dart';

class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const signup = '/signup';
  static const profileChoice = '/profile-choice';
  static const personalProfile = '/personal-profile';
  static const jobProfile = '/job-profile';
  
  static const home = '/home';
  static const createPost = '/create-post';
  static const editPersonal = '/profile/edit_personal';
  static const editJob = '/profile/edit_job';
  static const settings = '/settings';

  static Map<String, WidgetBuilder> routes = {
    splash: (context) => const SplashScreen(),
    login: (context) => const LoginScreen(),
    signup: (context) => const SignupScreen(),
    profileChoice: (context) => const ProfileChoiceScreen(),
    personalProfile: (context) => const PersonalProfileScreen(),
    jobProfile: (context) => const JobProfileScreen(),
    home: (context) => const HomePlaceholder(),
    createPost: (context) => const CreatePostScreen(),
    editPersonal: (context) => const EditPersonalScreen(),
    editJob: (context) => const EditJobScreen(),
    settings: (context) => const SettingsScreen(),
  };
}