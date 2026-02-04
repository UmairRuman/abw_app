// lib/features/auth/presentation/screens/splash/splash_screen.dart

import 'dart:math' as math;
import 'package:abw_app/shared/enums/user_role.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/theme/colors/app_colors_dark.dart';
import '../../../../../core/constants/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/auth_state.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _primaryController;
  late AnimationController _rotationController;
  late AnimationController _particleController;
  late AnimationController _pulseController;

  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoFadeAnimation;
  late Animation<double> _textSlideAnimation;
  late Animation<double> _textFadeAnimation;
  late Animation<double> _containerScaleAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _pulseAnimation;

  bool _navigating = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startAnimationSequence();
  }

  void _setupAnimations() {
    // Primary animation controller
    _primaryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    // Rotation controller for logo
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    // Particle effect controller
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    // Pulse effect controller
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    // Logo animations
    _logoScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.2)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 70,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.2, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
    ]).animate(_primaryController);

    _logoFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _primaryController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _containerScaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _primaryController,
        curve: Curves.easeOutBack,
      ),
    );

    // Text animations
    _textSlideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _primaryController,
        curve: const Interval(0.4, 0.8, curve: Curves.easeOut),
      ),
    );

    _textFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _primaryController,
        curve: const Interval(0.4, 0.8, curve: Curves.easeIn),
      ),
    );

    // Rotation animation
    _rotationAnimation = Tween<double>(begin: 0.0, end: 2 * math.pi).animate(
      CurvedAnimation(
        parent: _rotationController,
        curve: Curves.linear,
      ),
    );

    // Pulse animation
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );
  }

  void _startAnimationSequence() async {
  // Start animations
  _primaryController.forward();
  _rotationController.repeat();

  // Wait for animations AND auth check
  await Future.wait([
    Future.delayed(const Duration(milliseconds: 2500)), // Animation time
    _waitForAuthCheck(), // Wait for auth to initialize
  ]);

  if (mounted && !_navigating) {
    _navigating = true;
    _navigateBasedOnAuthState();
  }
}

// NEW METHOD: Wait for auth state to be ready
Future<void> _waitForAuthCheck() async {
  // Give auth provider time to check Firebase Auth state
  int attempts = 0;
  const maxAttempts = 10; // 5 seconds max (10 x 500ms)
  
  while (attempts < maxAttempts) {
    final authState = ref.read(authProvider);
    
    // If state is no longer loading, we're ready
    if (authState is! AuthLoading) {
      return;
    }
    
    // Wait a bit and try again
    await Future.delayed(const Duration(milliseconds: 500));
    attempts++;
  }
}

void _navigateBasedOnAuthState() {
  final authState = ref.read(authProvider);

  if (authState is Authenticated) {
    final user = authState.user;
    switch (user.role) {
      case UserRole.customer:
        context.go('/customer/home');
        break;
      case UserRole.rider:
        context.go('/rider/dashboard');
        break;
      case UserRole.admin:
        context.go('/admin/dashboard');
        break;
    }
  } else if (authState is RiderPendingApproval) {
    context.go('/rider/pending');
  } else {
    // Unauthenticated, AuthError, or AuthInitial - go to login
    context.go('/login');
  }
}

  @override
  void dispose() {
    _primaryController.dispose();
    _rotationController.dispose();
    _particleController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColorsDark.primary,
              AppColorsDark.primaryDark,
              AppColorsDark.secondary,
            ],
          ),
        ),
        child: Stack(
          children: [
            // Animated particles background
            _buildParticlesBackground(),

            // Main content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated Logo with container
                  _buildAnimatedLogo(),

                  SizedBox(height: 40.h),

                  // App Name with slide animation
                  _buildAppName(),

                  SizedBox(height: 8.h),

                  // Tagline with fade animation
                  _buildTagline(),

                  SizedBox(height: 80.h),

                  // Animated loading indicator
                  _buildLoadingIndicator(),
                ],
              ),
            ),

            // Bottom wave decoration
            _buildBottomWave(),
          ],
        ),
      ),
    );
  }

  Widget _buildParticlesBackground() {
    return AnimatedBuilder(
      animation: _particleController,
      builder: (context, child) {
        return CustomPaint(
          painter: ParticlesPainter(_particleController.value),
          size: Size.infinite,
        );
      },
    );
  }

  Widget _buildAnimatedLogo() {
    return AnimatedBuilder(
      animation: _primaryController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _logoFadeAnimation,
          child: ScaleTransition(
            scale: _logoScaleAnimation,
            child: AnimatedBuilder(
              animation: _rotationController,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _rotationAnimation.value,
                  child: Container(
                    width: 160.w,
                    height: 160.w,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColorsDark.white.withOpacity(0.95),
                          AppColorsDark.white.withOpacity(0.85),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(40.r),
                      boxShadow: [
                        BoxShadow(
                          color: AppColorsDark.primary.withOpacity(0.5),
                          blurRadius: 30,
                          spreadRadius: 5,
                          offset: const Offset(0, 10),
                        ),
                        BoxShadow(
                          color: AppColorsDark.secondary.withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 2,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Transform.rotate(
                      angle: -_rotationAnimation.value,
                      child: AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _pulseAnimation.value,
                            child: Center(
                              child: ShaderMask(
                                shaderCallback: (bounds) {
                                  return const LinearGradient(
                                    colors: [
                                      AppColorsDark.primary,
                                      AppColorsDark.secondary,
                                    ],
                                  ).createShader(bounds);
                                },
                                child: Icon(
                                  Icons.delivery_dining,
                                  size: 90.sp,
                                  color: AppColorsDark.white,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildAppName() {
    return AnimatedBuilder(
      animation: _primaryController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _textSlideAnimation.value),
          child: FadeTransition(
            opacity: _textFadeAnimation,
            child: ShaderMask(
              shaderCallback: (bounds) {
                return LinearGradient(
                  colors: [
                    AppColorsDark.white,
                    AppColorsDark.white.withOpacity(0.9),
                  ],
                ).createShader(bounds);
              },
              child: Text(
                AppConstants.appName,
                style: TextStyle(
                  fontSize: 38.sp,
                  fontWeight: FontWeight.w900,
                  color: AppColorsDark.white,
                  letterSpacing: 3,
                  shadows: [
                    Shadow(
                      color: AppColorsDark.black.withOpacity(0.3),
                      offset: const Offset(0, 4),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTagline() {
    return AnimatedBuilder(
      animation: _primaryController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _textSlideAnimation.value),
          child: FadeTransition(
            opacity: _textFadeAnimation,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: AppColorsDark.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(
                  color: AppColorsDark.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Text(
                'Fast & Reliable Delivery',
                style: TextStyle(
                  fontSize: 15.sp,
                  color: AppColorsDark.white,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingIndicator() {
    return AnimatedBuilder(
      animation: _primaryController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _textFadeAnimation,
          child: Column(
            children: [
              SizedBox(
                width: 50.w,
                height: 50.w,
                child: Stack(
                  children: [
                    // Outer ring
                    AnimatedBuilder(
                      animation: _rotationController,
                      builder: (context, child) {
                        return Transform.rotate(
                          angle: _rotationAnimation.value,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColorsDark.white.withOpacity(0.3),
                            ),
                          ),
                        );
                      },
                    ),
                    // Inner ring
                    AnimatedBuilder(
                      animation: _rotationController,
                      builder: (context, child) {
                        return Transform.rotate(
                          angle: -_rotationAnimation.value * 1.5,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColorsDark.white,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                'Loading...',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppColorsDark.white.withOpacity(0.8),
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomWave() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: AnimatedBuilder(
        animation: _particleController,
        builder: (context, child) {
          return CustomPaint(
            painter: WavePainter(_particleController.value),
            size: Size(MediaQuery.of(context).size.width, 150.h),
          );
        },
      ),
    );
  }
}

// Custom painter for particles
class ParticlesPainter extends CustomPainter {
  final double animationValue;

  ParticlesPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColorsDark.white.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 30; i++) {
      final x = (size.width / 30 * i + animationValue * 100) % size.width;
      final y = (size.height / 20 * (i % 10) + animationValue * 50) % size.height;
      final radius = (math.sin(animationValue * 2 * math.pi + i) + 1) * 2;

      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(ParticlesPainter oldDelegate) => true;
}

// Custom painter for wave effect
class WavePainter extends CustomPainter {
  final double animationValue;

  WavePainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColorsDark.white.withOpacity(0.0),
          AppColorsDark.white.withOpacity(0.1),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height * 0.5);

    for (double i = 0; i <= size.width; i++) {
      path.lineTo(
        i,
        size.height * 0.5 +
            math.sin((i / size.width * 2 * math.pi) + (animationValue * 2 * math.pi)) * 20,
      );
    }

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(WavePainter oldDelegate) => true;
}