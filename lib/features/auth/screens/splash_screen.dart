import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:onetap365app/core/constants/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:onetap365app/providers/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _rippleController;
  late AnimationController _textController;
  late AnimationController _numberController;
  late AnimationController _pulseController;
  late AnimationController _iconController;
  late AnimationController _writingController;
  late AnimationController _logoController;

  late Animation<double> _rippleAnimation;
  late Animation<double> _rippleOpacity;
  late Animation<double> _textFadeAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _iconAnimation;
  late Animation<double> _logoAnimation;

  String _displayedText = '';
  final String _fullText = 'OneTap365';

  final List<IconData> _marketplaceIcons = [
    Icons.shopping_bag_outlined,
    Icons.directions_car_outlined,
    Icons.home_outlined,
    Icons.laptop_outlined,
    Icons.phone_iphone_outlined,
    Icons.chair_outlined,
  ];

  @override
  void initState() {
    super.initState();

    // Ripple effect for "One Tap" concept
    _rippleController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // Text animation
    _textController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Number 365 animation (rotation + scale)
    _numberController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    // Continuous pulse for marketplace activity
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    // Icons floating animation
    _iconController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Writing animation controller
    _writingController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..addListener(() {
        final progress = _writingController.value;
        final charsToShow = (_fullText.length * progress).floor();
        if (mounted) {
          setState(() {
            _displayedText = _fullText.substring(0, charsToShow);
          });
        }
      });

    // Logo animation controller
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Define animations
    _rippleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _rippleController, curve: Curves.easeOut),
    );

    _rippleOpacity = Tween<double>(begin: 0.6, end: 0.0).animate(
      CurvedAnimation(parent: _rippleController, curve: Curves.easeOut),
    );

    _textFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeIn),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _iconAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _iconController, curve: Curves.easeOut),
    );

    _logoAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOut),
    );

    // Start animations in sequence
    _startAnimations();
  }

  void _startAnimations() async {
    // Start ripple effect immediately
    _rippleController.forward();

    await Future.delayed(const Duration(milliseconds: 400));
    _writingController.forward();

    await Future.delayed(const Duration(milliseconds: 200));
    _iconController.forward();

    // Show logo after text animation completes
    await Future.delayed(const Duration(milliseconds: 800));
    _logoController.forward();

    // Navigate after all animations complete
    await Future.delayed(const Duration(milliseconds: 2200));
    if (!mounted) return;
    // --- FIX: Check auth and route accordingly ---
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.checkAuthStatus();
    if (authProvider.isAuthenticated) {
      Navigator.pushReplacementNamed(context, '/main');
    } else {
      Navigator.pushReplacementNamed(context, '/onboarding');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Floating marketplace icons in background
          ...List.generate(6, (index) {
            return AnimatedBuilder(
              animation: _iconAnimation,
              builder: (context, child) {
                final angle = (index * math.pi * 2 / 6);
                final distance = 150.0 * _iconAnimation.value;
                final opacity = 0.15 * (1 - _iconAnimation.value);

                return Positioned(
                  left: MediaQuery.of(context).size.width / 2 +
                      math.cos(angle) * distance -
                      20,
                  top: MediaQuery.of(context).size.height / 2 +
                      math.sin(angle) * distance -
                      20,
                  child: Opacity(
                    opacity: opacity,
                    child: Icon(
                      _marketplaceIcons[index],
                      size: 40,
                      color: AppColors.primary,
                    ),
                  ),
                );
              },
            );
          }),

          // Main content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo fade-in animation
                FadeTransition(
                  opacity: _logoAnimation,
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 0.8, end: 1.0).animate(
                      CurvedAnimation(
                        parent: _logoController,
                        curve: Curves.easeOut,
                      ),
                    ),
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.background.withOpacity(0.1),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.asset(
                          'assets/logos/img_1.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Animated brand name with pulse and writing effect
                ScaleTransition(
                  scale: _pulseAnimation,
                  child: AnimatedBuilder(
                    animation: _writingController,
                    builder: (context, child) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Display "OneTap" characters one by one
                          ...List.generate(
                            _displayedText.length > 6
                                ? 6
                                : _displayedText.length,
                            (index) {
                              final char = _displayedText[index];
                              return TweenAnimationBuilder<double>(
                                duration: const Duration(milliseconds: 100),
                                tween: Tween(begin: 0.0, end: 1.0),
                                builder: (context, value, child) {
                                  return Transform.scale(
                                    scale: value,
                                    child: Opacity(
                                      opacity: value,
                                      child: Text(
                                        char,
                                        style: GoogleFonts.inter(
                                          fontSize: 48,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white,
                                          letterSpacing: -1.5,
                                          shadows: [
                                            Shadow(
                                              color: AppColors.primary
                                                  .withOpacity(0.3),
                                              blurRadius: 20,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                          // Display "365" characters one by one
                          ...List.generate(
                            _displayedText.length > 6
                                ? _displayedText.length - 6
                                : 0,
                            (index) {
                              final char = _displayedText[index + 6];
                              return TweenAnimationBuilder<double>(
                                duration: const Duration(milliseconds: 100),
                                tween: Tween(begin: 0.0, end: 1.0),
                                builder: (context, value, child) {
                                  return Transform.scale(
                                    scale: value,
                                    child: Opacity(
                                      opacity: value,
                                      child: Text(
                                        char,
                                        style: GoogleFonts.inter(
                                          fontSize: 52,
                                          fontWeight: FontWeight.w900,
                                          color: AppColors.primary,
                                          letterSpacing: -1.5,
                                          shadows: [
                                            Shadow(
                                              color: AppColors.primary
                                                  .withOpacity(0.5),
                                              blurRadius: 25,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                          // Blinking cursor
                          if (_displayedText.length < _fullText.length)
                            AnimatedOpacity(
                              duration: const Duration(milliseconds: 500),
                              opacity:
                                  (_writingController.value * 10).floor() % 2 ==
                                          0
                                      ? 1.0
                                      : 0.0,
                              child: Container(
                                width: 3,
                                height: 52,
                                margin: const EdgeInsets.only(left: 2),
                                color: AppColors.primary,
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),

                const SizedBox(height: 20),

                // Animated tagline
                FadeTransition(
                  opacity: _textFadeAnimation,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      'Buy, Sell, Discover – All in One Place!',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Ripple effect circles positioned at center (behind content)
          Center(
            child: AnimatedBuilder(
              animation: _rippleController,
              builder: (context, child) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer ripple
                    Container(
                      width: 200 * _rippleAnimation.value,
                      height: 200 * _rippleAnimation.value,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primary
                              .withOpacity(_rippleOpacity.value),
                          width: 2,
                        ),
                      ),
                    ),
                    // Inner ripple
                    Container(
                      width: 140 * _rippleAnimation.value,
                      height: 140 * _rippleAnimation.value,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primary
                              .withOpacity(_rippleOpacity.value * 0.5),
                          width: 2,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // Pulsing loading dots at bottom
          Positioned(
            left: 0,
            right: 0,
            bottom: 100,
            child: FadeTransition(
              opacity: _textFadeAnimation,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (index) {
                  return AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      final delay = index * 0.2;
                      final animation = Tween<double>(
                        begin: 0.5,
                        end: 1.0,
                      ).animate(
                        CurvedAnimation(
                          parent: _pulseController,
                          curve: Interval(
                            delay,
                            delay + 0.4,
                            curve: Curves.easeInOut,
                          ),
                        ),
                      );

                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary.withOpacity(animation.value),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.5),
                              blurRadius: 8 * animation.value,
                              spreadRadius: 2 * animation.value,
                            ),
                          ],
                        ),
                      );
                    },
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _rippleController.dispose();
    _textController.dispose();
    _numberController.dispose();
    _pulseController.dispose();
    _iconController.dispose();
    _writingController.dispose();
    _logoController.dispose();
    super.dispose();
  }
}
