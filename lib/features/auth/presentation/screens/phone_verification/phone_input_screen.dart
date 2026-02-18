// lib/features/auth/presentation/screens/phone_verification/phone_input_screen.dart
// CREATE THIS NEW FILE:

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../../core/theme/colors/app_colors_dark.dart';
import '../../../../../core/theme/text_styles/app_text_styles.dart';

class PhoneInputScreen extends ConsumerStatefulWidget {
  final String userId;
  final String? currentPhone; // Existing phone (if any)

  const PhoneInputScreen({super.key, required this.userId, this.currentPhone});

  @override
  ConsumerState<PhoneInputScreen> createState() => _PhoneInputScreenState();
}

class _PhoneInputScreenState extends ConsumerState<PhoneInputScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill if phone exists
    if (widget.currentPhone != null && widget.currentPhone!.isNotEmpty) {
      _phoneController.text = _formatDisplayPhone(widget.currentPhone!);
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  String _formatDisplayPhone(String phone) {
    // Remove country code for display
    if (phone.startsWith('+92')) {
      return '0${phone.substring(3)}';
    } else if (phone.startsWith('92')) {
      return '0${phone.substring(2)}';
    }
    return phone;
  }

  String _formatPhoneForStorage(String phone) {
    // Clean and format to E.164
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

  Future<void> _savePhoneNumber() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final phoneNumber = _phoneController.text.trim();
      final formattedPhone = _formatPhoneForStorage(phoneNumber);

      print('📱 Saving phone: $phoneNumber → $formattedPhone');

      // Update in Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .update({
            'phone': formattedPhone,
            'updatedAt': FieldValue.serverTimestamp(),
          });

      if (mounted) {
        // Navigate to verification
        context.pushReplacement('/verify-phone', extra: widget.userId);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
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
    final isEditing =
        widget.currentPhone != null && widget.currentPhone!.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColorsDark.background,
      appBar: AppBar(
        title: Text(
          isEditing ? 'Update Phone Number' : 'Add Phone Number',
          style: AppTextStyles.titleLarge().copyWith(
            color: AppColorsDark.textPrimary,
          ),
        ),
        backgroundColor: AppColorsDark.surface,
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
                    decoration: const BoxDecoration(
                      gradient: AppColorsDark.primaryGradient,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isEditing ? Icons.edit_outlined : Icons.phone_outlined,
                      color: AppColorsDark.white,
                      size: 50.sp,
                    ),
                  ),
                ),

                SizedBox(height: 32.h),

                // Title
                Center(
                  child: Text(
                    isEditing
                        ? 'Update Your Phone Number'
                        : 'Enter Your Phone Number',
                    style: AppTextStyles.headlineMedium().copyWith(
                      color: AppColorsDark.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                SizedBox(height: 12.h),

                // Subtitle
                Center(
                  child: Text(
                    isEditing
                        ? 'Update your phone number to receive verification code'
                        : 'We need your phone number to verify your account',
                    style: AppTextStyles.bodyMedium().copyWith(
                      color: AppColorsDark.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                SizedBox(height: 40.h),

                // Phone Input Field
                Text(
                  'Phone Number',
                  style: AppTextStyles.labelMedium().copyWith(
                    color: AppColorsDark.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 8.h),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: AppTextStyles.bodyLarge().copyWith(
                    color: AppColorsDark.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: '3001234567',
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
                      borderSide: const BorderSide(color: AppColorsDark.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: const BorderSide(color: AppColorsDark.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: const BorderSide(
                        color: AppColorsDark.primary,
                        width: 2,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: const BorderSide(color: AppColorsDark.error),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your phone number';
                    }

                    // Remove spaces and check length
                    final cleaned = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');

                    // Should be 10 digits (without country code)
                    // or 11 digits (with leading 0)
                    // or 12 digits (with 92)
                    // or 13 digits (with +92)
                    if (cleaned.length < 10 || cleaned.length > 13) {
                      return 'Please enter a valid Pakistani phone number';
                    }

                    // Check if starts with 3 (Pakistan mobile numbers)
                    if (cleaned.startsWith('0') &&
                        !cleaned.substring(1).startsWith('3')) {
                      return 'Mobile number should start with 03';
                    } else if (!cleaned.startsWith('0') &&
                        !cleaned.startsWith('3') &&
                        !cleaned.startsWith('92')) {
                      return 'Invalid phone number format';
                    }

                    return null;
                  },
                ),

                SizedBox(height: 12.h),

                // Help Text
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 18.sp,
                        color: AppColorsDark.info,
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          'Enter your 10-digit mobile number without the leading 0 (e.g., 3001234567)',
                          style: AppTextStyles.bodySmall().copyWith(
                            color: AppColorsDark.info,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Continue Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _savePhoneNumber,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                    ),
                    child:
                        _isLoading
                            ? SizedBox(
                              height: 20.h,
                              width: 20.w,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColorsDark.white,
                              ),
                            )
                            : Text('Continue', style: AppTextStyles.button()),
                  ),
                ),

                SizedBox(height: 16.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
