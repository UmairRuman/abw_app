// lib/features/auth/presentation/screens/splash/splash_screen.dart

// REPLACE ENTIRE FILE:

import 'dart:developer';
import 'dart:math' as math;
import 'package:abw_app/core/services/order_cleanup_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/theme/colors/app_colors_dark.dart';
import '../../../../../core/constants/app_constants.dart';
import '../../../../../shared/enums/user_role.dart';
import '../../providers/auth_provider.dart';
import '../../providers/auth_state.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late AnimationController _shimmerController;

  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
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
    // Main animation controller
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    // Rotation controller
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    // Pulse controller
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    // Shimmer controller
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();

    // Scale animation for logo
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    // Fade animation
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    // Slide animation for text
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.4, 0.8, curve: Curves.easeOut),
      ),
    );

    // Rotation animation
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * math.pi,
    ).animate(_rotationController);

    // Pulse animation
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  void _startAnimationSequence() async {
    // Start animations
    _mainController.forward();
    _rotationController.repeat();

    // Wait for animations AND auth check
    await Future.wait([
      Future.delayed(const Duration(milliseconds: 2500)),
      _waitForAuthCheck(),
    ]);

    if (mounted && !_navigating) {
      _navigating = true;
      _navigateBasedOnAuthState();
    }
  }

  Future<void> _waitForAuthCheck() async {
    int attempts = 0;
    const maxAttempts = 10;

    while (attempts < maxAttempts) {
      final authState = ref.read(authProvider);

      if (authState is! AuthLoading) {
        return;
      }

      await Future.delayed(const Duration(milliseconds: 500));
      attempts++;
    }
  }

  void _navigateBasedOnAuthState() async {
    final authState = ref.read(authProvider);

    if (authState is Authenticated) {
      final user = authState.user;

      // Block check — customers only
      if (user.role == UserRole.customer) {
        final isBlocked = await _isUserBlocked(user.id);
        if (isBlocked && mounted) {
          await FirebaseAuth.instance.signOut();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Your account has been blocked. Please contact support.',
                ),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 4),
              ),
            );
            context.go('/login');
          }
          return;
        }
      }

      // Navigate first — user should never wait for cleanup
      if (mounted) {
        switch (user.role) {
          case UserRole.customer:
            final hasLocation = await _customerHasLocation(user.id);
            if (!hasLocation && mounted) {
              context.go('/customer/location-setup');
            } else if (mounted) {
              context.go('/customer/home');
            }
            break;
          case UserRole.rider:
            context.go('/rider/dashboard');
            break;
          case UserRole.admin:
            context.go('/admin/dashboard');
            break;
        }
      }

      // ✅ Trigger cleanup AFTER navigation — non-blocking, runs in isolate
      // Uses fire-and-forget: no await, isolate handles its own lifecycle
      OrderCleanupService.runIfNeeded(
        userId: user.id,
        role: user.role.name, // 'admin', 'rider', or 'customer'
      );
    } else if (authState is RiderPendingApproval) {
      if (mounted) context.go('/rider/pending');
    } else {
      if (mounted) context.go('/login');
    }
  }

  /// Returns true if the customer already has latitude/longitude saved.
  Future<bool> _customerHasLocation(String userId) async {
    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .get();

      if (!doc.exists) return false;
      final data = doc.data();
      final lat = data?['latitude'];
      final lng = data?['longitude'];
      // Has location if both are non-null and non-zero
      return lat != null && lng != null && lat != 0.0 && lng != 0.0;
    } catch (e) {
      return false; // On error, send to location picker anyway
    }
  }

  Future<bool> _isUserBlocked(String userId) async {
    try {
      // Step 1: Get the user's phone number
      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .get();

      if (!userDoc.exists) return false;

      final phone = userDoc.data()?['phone'] as String?;
      log('User phone number: $phone');
      if (phone == null || phone.isEmpty) return false;

      // Step 2: Check blocked_numbers collection
      final blockedQuery =
          await FirebaseFirestore.instance
              .collection('blocked_numbers')
              .where('phoneNumber', isEqualTo: phone)
              .where('isActive', isEqualTo: true)
              .limit(1)
              .get();
      log("Blocked query : ${blockedQuery.docs.isNotEmpty}");
      log(
        "Blocked query result count: ${blockedQuery.docs.first.data().toString()}",
      );
      return blockedQuery.docs.isNotEmpty;
    } catch (e) {
      // If the check fails (e.g. offline), do NOT block — fail open
      return false;
    }
  }

  @override
  void dispose() {
    _mainController.dispose();
    _rotationController.dispose();
    _pulseController.dispose();
    _shimmerController.dispose();
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
              Color(0xFFEC4899), // Pink
              Color(0xFFDB2777), // Darker Pink
              Color(0xFF9333EA), // Purple
              Color(0xFF6366F1), // Indigo
              Color(0xFF06B6D4), // Cyan
            ],
            stops: [0.0, 0.25, 0.5, 0.75, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Animated background circles
            _buildAnimatedCircles(),

            // Main content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 2),

                  // Logo with animations
                  _buildAnimatedLogo(),

                  SizedBox(height: 32.h),

                  // App name
                  _buildAppName(),

                  SizedBox(height: 12.h),

                  // Tagline
                  _buildTagline(),

                  const Spacer(flex: 2),

                  // Loading indicator
                  _buildLoadingIndicator(),

                  SizedBox(height: 60.h),
                ],
              ),
            ),

            // Shimmer overlay
            _buildShimmerOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedCircles() {
    return Stack(
      children: [
        // Circle 1
        Positioned(
          top: -100.h,
          right: -100.w,
          child: AnimatedBuilder(
            animation: _rotationController,
            builder: (context, child) {
              return Transform.scale(
                scale: 1.0 + math.sin(_rotationAnimation.value) * 0.1,
                child: Container(
                  width: 300.w,
                  height: 300.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.white.withOpacity(0.1),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Circle 2
        Positioned(
          bottom: -80.h,
          left: -80.w,
          child: AnimatedBuilder(
            animation: _rotationController,
            builder: (context, child) {
              return Transform.scale(
                scale: 1.0 + math.cos(_rotationAnimation.value) * 0.1,
                child: Container(
                  width: 250.w,
                  height: 250.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.white.withOpacity(0.08),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Circle 3
        Positioned(
          top: MediaQuery.of(context).size.height * 0.3,
          left: -50.w,
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  width: 150.w,
                  height: 150.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.white.withOpacity(0.06),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAnimatedLogo() {
    return AnimatedBuilder(
      animation: _mainController,
      builder: (context, child) {
        return ScaleTransition(
          scale: _scaleAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Container(
                    width: 140.w,
                    height: 140.w,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(35.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 30,
                          spreadRadius: 5,
                          offset: const Offset(0, 10),
                        ),
                        BoxShadow(
                          color: const Color(0xFFEC4899).withOpacity(0.3),
                          blurRadius: 40,
                          spreadRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: AnimatedBuilder(
                      animation: _rotationController,
                      builder: (context, child) {
                        return Transform.rotate(
                          angle: _rotationAnimation.value * 0.1,
                          child: Center(
                            child: ShaderMask(
                              shaderCallback: (bounds) {
                                return const LinearGradient(
                                  colors: [
                                    Color(0xFFEC4899),
                                    Color(0xFF9333EA),
                                    Color(0xFF06B6D4),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ).createShader(bounds);
                              },
                              child: Icon(
                                Icons.delivery_dining,
                                size: 70.sp,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        );
                      },
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
      animation: _mainController,
      builder: (context, child) {
        return SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Text(
              AppConstants.appName,
              style: TextStyle(
                fontSize: 42.sp,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 2,
                shadows: [
                  Shadow(
                    color: Colors.black.withOpacity(0.3),
                    offset: const Offset(0, 4),
                    blurRadius: 12,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTagline() {
    return AnimatedBuilder(
      animation: _mainController,
      builder: (context, child) {
        return SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(25.r),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.bolt, color: Colors.white, size: 16.sp),
                  SizedBox(width: 8.w),
                  Text(
                    'Fast & Reliable Delivery',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.white,
                      letterSpacing: 1,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingIndicator() {
    return AnimatedBuilder(
      animation: _mainController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              SizedBox(
                width: 40.w,
                height: 40.w,
                child: AnimatedBuilder(
                  animation: _rotationController,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _rotationAnimation.value,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.white.withOpacity(0.9),
                        ),
                        backgroundColor: Colors.white.withOpacity(0.2),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                'Loading...',
                style: TextStyle(
                  fontSize: 13.sp,
                  color: Colors.white.withOpacity(0.8),
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildShimmerOverlay() {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        return Positioned.fill(
          child: CustomPaint(painter: ShimmerPainter(_shimmerController.value)),
        );
      },
    );
  }
}

// Shimmer effect painter
class ShimmerPainter extends CustomPainter {
  final double progress;

  ShimmerPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.transparent,
              Colors.white.withOpacity(0.05),
              Colors.transparent,
            ],
            stops: [
              math.max(0, progress - 0.3),
              progress,
              math.min(1, progress + 0.3),
            ],
          ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(ShimmerPainter oldDelegate) =>
      progress != oldDelegate.progress;
}
