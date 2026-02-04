// lib/features/auth/presentation/screens/login/login_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/theme/colors/app_colors_dark.dart';
import '../../../../../core/theme/text_styles/app_text_styles.dart';
import '../../../../../shared/enums/user_role.dart';
import '../../providers/auth_provider.dart';
import '../../providers/auth_state.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _adminKeyController = TextEditingController();

  UserRole _selectedRole = UserRole.customer;
  bool _obscurePassword = true;
  bool _isLoading = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _adminKeyController.dispose();
    super.dispose();
  }

  void _onRoleChanged(UserRole newRole) {
    setState(() {
      _selectedRole = newRole;
    });
    // Restart animation when role changes
    _animationController.reset();
    _animationController.forward();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    await ref
        .read(authProvider.notifier)
        .loginWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          role: _selectedRole,
          adminKey:
              _selectedRole == UserRole.admin
                  ? _adminKeyController.text.trim()
                  : null,
        );

    if (mounted) {
      setState(() => _isLoading = false);
    }

    final authState = ref.read(authProvider);

    if (authState is AuthError) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 12.w),
                Expanded(child: Text(authState.message)),
              ],
            ),
            backgroundColor: AppColorsDark.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else if (authState is Authenticated) {
      if (mounted) {
        switch (authState.user.role) {
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
      }
    } else if (authState is RiderPendingApproval) {
      if (mounted) {
        context.go('/rider/pending');
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);

    await ref.read(authProvider.notifier).loginWithGoogle();

    if (mounted) {
      setState(() => _isLoading = false);
    }

    final authState = ref.read(authProvider);

    if (authState is AuthError) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authState.message),
            backgroundColor: AppColorsDark.error,
          ),
        );
      }
    } else if (authState is Authenticated) {
      if (mounted) {
        context.go('/customer/home');
      }
    }
  }

  void _showRoleMenu() {
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        MediaQuery.of(context).size.width - 20.w,
        AppBar().preferredSize.height + 40.h,
        20.w,
        0,
      ),
      items: [
        // Customer option (always show)
        PopupMenuItem(
          value: UserRole.customer,
          child: Row(
            children: [
              const Icon(Icons.person, color: AppColorsDark.primary),
              SizedBox(width: 12.w),
              Text(
                'Login as Customer',
                style: AppTextStyles.bodyMedium().copyWith(
                  color: AppColorsDark.textPrimary,
                ),
              ),
            ],
          ),
        ),

        // Rider option
        PopupMenuItem(
          value: UserRole.rider,
          child: Row(
            children: [
              const Icon(Icons.delivery_dining, color: AppColorsDark.accent),
              SizedBox(width: 12.w),
              Text(
                'Login as Rider',
                style: AppTextStyles.bodyMedium().copyWith(
                  color: AppColorsDark.textPrimary,
                ),
              ),
            ],
          ),
        ),

        // Admin option
        PopupMenuItem(
          value: UserRole.admin,
          child: Row(
            children: [
              const Icon(
                Icons.admin_panel_settings,
                color: AppColorsDark.secondary,
              ),
              SizedBox(width: 12.w),
              Text(
                'Login as Admin',
                style: AppTextStyles.bodyMedium().copyWith(
                  color: AppColorsDark.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
      elevation: 8,
    ).then((value) {
      if (value != null) {
        setState(() {
          _selectedRole = value;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: _getRoleColor(_selectedRole),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: AppColorsDark.textPrimary),
            onPressed: _showRoleMenu,
            tooltip: 'Select Login Type',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(gradient: _getRoleGradient()),
        child: SafeArea(
          child: Column(
            children: [
              // Top Role Selector Tabs
              // _buildRoleTabs(),

              // Form Content
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(24.w),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Column(
                        children: [
                          SizedBox(height: 20.h),

                          // Role Icon & Title
                          _buildRoleHeader(),

                          SizedBox(height: 40.h),

                          // Login Form Card
                          _buildLoginForm(),

                          SizedBox(height: 24.h),

                          // Additional Actions
                          _buildAdditionalActions(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleTabs() {
    return Container(
      margin: EdgeInsets.all(16.w),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppColorsDark.surface.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColorsDark.white.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          _buildRoleTab(UserRole.customer, Icons.person, 'Customer'),
          SizedBox(width: 4.w),
          _buildRoleTab(UserRole.rider, Icons.delivery_dining, 'Rider'),
          SizedBox(width: 4.w),
          _buildRoleTab(UserRole.admin, Icons.admin_panel_settings, 'Admin'),
        ],
      ),
    );
  }

  Widget _buildRoleTab(UserRole role, IconData icon, String label) {
    final isSelected = _selectedRole == role;
    final color = _getRoleColor(role);

    return Expanded(
      child: InkWell(
        onTap: () => _onRoleChanged(role),
        borderRadius: BorderRadius.circular(12.r),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          padding: EdgeInsets.symmetric(vertical: 12.h),
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(12.r),
            boxShadow:
                isSelected
                    ? [
                      BoxShadow(
                        color: color.withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                    : [],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color:
                    isSelected
                        ? AppColorsDark.white
                        : AppColorsDark.white.withOpacity(0.6),
                size: 24.sp,
              ),
              SizedBox(height: 4.h),
              Text(
                label,
                style: AppTextStyles.labelSmall().copyWith(
                  color:
                      isSelected
                          ? AppColorsDark.white
                          : AppColorsDark.white.withOpacity(0.6),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleHeader() {
    return Column(
      children: [
        // Animated Icon
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 100.w,
          height: 100.w,
          decoration: BoxDecoration(
            color: AppColorsDark.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: _getRoleColor(_selectedRole).withOpacity(0.5),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Icon(
            _getRoleIcon(),
            size: 50.sp,
            color: _getRoleColor(_selectedRole),
          ),
        ),

        SizedBox(height: 20.h),

        // Title
        Text(
          _getRoleTitle(),
          style: AppTextStyles.headlineMedium().copyWith(
            color: AppColorsDark.white,
            fontWeight: FontWeight.bold,
          ),
        ),

        SizedBox(height: 8.h),

        // Subtitle
        Text(
          _getRoleSubtitle(),
          style: AppTextStyles.bodyMedium().copyWith(
            color: AppColorsDark.white.withOpacity(0.8),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildLoginForm() {
    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: AppColorsDark.surface,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: AppColorsDark.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            // Email Field
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              style: AppTextStyles.bodyMedium().copyWith(
                color: AppColorsDark.textPrimary,
              ),
              decoration: InputDecoration(
                labelText: 'Email',
                hintText: 'Enter your email',
                prefixIcon: Icon(
                  Icons.email_outlined,
                  color: _getRoleColor(_selectedRole),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Email is required';
                }
                if (!value.contains('@')) {
                  return 'Invalid email address';
                }
                return null;
              },
            ),

            SizedBox(height: 16.h),

            // Password Field
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              style: AppTextStyles.bodyMedium().copyWith(
                color: AppColorsDark.textPrimary,
              ),
              decoration: InputDecoration(
                labelText: 'Password',
                hintText: 'Enter your password',
                prefixIcon: Icon(
                  Icons.lock_outline,
                  color: _getRoleColor(_selectedRole),
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  onPressed: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Password is required';
                }
                if (value.length < 8) {
                  return 'Password must be at least 8 characters';
                }
                return null;
              },
            ),

            // Admin Key Field
            if (_selectedRole == UserRole.admin) ...[
              SizedBox(height: 16.h),
              TextFormField(
                controller: _adminKeyController,
                style: AppTextStyles.bodyMedium().copyWith(
                  color: AppColorsDark.textPrimary,
                ),
                decoration: InputDecoration(
                  labelText: 'Admin Access Key',
                  hintText: 'Enter admin key',
                  prefixIcon: Icon(
                    Icons.vpn_key,
                    color: _getRoleColor(_selectedRole),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Admin key is required';
                  }
                  return null;
                },
              ),
            ],

            SizedBox(height: 12.h),

            // Forgot Password
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => context.push('/forgot-password'),
                child: Text(
                  'Forgot Password?',
                  style: AppTextStyles.bodySmall().copyWith(
                    color: _getRoleColor(_selectedRole),
                  ),
                ),
              ),
            ),

            SizedBox(height: 24.h),

            // Login Button
            SizedBox(
              width: double.infinity,
              height: 56.h,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _getRoleColor(_selectedRole),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                child:
                    _isLoading
                        ? SizedBox(
                          width: 24.w,
                          height: 24.w,
                          child: const CircularProgressIndicator(
                            color: AppColorsDark.white,
                            strokeWidth: 2,
                          ),
                        )
                        : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(_getRoleIcon(), size: 20.sp),
                            SizedBox(width: 8.w),
                            Text(
                              'Login as ${_selectedRole.displayName}',
                              style: AppTextStyles.titleSmall().copyWith(
                                color: AppColorsDark.white,
                              ),
                            ),
                          ],
                        ),
              ),
            ),

            // Google Sign-In (Customer only)
            if (_selectedRole == UserRole.customer) ...[
              SizedBox(height: 16.h),
              Row(
                children: [
                  const Expanded(child: Divider(color: AppColorsDark.border)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: Text(
                      'OR',
                      style: AppTextStyles.labelSmall().copyWith(
                        color: AppColorsDark.textTertiary,
                      ),
                    ),
                  ),
                  const Expanded(child: Divider(color: AppColorsDark.border)),
                ],
              ),
              SizedBox(height: 16.h),
              SizedBox(
                width: double.infinity,
                height: 56.h,
                child: OutlinedButton.icon(
                  onPressed: _isLoading ? null : _handleGoogleSignIn,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColorsDark.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  icon: Icon(
                    Icons.g_mobiledata,
                    size: 28.sp,
                    color: AppColorsDark.primary,
                  ),
                  label: const Text('Continue with Google'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAdditionalActions() {
    return Column(
      children: [
        // Rider Request Access
        if (_selectedRole == UserRole.rider) ...[
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: AppColorsDark.accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: AppColorsDark.accent.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: AppColorsDark.accent,
                  size: 20.sp,
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    'New riders must request access and await approval',
                    style: AppTextStyles.bodySmall().copyWith(
                      color: AppColorsDark.white.withOpacity(0.9),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),
        ],

        // Sign Up Link
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Don't have an account? ",
              style: AppTextStyles.bodyMedium().copyWith(
                color: AppColorsDark.white.withOpacity(0.8),
              ),
            ),
            TextButton(
              onPressed: () {
                switch (_selectedRole) {
                  case UserRole.customer:
                    context.push('/signup/customer');
                    break;
                  case UserRole.rider:
                    context.push('/signup/rider');
                    break;
                  case UserRole.admin:
                    context.push('/signup/admin');
                    break;
                }
              },
              child: Text(
                'Sign Up',
                style: AppTextStyles.bodyMedium().copyWith(
                  color: AppColorsDark.white,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                  decorationColor: AppColorsDark.white,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Helper methods
  LinearGradient _getRoleGradient() {
    switch (_selectedRole) {
      case UserRole.customer:
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColorsDark.primary.withOpacity(0.9),
            AppColorsDark.primaryDark,
          ],
        );
      case UserRole.rider:
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColorsDark.accent.withOpacity(0.9),
            AppColorsDark.accent.withOpacity(0.7),
          ],
        );
      case UserRole.admin:
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColorsDark.secondary.withOpacity(0.9),
            AppColorsDark.secondary.withOpacity(0.7),
          ],
        );
    }
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.customer:
        return AppColorsDark.primary;
      case UserRole.rider:
        return AppColorsDark.accent;
      case UserRole.admin:
        return AppColorsDark.secondary;
    }
  }

  IconData _getRoleIcon() {
    switch (_selectedRole) {
      case UserRole.customer:
        return Icons.person;
      case UserRole.rider:
        return Icons.delivery_dining;
      case UserRole.admin:
        return Icons.admin_panel_settings;
    }
  }

  String _getRoleTitle() {
    switch (_selectedRole) {
      case UserRole.customer:
        return 'Welcome Back!';
      case UserRole.rider:
        return 'Rider Portal';
      case UserRole.admin:
        return 'Admin Access';
    }
  }

  String _getRoleSubtitle() {
    switch (_selectedRole) {
      case UserRole.customer:
        return 'Sign in to order delicious food';
      case UserRole.rider:
        return 'Start delivering and earning today';
      case UserRole.admin:
        return 'Manage platform operations';
    }
  }
}
