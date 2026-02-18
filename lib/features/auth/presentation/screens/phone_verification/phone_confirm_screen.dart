// lib/features/auth/presentation/screens/phone_verification/phone_confirm_screen.dart
// CREATE NEW FILE:

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../../core/theme/colors/app_colors_dark.dart';
import '../../../../../core/theme/text_styles/app_text_styles.dart';

class PhoneConfirmScreen extends ConsumerStatefulWidget {
  final String userId;

  const PhoneConfirmScreen({super.key, required this.userId});

  @override
  ConsumerState<PhoneConfirmScreen> createState() => _PhoneConfirmScreenState();
}

class _PhoneConfirmScreenState extends ConsumerState<PhoneConfirmScreen> {
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isFetching = true;
  String? _existingPhone;

  @override
  void initState() {
    super.initState();
    _loadUserPhone();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  // ✅ LOAD EXISTING PHONE FROM FIRESTORE
  Future<void> _loadUserPhone() async {
    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(widget.userId)
              .get();

      if (doc.exists) {
        final phone = doc.data()?['phone'] as String?;
        setState(() {
          _existingPhone = phone;
          if (phone != null && phone.isNotEmpty) {
            _phoneController.text = _formatDisplayPhone(phone);
          }
          _isFetching = false;
        });
      } else {
        setState(() => _isFetching = false);
      }
    } catch (e) {
      setState(() => _isFetching = false);
    }
  }

  String _formatDisplayPhone(String phone) {
    if (phone.startsWith('+92')) return '0${phone.substring(3)}';
    if (phone.startsWith('92') && phone.length > 10)
      return '0${phone.substring(2)}';
    return phone;
  }

  String _formatPhoneForStorage(String phone) {
    String cleaned = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (!cleaned.startsWith('+')) {
      if (cleaned.startsWith('0')) {
        cleaned = '+92${cleaned.substring(1)}';
      } else if (cleaned.startsWith('92')) {
        cleaned = '+$cleaned';
      } else {
        cleaned = '+92$cleaned';
      }
    }
    return cleaned;
  }

  Future<void> _confirmPhone() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final phone = _phoneController.text.trim();
      final formattedPhone = _formatPhoneForStorage(phone);

      // ✅ SAVE PHONE + MARK AS VERIFIED (skipping OTP)
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .update({
            'phone': formattedPhone,
            'isPhoneVerified': true, // ✅ MARK VERIFIED WITHOUT OTP
            'updatedAt': FieldValue.serverTimestamp(),
          });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Phone number confirmed! ✅'),
            backgroundColor: AppColorsDark.success,
          ),
        );
        context.go('/customer/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColorsDark.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isFetching) {
      return Scaffold(
        backgroundColor: AppColorsDark.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColorsDark.primary),
        ),
      );
    }

    final hasPhone = _existingPhone != null && _existingPhone!.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColorsDark.background,
      appBar: AppBar(
        backgroundColor: AppColorsDark.surface,
        title: Text(
          hasPhone ? 'Confirm Phone Number' : 'Add Phone Number',
          style: AppTextStyles.titleLarge().copyWith(
            color: AppColorsDark.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 20.h),

                // Icon
                Center(
                  child: Container(
                    width: 100.w,
                    height: 100.w,
                    decoration: BoxDecoration(
                      gradient: AppColorsDark.primaryGradient,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      hasPhone ? Icons.phone_android : Icons.phone_outlined,
                      color: AppColorsDark.white,
                      size: 48.sp,
                    ),
                  ),
                ),

                SizedBox(height: 32.h),

                // Title
                Center(
                  child: Text(
                    hasPhone
                        ? 'Is this your phone number?'
                        : 'Enter Your Phone Number',
                    style: AppTextStyles.headlineMedium().copyWith(
                      color: AppColorsDark.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                SizedBox(height: 8.h),

                Center(
                  child: Text(
                    hasPhone
                        ? 'Confirm or update your number below'
                        : 'We need your number to deliver orders',
                    style: AppTextStyles.bodyMedium().copyWith(
                      color: AppColorsDark.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                SizedBox(height: 40.h),

                // Phone Label
                Text(
                  'Phone Number',
                  style: AppTextStyles.labelMedium().copyWith(
                    color: AppColorsDark.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 8.h),

                // Phone Input
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: AppTextStyles.bodyLarge().copyWith(
                    color: AppColorsDark.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: '03001234567',
                    prefixIcon: Container(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '🇵🇰 +92',
                            style: AppTextStyles.bodyLarge().copyWith(
                              color: AppColorsDark.textPrimary,
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Container(
                            width: 1,
                            height: 24.h,
                            color: AppColorsDark.border,
                          ),
                        ],
                      ),
                    ),
                    filled: true,
                    fillColor: AppColorsDark.surfaceVariant,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide(color: AppColorsDark.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide(color: AppColorsDark.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide(
                        color: AppColorsDark.primary,
                        width: 2,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide(color: AppColorsDark.error),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your phone number';
                    }
                    final cleaned = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');
                    if (cleaned.length < 10 || cleaned.length > 13) {
                      return 'Enter a valid Pakistani number';
                    }
                    return null;
                  },
                ),

                SizedBox(height: 12.h),

                // Info Box
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: AppColorsDark.info.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(
                      color: AppColorsDark.info.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 18.sp,
                        color: AppColorsDark.info,
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          'This number will be used for delivery updates',
                          style: AppTextStyles.bodySmall().copyWith(
                            color: AppColorsDark.info,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Confirm Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _confirmPhone,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                    ),
                    child:
                        _isLoading
                            ? SizedBox(
                              height: 20.h,
                              width: 20.w,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColorsDark.white,
                              ),
                            )
                            : Text(
                              hasPhone ? 'Confirm Number' : 'Save Number',
                              style: AppTextStyles.button(),
                            ),
                  ),
                ),

                SizedBox(height: 12.h),

                // Skip Button (only if phone exists)
                if (hasPhone)
                  Center(
                    child: TextButton(
                      onPressed: () => context.go('/customer/home'),
                      child: Text(
                        'Skip for now',
                        style: AppTextStyles.bodyMedium().copyWith(
                          color: AppColorsDark.textSecondary,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
