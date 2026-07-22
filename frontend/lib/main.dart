import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme.dart';
import 'screens/login_screen.dart';
import 'screens/registration_screen.dart';
import 'screens/home_screen.dart';
import 'screens/checkin_screen.dart';
import 'screens/doctors_screen.dart';
import 'screens/family_screen.dart';
import 'screens/profile_screen.dart';
import 'services/translation_service.dart';



import 'screens/splash_screen.dart';

void main() {
  runApp(const ArogyaApp());
}

typedef HealthTechApp = ArogyaApp;

class ArogyaApp extends StatefulWidget {
  const ArogyaApp({super.key});

  @override
  State<ArogyaApp> createState() => _ArogyaAppState();
}

class _ArogyaAppState extends State<ArogyaApp> {
  bool _showSplash = true;
  bool _isLoggedIn = false;
  bool _isProfileCompleted = false;
  String? _verifiedPhoneNumber;
  Map<String, dynamic>? _userProfile;

  void _handleLoginSuccess(String phoneNumber, Map<String, dynamic>? existingProfile) {
    setState(() {
      _verifiedPhoneNumber = phoneNumber;
      _isLoggedIn = true;
      if (existingProfile != null) {
        _userProfile = existingProfile;
        _isProfileCompleted = true;
      }
    });
  }

  void _handleProfileComplete(Map<String, dynamic> profile) {
    setState(() {
      _userProfile = profile;
      _isProfileCompleted = true;
    });
  }

  void _handleLogout() {
    setState(() {
      _isLoggedIn = false;
      _isProfileCompleted = false;
      _verifiedPhoneNumber = null;
      _userProfile = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Arogya',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.background,
        textTheme: GoogleFonts.interTextTheme(),
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
          surface: AppColors.background,
        ),
      ),
      home: _showSplash
          ? SplashScreen(
              onComplete: () {
                if (mounted) {
                  setState(() {
                    _showSplash = false;
                  });
                }
              },
            )
          : _buildRoot(),
    );
  }

  Widget _buildRoot() {
    if (!_isLoggedIn) {
      return LoginScreen(onLoginSuccess: _handleLoginSuccess);
    }
    if (!_isProfileCompleted) {
      return RegistrationScreen(
        phoneNumber: _verifiedPhoneNumber ?? "",
        onProfileComplete: _handleProfileComplete,
      );
    }
    return AppShell(
      userProfile: _userProfile,
      onLogout: _handleLogout,
    );
  }
}

class AppShell extends StatefulWidget {
  final Map<String, dynamic>? userProfile;
  final VoidCallback? onLogout;

  const AppShell({super.key, this.userProfile, this.onLogout});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _tab = 0;
  bool _isBottomNavVisible = true;

  void _navigate(int tab) => setState(() => _tab = tab);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _body(),
      ),
      bottomNavigationBar: ValueListenableBuilder<String>(

        valueListenable: TranslationService.currentLanguage,
        builder: (context, activeLang, child) {
          return Container(
            decoration: const BoxDecoration(
              color: Color(0xFFF7F4EE),
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _NavItem(icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: TranslationService.tr('home'), idx: 0, current: _tab, onTap: _navigate),
                    _NavItem(icon: Icons.medical_services_outlined, activeIcon: Icons.medical_services_rounded, label: TranslationService.tr('doctors'), idx: 1, current: _tab, onTap: _navigate),
                    _NavItem(icon: Icons.mic_outlined, activeIcon: Icons.mic_rounded, label: TranslationService.tr('check_in'), idx: 2, current: _tab, onTap: _navigate),
                    _NavItem(icon: Icons.people_outline_rounded, activeIcon: Icons.people_rounded, label: TranslationService.tr('family'), idx: 3, current: _tab, onTap: _navigate),
                    _NavItem(icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, label: TranslationService.tr('profile'), idx: 4, current: _tab, onTap: _navigate),
                  ],
                ),
              ),
            ),
          );
        },
      ),


    );
  }

  Widget _body() {
    return switch (_tab) {
      0 => SingleChildScrollView(physics: const BouncingScrollPhysics(), child: HomeScreen(onNavigate: _navigate, userProfile: widget.userProfile)),
      1 => SingleChildScrollView(physics: const BouncingScrollPhysics(), child: const DoctorsScreen()),
      2 => CheckInScreen(
          userProfile: widget.userProfile,
          onNavigate: _navigate,
          onScrollDirectionChanged: (isScrollingDown) {
            if (mounted && _isBottomNavVisible == isScrollingDown) {
              setState(() {
                _isBottomNavVisible = !isScrollingDown;
              });
            }
          },
        ),

      3 => SingleChildScrollView(physics: const BouncingScrollPhysics(), child: FamilyScreen(userProfile: widget.userProfile)),
      4 => SingleChildScrollView(physics: const BouncingScrollPhysics(), child: ProfileScreen(userProfile: widget.userProfile, onLogout: widget.onLogout)),
      _ => SingleChildScrollView(physics: const BouncingScrollPhysics(), child: HomeScreen(onNavigate: _navigate, userProfile: widget.userProfile)),
    };
  }
}


class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int idx;
  final int current;
  final void Function(int) onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.idx,
    required this.current,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final active = idx == current;
    return GestureDetector(
      onTap: () => onTap(idx),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: active ? AppColors.secondary : Colors.transparent,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Icon(
                active ? activeIcon : icon,
                size: 22,
                color: active ? AppColors.primary : AppColors.mutedFg,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: body(
                size: 11,
                weight: active ? FontWeight.w600 : FontWeight.w400,
                color: active ? AppColors.primary : AppColors.mutedFg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
