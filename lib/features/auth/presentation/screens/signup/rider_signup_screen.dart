//  lib/features/auth/presentation/screens/signup/rider_signup_screen.dart

import 'package:abw_app/core/utils/validators.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/theme/colors/app_colors_dark.dart';
import '../../../../../core/theme/text_styles/app_text_styles.dart';
import '../../providers/auth_provider.dart';
import '../../providers/auth_state.dart';

class RiderSignupScreen extends ConsumerStatefulWidget {
  const RiderSignupScreen({super.key});

  @override
  ConsumerState<RiderSignupScreen> createState() => _RiderSignupScreenState();
}

class _RiderSignupScreenState extends ConsumerState<RiderSignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _vehicleNumberController = TextEditingController();
  final _licenseController = TextEditingController();

  String _selectedVehicleType = 'Bike';
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  bool _agreeToTerms = false;

  final List<String> _vehicleTypes = ['Bike', 'Scooter', 'Car', 'Bicycle'];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _vehicleNumberController.dispose();
    _licenseController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 12.w),
              const Expanded(child: Text('Please agree to Terms & Conditions')),
            ],
          ),
          backgroundColor: AppColorsDark.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    await ref
        .read(authProvider.notifier)
        .signUpRider(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          vehicleType: _selectedVehicleType,
          vehicleNumber: _vehicleNumberController.text.trim(),
          licenseNumber:
              _licenseController.text.trim().isEmpty
                  ? null
                  : _licenseController.text.trim(),
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
    } else if (authState is RiderPendingApproval) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.white),
                SizedBox(width: 12.w),
                const Expanded(
                  child: Text('Request submitted! Awaiting admin approval.'),
                ),
              ],
            ),
            backgroundColor: AppColorsDark.success,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          context.go('/rider/pending');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColorsDark.background,
      appBar: AppBar(
        backgroundColor: AppColorsDark.surface,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: AppColorsDark.surfaceVariant,
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(
              Icons.arrow_back,
              color: AppColorsDark.textPrimary,
              size: 20.sp,
            ),
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Rider Registration',
          style: AppTextStyles.titleLarge().copyWith(
            color: AppColorsDark.textPrimary,
          ),
        ),
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

                // Info Banner
                Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColorsDark.accent.withOpacity(0.2),
                        AppColorsDark.accent.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(
                      color: AppColorsDark.accent.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8.w),
                        decoration: BoxDecoration(
                          color: AppColorsDark.accent,
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Icon(
                          Icons.info_outline,
                          color: AppColorsDark.white,
                          size: 20.sp,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Text(
                          'Your account will be pending admin approval',
                          style: AppTextStyles.bodyMedium().copyWith(
                            color: AppColorsDark.accent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 32.h),

                // Personal Information Section
                _buildSectionHeader('Personal Information', Icons.person),
                SizedBox(height: 16.h),

                _buildTextField(
                  controller: _nameController,
                  label: 'Full Name',
                  hint: 'Enter your full name',
                  icon: Icons.person_outline,
                  textCapitalization: TextCapitalization.words,
                  validator:
                      (value) =>
                          value?.isEmpty ?? true ? 'Name is required' : null,
                ),

                SizedBox(height: 16.h),

                _buildTextField(
                  controller: _emailController,
                  label: 'Email',
                  hint: 'Enter your email',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Email is required';
                    if (!value!.contains('@')) return 'Invalid email';
                    return null;
                  },
                ),

                SizedBox(height: 16.h),

                _buildTextField(
                  controller: _phoneController,
                  label: 'Phone Number',
                  hint: 'Enter your phone number',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  validator: Validators.validatePakistaniPhone,
                ),

                SizedBox(height: 32.h),

                // Vehicle Information Section
                _buildSectionHeader(
                  'Vehicle Information',
                  Icons.delivery_dining,
                ),
                SizedBox(height: 16.h),

                // Vehicle Type Dropdown
                DropdownButtonFormField<String>(
                  value: _selectedVehicleType,
                  dropdownColor: AppColorsDark.surface,
                  style: AppTextStyles.bodyMedium().copyWith(
                    color: AppColorsDark.textPrimary,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Vehicle Type',
                    prefixIcon: Icon(
                      Icons.two_wheeler,
                      color: AppColorsDark.accent,
                    ),
                  ),
                  items:
                      _vehicleTypes.map((type) {
                        return DropdownMenuItem(value: type, child: Text(type));
                      }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedVehicleType = value!);
                  },
                ),

                SizedBox(height: 16.h),

                _buildTextField(
                  controller: _vehicleNumberController,
                  label: 'Vehicle Number',
                  hint: 'e.g., ABC-1234',
                  icon: Icons.confirmation_number_outlined,
                  textCapitalization: TextCapitalization.characters,
                  validator:
                      (value) =>
                          value?.isEmpty ?? true
                              ? 'Vehicle number required'
                              : null,
                ),

                SizedBox(height: 16.h),

                _buildTextField(
                  controller: _licenseController,
                  label: 'License Number (Optional)',
                  hint: 'Enter license number',
                  icon: Icons.badge_outlined,
                ),

                SizedBox(height: 32.h),

                // Security Section
                _buildSectionHeader('Security', Icons.lock),
                SizedBox(height: 16.h),

                _buildTextField(
                  controller: _passwordController,
                  label: 'Password',
                  hint: 'Create a strong password',
                  icon: Icons.lock_outline,
                  isPassword: true,
                  obscureText: _obscurePassword,
                  onToggleVisibility: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Password required';
                    if (value!.length < 8) {
                      return 'Password must be at least 8 characters';
                    }
                    return null;
                  },
                ),

                SizedBox(height: 16.h),

                _buildTextField(
                  controller: _confirmPasswordController,
                  label: 'Confirm Password',
                  hint: 'Re-enter your password',
                  icon: Icons.lock_outline,
                  isPassword: true,
                  obscureText: _obscureConfirmPassword,
                  onToggleVisibility: () {
                    setState(
                      () => _obscureConfirmPassword = !_obscureConfirmPassword,
                    );
                  },
                  validator: (value) {
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),

                SizedBox(height: 24.h),

                // Terms Checkbox
                _buildTermsCheckbox(),

                SizedBox(height: 32.h),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 56.h,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleSignup,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColorsDark.accent,
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
                                const Icon(Icons.delivery_dining),
                                SizedBox(width: 8.w),
                                const Text('Register as Rider'),
                              ],
                            ),
                  ),
                ),

                SizedBox(height: 24.h),

                // Login Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already registered? ',
                      style: AppTextStyles.bodyMedium().copyWith(
                        color: AppColorsDark.textSecondary,
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.pop(),
                      child: Text(
                        'Login',
                        style: AppTextStyles.bodyMedium().copyWith(
                          color: AppColorsDark.accent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 32.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: AppColorsDark.accent.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(icon, color: AppColorsDark.accent, size: 20.sp),
        ),
        SizedBox(width: 12.w),
        Text(
          title,
          style: AppTextStyles.titleMedium().copyWith(
            color: AppColorsDark.textPrimary,
            fontWeight: FontWeight.bold,
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
        prefixIcon: Icon(icon, color: AppColorsDark.accent),
        suffixIcon:
            isPassword
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

  Widget _buildTermsCheckbox() {
    return InkWell(
      onTap: () => setState(() => _agreeToTerms = !_agreeToTerms),
      borderRadius: BorderRadius.circular(8.r),
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: AppColorsDark.surfaceVariant.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: _agreeToTerms ? AppColorsDark.accent : AppColorsDark.border,
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
                activeColor: AppColorsDark.accent,
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
                        color: AppColorsDark.accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const TextSpan(text: ' and '),
                    TextSpan(
                      text: 'Privacy Policy',
                      style: AppTextStyles.bodySmall().copyWith(
                        color: AppColorsDark.accent,
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
}
