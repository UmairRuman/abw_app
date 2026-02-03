// lib/features/auth/presentation/screens/login/login_screen.dart

import 'dart:developer';

import 'package:abw_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:abw_app/features/auth/presentation/providers/auth_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/theme/colors/app_colors_dark.dart';
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
  // Clear any error state when leaving screen

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
              const Icon(Icons.delivery_dining, color: AppColorsDark.primary),
              SizedBox(width: 12.w),
              Text('Login as Rider', style: AppTextStyles.bodyMedium().copyWith(color: AppColorsDark.textPrimary)),
            ],
          ),
        ),
        PopupMenuItem(
          value: UserRole.admin,
          child: Row(
            children: [
              const Icon(Icons.admin_panel_settings, color: AppColorsDark.secondary),
              SizedBox(width: 12.w),
              Text('Login as Admin', style: AppTextStyles.bodyMedium().copyWith(color: AppColorsDark.textPrimary)),
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

  // Call auth method
  await ref.read(authProvider.notifier).loginWithEmail(
    email: _emailController.text.trim(),
    password: _passwordController.text.trim(),
    role: _selectedRole,
    adminKey: _selectedRole == UserRole.admin 
        ? _adminKeyController.text.trim() 
        : null,
  );

  // Stop loading
  if (mounted) {
    setState(() => _isLoading = false);
  }

  // Check result
  final authState = ref.read(authProvider);
  
  if (authState is AuthError) {
    // Show error
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authState.message),
          backgroundColor: AppColorsDark.error,
        ),
      );
    }
  } else if (authState is Authenticated) {
    // Success - navigate based on role
    if (mounted) {
      switch (authState.user.role) {
        case UserRole.customer:
          context.go('/admin/dashboard');
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
    // Rider not approved
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


  @override
  Widget build(BuildContext context) {

    

    return Scaffold(
      backgroundColor: AppColorsDark.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: AppColorsDark.textPrimary),
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
                  style: AppTextStyles.headlineLarge().copyWith(
                    color: AppColorsDark.textPrimary,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  _getRoleSubtitle(),
                  style: AppTextStyles.bodyLarge().copyWith(
                    color: AppColorsDark.textSecondary,
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
                  style: AppTextStyles.bodyMedium().copyWith(
                    color: AppColorsDark.textPrimary,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    hintText: 'Enter your email',
                    prefixIcon: Icon(Icons.email_outlined),
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
                    style: AppTextStyles.bodyMedium().copyWith(
                      color: AppColorsDark.textPrimary,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Admin Access Key',
                      hintText: 'Enter admin key',
                      prefixIcon: Icon(Icons.key),
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
                      context.push('/forgot-password');
                    },
                    child: Text(
                      'Forgot Password?',
                      style: AppTextStyles.bodyMedium().copyWith(
                        color: AppColorsDark.primary,
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
                        ? const CircularProgressIndicator(color: AppColorsDark.background)
                        : const Text('Login'),
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
                      icon: Icon(
                        Icons.g_mobiledata,
                        size: 32.sp,
                        color: AppColorsDark.primary,
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
                        context.go('/signup/rider');
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
                      style: AppTextStyles.bodyMedium().copyWith(
                        color: AppColorsDark.textSecondary,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        if (_selectedRole == UserRole.rider) {
                          context.go('/signup/rider');
                        } else {
                          context.go('/signup/customer');
                        }
                      },
                      child: Text(
                        'Sign Up',
                        style: AppTextStyles.bodyMedium().copyWith(
                          color: AppColorsDark.primary,
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
}