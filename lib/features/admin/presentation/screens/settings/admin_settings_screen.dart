// lib/features/admin/presentation/screens/settings/admin_settings_screen.dart
// Admin can edit helpline number here

import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../../core/theme/colors/app_colors_dark.dart';
import '../../../../../core/theme/text_styles/app_text_styles.dart';

class AdminSettingsScreen extends ConsumerStatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  ConsumerState<AdminSettingsScreen> createState() =>
      _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends ConsumerState<AdminSettingsScreen> {
  final _helplineController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    try {
      final settingsDoc =
          await FirebaseFirestore.instance
              .collection('settings')
              .doc('general')
              .get();

      if (settingsDoc.exists && mounted) {
        final data = settingsDoc.data();
        _helplineController.text = data?['helplineNumber'] as String? ?? '';
      }
    } catch (e) {
      log('Error loading settings: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _helplineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColorsDark.background,
      appBar: AppBar(
        backgroundColor: AppColorsDark.surface,
        title: Text(
          'Settings',
          style: AppTextStyles.titleLarge().copyWith(
            color: AppColorsDark.textPrimary,
          ),
        ),
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: AppColorsDark.primary),
              )
              : Form(
                key: _formKey,
                child: ListView(
                  padding: EdgeInsets.all(16.w),
                  children: [
                    // Helpline Number Section
                    Container(
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: AppColorsDark.cardBackground,
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(color: AppColorsDark.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.headset_mic,
                                color: AppColorsDark.primary,
                                size: 24.sp,
                              ),
                              SizedBox(width: 12.w),
                              Text(
                                'Customer Support',
                                style: AppTextStyles.titleMedium().copyWith(
                                  color: AppColorsDark.textPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16.h),
                          const Divider(color: AppColorsDark.border),
                          SizedBox(height: 16.h),
                          Text(
                            'Helpline Number',
                            style: AppTextStyles.labelMedium().copyWith(
                              color: AppColorsDark.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          TextFormField(
                            controller: _helplineController,
                            keyboardType: TextInputType.phone,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Helpline number is required';
                              }
                              if (!RegExp(
                                r'^[+]?[0-9]{10,15}$',
                              ).hasMatch(value.trim())) {
                                return 'Enter a valid phone number';
                              }
                              return null;
                            },
                            style: AppTextStyles.bodyLarge().copyWith(
                              color: AppColorsDark.textPrimary,
                            ),
                            decoration: InputDecoration(
                              prefixIcon: const Icon(
                                Icons.phone,
                                color: AppColorsDark.primary,
                              ),
                              hintText: 'e.g. +92 300 1234567',
                              filled: true,
                              fillColor: AppColorsDark.surfaceContainer,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.r),
                                borderSide: const BorderSide(
                                  color: AppColorsDark.border,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.r),
                                borderSide: const BorderSide(
                                  color: AppColorsDark.border,
                                ),
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
                                borderSide: const BorderSide(
                                  color: AppColorsDark.error,
                                ),
                              ),
                              helperText:
                                  'This number will be shown to customers for support',
                              helperStyle: AppTextStyles.bodySmall().copyWith(
                                color: AppColorsDark.textTertiary,
                              ),
                            ),
                          ),
                          SizedBox(height: 16.h),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isSaving ? null : _saveSettings,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColorsDark.primary,
                                padding: EdgeInsets.symmetric(vertical: 16.h),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                              ),
                              child:
                                  _isSaving
                                      ? SizedBox(
                                        height: 20.h,
                                        width: 20.w,
                                        child: const CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppColorsDark.white,
                                        ),
                                      )
                                      : Text(
                                        'Save Changes',
                                        style: AppTextStyles.button(),
                                      ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16.h),

                    // Info Card
                    Container(
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: AppColorsDark.info.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: AppColorsDark.info.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: AppColorsDark.info,
                            size: 20.sp,
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'About Helpline Number',
                                  style: AppTextStyles.labelMedium().copyWith(
                                    color: AppColorsDark.info,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(height: 4.h),
                                Text(
                                  'This number will be displayed to customers on their order details screen so they can contact support if needed.',
                                  style: AppTextStyles.bodySmall().copyWith(
                                    color: AppColorsDark.info,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
    );
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      final helplineNumber = _helplineController.text.trim();

      // Save to Firestore
      await FirebaseFirestore.instance
          .collection('settings')
          .doc('general')
          .set({
            'helplineNumber': helplineNumber,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12.w),
                const Text('Settings saved successfully'),
              ],
            ),
            backgroundColor: AppColorsDark.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 12.w),
                Expanded(child: Text('Error: ${e.toString()}')),
              ],
            ),
            backgroundColor: AppColorsDark.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}
