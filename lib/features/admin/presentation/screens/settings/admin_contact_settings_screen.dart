// lib/features/admin/presentation/screens/settings/admin_contact_settings_screen.dart

import 'dart:io';

import 'package:abw_app/core/presentation/providers/image_upload_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../../core/theme/colors/app_colors_dark.dart';
import '../../../../../core/theme/text_styles/app_text_styles.dart';
import '../../../../settings/data/models/contact_settings_model.dart';
import '../../../../settings/presentation/providers/contact_settings_provider.dart';

class AdminContactSettingsScreen extends ConsumerStatefulWidget {
  const AdminContactSettingsScreen({super.key});

  @override
  ConsumerState<AdminContactSettingsScreen> createState() =>
      _AdminContactSettingsScreenState();
}

class _AdminContactSettingsScreenState
    extends ConsumerState<AdminContactSettingsScreen> {
  final _whatsappController = TextEditingController();
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isSaving = false;
  bool _isUploadingBanner = false;
  String _currentBannerUrl = '';

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(contactSettingsProvider.notifier).load());
  }

  @override
  void dispose() {
    _whatsappController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _populateFields(ContactSettingsModel settings) {
    if (_whatsappController.text.isEmpty) {
      _whatsappController.text = settings.whatsappNumber;
    }
    if (_phoneController.text.isEmpty) {
      _phoneController.text = settings.phoneNumber;
    }
    if (_currentBannerUrl.isEmpty) {
      _currentBannerUrl = settings.bannerUrl;
    }
  }

  Future<void> _uploadBanner() async {
    // Pick image first using image_picker
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null) return;

    setState(() => _isUploadingBanner = true);
    try {
      final file = File(picked.path);
      final url = await ref
          .read(imageUploadProvider.notifier)
          .uploadContactBanner(file);

      if (url != null && url.isNotEmpty) {
        setState(() => _currentBannerUrl = url);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Upload failed. Please try again.'),
              backgroundColor: AppColorsDark.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: ${e.toString()}'),
            backgroundColor: AppColorsDark.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingBanner = false);
    }
  }

  Future<void> _removeBanner() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            backgroundColor: AppColorsDark.surface,
            title: Text(
              'Remove Banner',
              style: AppTextStyles.titleMedium().copyWith(
                color: AppColorsDark.textPrimary,
              ),
            ),
            content: Text(
              'Are you sure you want to remove the banner image?',
              style: AppTextStyles.bodyMedium().copyWith(
                color: AppColorsDark.textSecondary,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColorsDark.error,
                ),
                child: const Text('Remove'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      setState(() => _currentBannerUrl = '');
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final settings = ContactSettingsModel(
        bannerUrl: _currentBannerUrl,
        whatsappNumber: _whatsappController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
      );

      final success = await ref
          .read(contactSettingsProvider.notifier)
          .save(settings);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Contact settings saved successfully'
                  : 'Failed to save settings',
            ),
            backgroundColor:
                success ? AppColorsDark.success : AppColorsDark.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(contactSettingsProvider);

    if (state is ContactSettingsLoaded) {
      _populateFields(state.settings);
    }

    return Scaffold(
      backgroundColor: AppColorsDark.background,
      appBar: AppBar(
        backgroundColor: AppColorsDark.surface,
        title: Text(
          'Contact Us Settings',
          style: AppTextStyles.titleLarge().copyWith(
            color: AppColorsDark.textPrimary,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: AppColorsDark.textPrimary,
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body:
          state is ContactSettingsLoading
              ? const Center(
                child: CircularProgressIndicator(color: AppColorsDark.primary),
              )
              : SingleChildScrollView(
                padding: EdgeInsets.all(16.w),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Banner Section ───────────────────────────────────
                      _sectionHeader(Icons.image_outlined, 'Contact Banner'),
                      SizedBox(height: 12.h),

                      Container(
                        padding: EdgeInsets.all(16.w),
                        decoration: BoxDecoration(
                          color: AppColorsDark.cardBackground,
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(color: AppColorsDark.border),
                        ),
                        child: Column(
                          children: [
                            // Preview
                            if (_currentBannerUrl.isNotEmpty) ...[
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12.r),
                                child: Image.network(
                                  _currentBannerUrl,
                                  width: double.infinity,
                                  height: 160.h,
                                  fit: BoxFit.cover,
                                  errorBuilder:
                                      (_, __, ___) => _bannerPlaceholder(),
                                ),
                              ),
                              SizedBox(height: 12.h),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed:
                                          _isUploadingBanner
                                              ? null
                                              : _uploadBanner,
                                      icon: Icon(Icons.upload, size: 18.sp),
                                      label: const Text('Change'),
                                      style: OutlinedButton.styleFrom(
                                        side: const BorderSide(
                                          color: AppColorsDark.primary,
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 10.w),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: _removeBanner,
                                      icon: Icon(
                                        Icons.delete_outline,
                                        size: 18.sp,
                                      ),
                                      label: const Text('Remove'),
                                      style: OutlinedButton.styleFrom(
                                        side: const BorderSide(
                                          color: AppColorsDark.error,
                                        ),
                                        foregroundColor: AppColorsDark.error,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ] else ...[
                              _bannerPlaceholder(),
                              SizedBox(height: 12.h),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed:
                                      _isUploadingBanner ? null : _uploadBanner,
                                  icon:
                                      _isUploadingBanner
                                          ? SizedBox(
                                            width: 18.w,
                                            height: 18.w,
                                            child:
                                                const CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: AppColorsDark.white,
                                                ),
                                          )
                                          : Icon(Icons.upload, size: 18.sp),
                                  label: Text(
                                    _isUploadingBanner
                                        ? 'Uploading...'
                                        : 'Upload Banner Image',
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColorsDark.primary,
                                    padding: EdgeInsets.symmetric(
                                      vertical: 14.h,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      SizedBox(height: 24.h),

                      // ── Contact Numbers ──────────────────────────────────
                      _sectionHeader(Icons.phone_outlined, 'Contact Numbers'),
                      SizedBox(height: 12.h),

                      Container(
                        padding: EdgeInsets.all(16.w),
                        decoration: BoxDecoration(
                          color: AppColorsDark.cardBackground,
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(color: AppColorsDark.border),
                        ),
                        child: Column(
                          children: [
                            // WhatsApp
                            _buildField(
                              controller: _whatsappController,
                              label: 'WhatsApp Number',
                              hint: 'e.g. +923001234567',
                              icon: Icons.chat,
                              iconColor: const Color(0xFF25D366),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'WhatsApp number is required';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 16.h),

                            // Phone
                            _buildField(
                              controller: _phoneController,
                              label: 'Phone / PTCL Number',
                              hint: 'e.g. 04211234567',
                              icon: Icons.phone,
                              iconColor: AppColorsDark.primary,
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Phone number is required';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 32.h),

                      // ── Save Button ──────────────────────────────────────
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _save,
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
                                    height: 22.h,
                                    width: 22.w,
                                    child: const CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColorsDark.white,
                                    ),
                                  )
                                  : Text(
                                    'Save Settings',
                                    style: AppTextStyles.button().copyWith(
                                      fontSize: 16.sp,
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

  Widget _sectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: AppColorsDark.primary, size: 20.sp),
        SizedBox(width: 8.w),
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

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required Color iconColor,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.phone,
      validator: validator,
      style: AppTextStyles.bodyMedium().copyWith(
        color: AppColorsDark.textPrimary,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: iconColor, size: 20.sp),
        filled: true,
        fillColor: AppColorsDark.surfaceContainer,
        labelStyle: AppTextStyles.bodySmall().copyWith(
          color: AppColorsDark.textSecondary,
        ),
        hintStyle: AppTextStyles.bodySmall().copyWith(
          color: AppColorsDark.textTertiary,
        ),
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
          borderSide: const BorderSide(color: AppColorsDark.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: AppColorsDark.error),
        ),
      ),
    );
  }

  Widget _bannerPlaceholder() {
    return Container(
      width: double.infinity,
      height: 140.h,
      decoration: BoxDecoration(
        color: AppColorsDark.surfaceContainer,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: AppColorsDark.border,
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_outlined,
            size: 48.sp,
            color: AppColorsDark.textTertiary,
          ),
          SizedBox(height: 8.h),
          Text(
            'No banner uploaded',
            style: AppTextStyles.bodySmall().copyWith(
              color: AppColorsDark.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}
