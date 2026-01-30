// lib/features/auth/presentation/screens/login/login_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../core/theme/colors/app_colors.dart';
import '../../../../../core/theme/text_styles/app_text_styles.dart';
import '../../../../../shared/enums/user_role.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _adminKeyController = TextEditingController();

  UserRole _selectedRole = UserRole.customer;
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _adminKeyController.dispose();
    super.dispose();
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
        PopupMenuItem(
          value: UserRole.rider,
          child: Row(
            children: [
              const Icon(Icons.delivery_dining, color: AppColors.primary),
              SizedBox(width: 12.w),
              Text('Login as Rider', style: AppTextStyles.bodyMedium()),
            ],
          ),
        ),
        PopupMenuItem(
          value: UserRole.admin,
          child: Row(
            children: [
              const Icon(Icons.admin_panel_settings, color: AppColors.secondary),
              SizedBox(width: 12.w),
              Text('Login as Admin', style: AppTextStyles.bodyMedium()),
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

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // TODO: Implement login logic with provider
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() => _isLoading = false);
      // Navigate based on role
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);

    // TODO: Implement Google sign-in
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: AppColors.textPrimary),
            onPressed: _showRoleMenu,
            tooltip: 'Select Login Type',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 20.h),

                // Welcome Text
                Text(
                  'Welcome Back!',
                  style: AppTextStyles.headlineLarge(),
                ),
                SizedBox(height: 8.h),
                Text(
                  _getRoleSubtitle(),
                  style: AppTextStyles.bodyLarge().copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),

                SizedBox(height: 40.h),

                // Role Indicator
                _buildRoleIndicator(),

                SizedBox(height: 24.h),

                // Email Field
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    hintText: 'Enter your email',
                    prefixIcon: const Icon(Icons.email_outlined),
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
                  decoration: InputDecoration(
                    labelText: 'Password',
                    hintText: 'Enter your password',
                    prefixIcon: const Icon(Icons.lock_outline),
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

                // Admin Key Field (only for admin)
                if (_selectedRole == UserRole.admin) ...[
                  SizedBox(height: 16.h),
                  TextFormField(
                    controller: _adminKeyController,
                    decoration: InputDecoration(
                      labelText: 'Admin Access Key',
                      hintText: 'Enter admin key',
                      prefixIcon: const Icon(Icons.key),
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
                    onPressed: () {
                      Navigator.pushNamed(context, '/forgot-password');
                    },
                    child: Text(
                      'Forgot Password?',
                      style: AppTextStyles.bodyMedium().copyWith(
                        color: AppColors.primary,
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
                    child: _isLoading
                        ? const CircularProgressIndicator(color: AppColors.white)
                        : Text('Login'),
                  ),
                ),

                // Google Sign-In (only for customers)
                if (_selectedRole == UserRole.customer) ...[
                  SizedBox(height: 16.h),
                  SizedBox(
                    width: double.infinity,
                    height: 56.h,
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : _handleGoogleSignIn,
                      icon: Image.asset(
                        'assets/icons/google.png',
                        height: 24.h,
                        width: 24.w,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.g_mobiledata,
                          size: 32,
                        ),
                      ),
                      label: const Text('Continue with Google'),
                    ),
                  ),
                ],

                // Request Access (for riders)
                if (_selectedRole == UserRole.rider) ...[
                  SizedBox(height: 16.h),
                  Center(
                    child: TextButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(context, '/rider-request');
                      },
                      icon: const Icon(Icons.person_add),
                      label: const Text('Request Rider Access'),
                    ),
                  ),
                ],

                SizedBox(height: 32.h),

                // Sign Up Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: AppTextStyles.bodyMedium(),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/signup');
                      },
                      child: Text(
                        'Sign Up',
                        style: AppTextStyles.bodyMedium().copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 24.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getRoleSubtitle() {
    switch (_selectedRole) {
      case UserRole.customer:
        return 'Sign in to order delicious food';
      case UserRole.rider:
        return 'Sign in to start delivering';
      case UserRole.admin:
        return 'Admin portal access';
    }
  }

  Widget _buildRoleIndicator() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: _getRoleColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: _getRoleColor().withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            _getRoleIcon(),
            color: _getRoleColor(),
            size: 20.sp,
          ),
          SizedBox(width: 12.w),
          Text(
            'Logging in as ${_selectedRole.displayName}',
            style: AppTextStyles.bodyMedium().copyWith(
              color: _getRoleColor(),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Color _getRoleColor() {
    switch (_selectedRole) {
      case UserRole.customer:
        return AppColors.primary;
      case UserRole.rider:
        return AppColors.accent;
      case UserRole.admin:
        return AppColors.secondary;
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
}