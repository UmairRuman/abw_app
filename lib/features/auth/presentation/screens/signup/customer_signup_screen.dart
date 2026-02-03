// lib/features/auth/presentation/screens/signup/customer_signup_screen.dart

import 'package:abw_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:abw_app/features/auth/presentation/providers/auth_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/theme/colors/app_colors_dark.dart';
import '../../../../../core/theme/text_styles/app_text_styles.dart';

class CustomerSignupScreen extends ConsumerStatefulWidget {
  const CustomerSignupScreen({super.key});

  @override
  ConsumerState<CustomerSignupScreen> createState() =>
      _CustomerSignupScreenState();
}

class _CustomerSignupScreenState extends ConsumerState<CustomerSignupScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  bool _agreeToTerms = false;

  // Password strength
  double _passwordStrength = 0.0;
  String _passwordStrengthText = '';
  Color _passwordStrengthColor = AppColorsDark.error;

 
  void _setupAnimations() {
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_fadeController);

    _slideController.forward();
    _fadeController.forward();
  }

 @override
void initState() {
  super.initState();
  _setupAnimations();
  

}



@override
void dispose() {
 
  _slideController.dispose();
  _fadeController.dispose();
  _nameController.dispose();
  _emailController.dispose();
  _phoneController.dispose();
  _passwordController.dispose();
  _confirmPasswordController.dispose();
  super.dispose();
}

  void _calculatePasswordStrength(String password) {
    double strength = 0.0;
    String strengthText = 'Weak';
    Color strengthColor = AppColorsDark.error;

    if (password.isEmpty) {
      setState(() {
        _passwordStrength = 0.0;
        _passwordStrengthText = '';
        _passwordStrengthColor = AppColorsDark.error;
      });
      return;
    }

    // Length check
    if (password.length >= 8) strength += 0.25;
    if (password.length >= 12) strength += 0.15;

    // Contains uppercase
    if (RegExp(r'[A-Z]').hasMatch(password)) strength += 0.2;

    // Contains lowercase
    if (RegExp(r'[a-z]').hasMatch(password)) strength += 0.1;

    // Contains number
    if (RegExp(r'[0-9]').hasMatch(password)) strength += 0.2;

    // Contains special character
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) strength += 0.1;

    // Determine strength text and color
    if (strength < 0.4) {
      strengthText = 'Weak';
      strengthColor = AppColorsDark.error;
    } else if (strength < 0.7) {
      strengthText = 'Medium';
      strengthColor = AppColorsDark.warning;
    } else {
      strengthText = 'Strong';
      strengthColor = AppColorsDark.success;
    }

    setState(() {
      _passwordStrength = strength;
      _passwordStrengthText = strengthText;
      _passwordStrengthColor = strengthColor;
    });
  }

Future<void> _handleSignup() async {
  if (!_formKey.currentState!.validate()) return;

  if (!_agreeToTerms) {
    _showSnackBar('Please agree to Terms & Conditions', isError: true);
    return;
  }

  setState(() => _isLoading = true);

  // Call signup
  await ref.read(authProvider.notifier).signUpCustomer(
    email: _emailController.text.trim(),
    password: _passwordController.text.trim(),
    name: _nameController.text.trim(),
    phone: _phoneController.text.trim(),
  );

  if (mounted) {
    setState(() => _isLoading = false);
  }

  // Check result
  final authState = ref.read(authProvider);
  
  if (authState is AuthError) {
    if (mounted) {
      _showSnackBar(authState.message, isError: true);
    }
  } else if (authState is Authenticated) {
    if (mounted) {
      _showSnackBar('Account created successfully!', isError: false);
      // Wait a bit for user to see success message
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        context.go('/customer/home');
      }
    }
  }
}

Future<void> _handleGoogleSignup() async {
  setState(() => _isLoading = true);

  await ref.read(authProvider.notifier).loginWithGoogle();

  if (mounted) {
    setState(() => _isLoading = false);
  }

  final authState = ref.read(authProvider);
  
  if (authState is AuthError) {
    if (mounted) {
      _showSnackBar(authState.message, isError: true);
    }
  } else if (authState is Authenticated) {
    if (mounted) {
      _showSnackBar('Welcome!', isError: false);
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        context.go('/customer/home');
      }
    }
  }
}


  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: AppColorsDark.white,
            ),
            SizedBox(width: 12.w),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? AppColorsDark.error : AppColorsDark.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColorsDark.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverAppBar(
              floating: true,
              backgroundColor: AppColorsDark.surface,
              elevation: 0,
              
              title: Text(
                'Sign Up',
                style: AppTextStyles.titleLarge().copyWith(
                  color: AppColorsDark.textPrimary,
                ),
              ),
            ),

            // Content
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.w),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 20.h),

                          // Animated Header with Icon
                          _buildHeader(),

                          SizedBox(height: 32.h),

                          // Progress Indicator
                          _buildProgressIndicator(),

                          SizedBox(height: 24.h),

                          // Name Field
                          _buildTextField(
                            controller: _nameController,
                            label: 'Full Name',
                            hint: 'Enter your full name',
                            icon: Icons.person_outline,
                            textCapitalization: TextCapitalization.words,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Name is required';
                              }
                              if (value.length < 3) {
                                return 'Name must be at least 3 characters';
                              }
                              return null;
                            },
                          ),

                          SizedBox(height: 16.h),

                          // Email Field
                          _buildTextField(
                            controller: _emailController,
                            label: 'Email',
                            hint: 'Enter your email',
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Email is required';
                              }
                              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                  .hasMatch(value)) {
                                return 'Invalid email address';
                              }
                              return null;
                            },
                          ),

                          SizedBox(height: 16.h),

                          // Phone Field
                          _buildTextField(
                            controller: _phoneController,
                            label: 'Phone Number',
                            hint: 'Enter your phone number',
                            icon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(11),
                            ],
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Phone number is required';
                              }
                              if (value.length < 10) {
                                return 'Invalid phone number';
                              }
                              return null;
                            },
                          ),

                          SizedBox(height: 16.h),

                          // Password Field with Strength Indicator
                          _buildPasswordField(),

                          SizedBox(height: 16.h),

                          // Confirm Password Field
                          _buildTextField(
                            controller: _confirmPasswordController,
                            label: 'Confirm Password',
                            hint: 'Re-enter your password',
                            icon: Icons.lock_outline,
                            isPassword: true,
                            obscureText: _obscureConfirmPassword,
                            onToggleVisibility: () {
                              setState(() => _obscureConfirmPassword =
                                  !_obscureConfirmPassword);
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please confirm your password';
                              }
                              if (value != _passwordController.text) {
                                return 'Passwords do not match';
                              }
                              return null;
                            },
                          ),

                          SizedBox(height: 20.h),

                          // Terms & Conditions
                          _buildTermsCheckbox(),

                          SizedBox(height: 24.h),

                          // Sign Up Button
                          _buildSignUpButton(),

                          SizedBox(height: 16.h),

                          // Divider
                          _buildDivider(),

                          SizedBox(height: 16.h),

                          // Google Sign Up
                          _buildGoogleSignUpButton(),

                          SizedBox(height: 24.h),

                          // Already have account
                          _buildLoginLink(),

                          SizedBox(height: 32.h),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColorsDark.primary.withOpacity(0.1),
            AppColorsDark.secondary.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: AppColorsDark.primary.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              gradient: AppColorsDark.primaryGradient,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              Icons.person_add,
              color: AppColorsDark.white,
              size: 28.sp,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Create Account',
                  style: AppTextStyles.titleLarge().copyWith(
                    color: AppColorsDark.textPrimary,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Join us and start ordering delicious food',
                  style: AppTextStyles.bodySmall().copyWith(
                    color: AppColorsDark.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Account Setup',
          style: AppTextStyles.labelSmall().copyWith(
            color: AppColorsDark.textTertiary,
          ),
        ),
        SizedBox(height: 8.h),
        ClipRRect(
          borderRadius: BorderRadius.circular(10.r),
          child: LinearProgressIndicator(
            value: 0.5,
            minHeight: 6.h,
            backgroundColor: AppColorsDark.surfaceVariant,
            valueColor: AlwaysStoppedAnimation<Color>(AppColorsDark.primary),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onToggleVisibility,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    TextCapitalization? textCapitalization,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      textCapitalization: textCapitalization ?? TextCapitalization.none,
      style: AppTextStyles.bodyMedium().copyWith(
        color: AppColorsDark.textPrimary,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  obscureText
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                onPressed: onToggleVisibility,
              )
            : null,
      ),
      validator: validator,
    );
  }

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          style: AppTextStyles.bodyMedium().copyWith(
            color: AppColorsDark.textPrimary,
          ),
          decoration: InputDecoration(
            labelText: 'Password',
            hintText: 'Create a strong password',
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
          onChanged: _calculatePasswordStrength,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Password is required';
            }
            if (value.length < 8) {
              return 'Password must be at least 8 characters';
            }
            if (!RegExp(r'[A-Z]').hasMatch(value)) {
              return 'Password must contain uppercase letter';
            }
            if (!RegExp(r'[0-9]').hasMatch(value)) {
              return 'Password must contain a number';
            }
            return null;
          },
        ),
        if (_passwordController.text.isNotEmpty) ...[
          SizedBox(height: 8.h),
          // Password Strength Indicator
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10.r),
                  child: LinearProgressIndicator(
                    value: _passwordStrength,
                    minHeight: 4.h,
                    backgroundColor: AppColorsDark.surfaceVariant,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(_passwordStrengthColor),
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Text(
                _passwordStrengthText,
                style: AppTextStyles.labelSmall().copyWith(
                  color: _passwordStrengthColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildTermsCheckbox() {
    return InkWell(
      onTap: () => setState(() => _agreeToTerms = !_agreeToTerms),
      borderRadius: BorderRadius.circular(8.r),
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: AppColorsDark.surfaceVariant.withOpacity(0.5),
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: _agreeToTerms
                ? AppColorsDark.primary
                : AppColorsDark.border,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 24.w,
              height: 24.w,
              child: Checkbox(
                value: _agreeToTerms,
                onChanged: (value) {
                  setState(() => _agreeToTerms = value ?? false);
                },
                activeColor: AppColorsDark.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4.r),
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text.rich(
                TextSpan(
                  text: 'I agree to the ',
                  style: AppTextStyles.bodySmall().copyWith(
                    color: AppColorsDark.textSecondary,
                  ),
                  children: [
                    TextSpan(
                      text: 'Terms & Conditions',
                      style: AppTextStyles.bodySmall().copyWith(
                        color: AppColorsDark.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const TextSpan(text: ' and '),
                    TextSpan(
                      text: 'Privacy Policy',
                      style: AppTextStyles.bodySmall().copyWith(
                        color: AppColorsDark.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignUpButton() {
    return SizedBox(
      width: double.infinity,
      height: 56.h,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleSignup,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColorsDark.primary,
        ),
        child: _isLoading
            ? SizedBox(
                width: 24.w,
                height: 24.w,
                child: const CircularProgressIndicator(
                  color: AppColorsDark.background,
                  strokeWidth: 2,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.person_add),
                  SizedBox(width: 8.w),
                  const Text('Create Account'),
                ],
              ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
          child: Divider(color: AppColorsDark.border),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Text(
            'OR',
            style: AppTextStyles.labelSmall().copyWith(
              color: AppColorsDark.textTertiary,
            ),
          ),
        ),
        Expanded(
          child: Divider(color: AppColorsDark.border),
        ),
      ],
    );
  }

  Widget _buildGoogleSignUpButton() {
    return SizedBox(
      width: double.infinity,
      height: 56.h,
      child: OutlinedButton.icon(
        onPressed: _isLoading ? null : _handleGoogleSignup,
        icon: Icon(
          Icons.g_mobiledata,
          size: 32.sp,
          color: AppColorsDark.primary,
        ),
        label: const Text('Continue with Google'),
      ),
    );
  }

  Widget _buildLoginLink() {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Already have an account? ',
            style: AppTextStyles.bodyMedium().copyWith(
              color: AppColorsDark.textSecondary,
            ),
          ),
          TextButton(
            onPressed: () => context.go('/login'),
            child: Text(
              'Login',
              style: AppTextStyles.bodyMedium().copyWith(
                color: AppColorsDark.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}