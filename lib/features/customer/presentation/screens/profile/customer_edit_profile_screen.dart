// lib/features/customer/presentation/screens/profile/customer_edit_profile_screen.dart
// FIX: Properly load and display phone number from Firestore

import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // ✅ ADD THIS
import '../../../../../core/theme/colors/app_colors_dark.dart';
import '../../../../../core/theme/text_styles/app_text_styles.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';
import '../../../../auth/presentation/providers/auth_state.dart';

class CustomerEditProfileScreen extends ConsumerStatefulWidget {
  const CustomerEditProfileScreen({super.key});

  @override
  ConsumerState<CustomerEditProfileScreen> createState() =>
      _CustomerEditProfileScreenState();
}

class _CustomerEditProfileScreenState
    extends ConsumerState<CustomerEditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isLoading = false;
  bool _isLoadingData = true; // ✅ NEW: Track data loading
  bool _hasChanges = false;
  File? _selectedImage;
  String? _currentImageUrl;
  String _originalPhone = '';

  @override
  void initState() {
    super.initState();
    _loadUserDataFromFirestore(); // ✅ CHANGED: Load from Firestore
  }

  // ✅ NEW: Load data directly from Firestore to ensure we have phone
  Future<void> _loadUserDataFromFirestore() async {
    final authState = ref.read(authProvider);
    if (authState is! Authenticated) {
      setState(() => _isLoadingData = false);
      return;
    }

    final userId = authState.user.id;

    try {
      // ✅ Fetch fresh data from Firestore
      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .get();

      if (userDoc.exists && mounted) {
        final userData = userDoc.data()!;

        // ✅ Load data into controllers
        _nameController.text = userData['name'] as String? ?? '';
        _emailController.text = userData['email'] as String? ?? '';
        _phoneController.text =
            userData['phone'] as String? ?? ''; // ✅ CRITICAL
        _originalPhone = userData['phone'] as String? ?? '';
        _currentImageUrl = userData['profileImage'] as String?;

        // Add listeners for change detection
        _nameController.addListener(_onFieldChanged);
        _phoneController.addListener(_onFieldChanged);

        setState(() => _isLoadingData = false);

        // Debug logs
        log('✅ Profile data loaded');
        log('   Name: ${_nameController.text}');
        log('   Email: ${_emailController.text}');
        log('   Phone: ${_phoneController.text}'); // ✅ Should show phone
      } else {
        throw Exception('User document not found');
      }
    } catch (e) {
      log('❌ Error loading profile data: $e');
      if (mounted) {
        setState(() => _isLoadingData = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading profile: $e'),
            backgroundColor: AppColorsDark.error,
          ),
        );
      }
    }
  }

  void _onFieldChanged() {
    if (!_hasChanges) {
      setState(() => _hasChanges = true);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    if (authState is! Authenticated) {
      return const Scaffold(body: Center(child: Text('Please login')));
    }

    return Scaffold(
      backgroundColor: AppColorsDark.background,
      appBar: AppBar(
        backgroundColor: AppColorsDark.surface,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _handleBack(context),
        ),
        title: Text(
          'Edit Profile',
          style: AppTextStyles.titleLarge().copyWith(
            color: AppColorsDark.textPrimary,
          ),
        ),
      ),
      body:
          _isLoadingData // ✅ Show loading while fetching data
              ? const Center(
                child: CircularProgressIndicator(color: AppColorsDark.primary),
              )
              : Form(
                key: _formKey,
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.all(16.w),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Profile Image Picker
                            Center(
                              child: _buildProfileImagePicker(
                                authState.user.name,
                              ),
                            ),
                            SizedBox(height: 32.h),

                            // Name field
                            _buildTextField(
                              controller: _nameController,
                              label: 'Full Name',
                              icon: Icons.person_outline,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Name is required';
                                }
                                if (value.trim().length < 3) {
                                  return 'Name must be at least 3 characters';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 16.h),

                            // Email field (locked)
                            _buildTextField(
                              controller: _emailController,
                              label: 'Email',
                              icon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              enabled: false,
                              suffixIcon: Icon(
                                Icons.lock_outline,
                                size: 18.sp,
                                color: AppColorsDark.textTertiary,
                              ),
                              helperText: 'Email cannot be changed',
                            ),
                            SizedBox(height: 16.h),

                            // ✅ Phone field (now properly pre-filled!)
                            _buildTextField(
                              controller: _phoneController,
                              label: 'Phone Number',
                              icon: Icons.phone_outlined,
                              keyboardType: TextInputType.phone,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Phone number is required';
                                }
                                if (!RegExp(
                                  r'^[+]?[0-9]{10,15}$',
                                ).hasMatch(value.trim())) {
                                  return 'Enter a valid phone number';
                                }
                                return null;
                              },
                              helperText:
                                  'Changing phone requires re-verification',
                            ),
                            SizedBox(height: 24.h),

                            // Phone change warning
                            if (_phoneController.text != _originalPhone &&
                                _phoneController.text.isNotEmpty)
                              _buildPhoneChangeWarning(),

                            SizedBox(height: 16.h),

                            // Info card
                            _buildInfoCard(),
                          ],
                        ),
                      ),
                    ),

                    // Save button
                    _buildSaveButton(),
                  ],
                ),
              ),
    );
  }

  // ... rest of the methods (same as before: _buildProfileImagePicker, _pickImage, etc.)
  // [Include all the other methods from the previous version]
  // For brevity, I'm not repeating them, but they should all be included

  Widget _buildProfileImagePicker(String name) {
    return GestureDetector(
      onTap: _pickImage,
      child: Stack(
        children: [
          Container(
            width: 100.w,
            height: 100.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient:
                  _selectedImage == null && _currentImageUrl == null
                      ? AppColorsDark.primaryGradient
                      : null,
              image:
                  _selectedImage != null
                      ? DecorationImage(
                        image: FileImage(_selectedImage!),
                        fit: BoxFit.cover,
                      )
                      : _currentImageUrl != null
                      ? DecorationImage(
                        image: NetworkImage(_currentImageUrl!),
                        fit: BoxFit.cover,
                      )
                      : null,
            ),
            child:
                _selectedImage == null && _currentImageUrl == null
                    ? Center(
                      child: Text(
                        name.isNotEmpty
                            ? name.substring(0, 2).toUpperCase()
                            : 'U',
                        style: AppTextStyles.headlineLarge().copyWith(
                          color: AppColorsDark.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                    : null,
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: AppColorsDark.primary,
                shape: BoxShape.circle,
                border: Border.all(color: AppColorsDark.background, width: 3),
              ),
              child: Icon(
                Icons.camera_alt,
                size: 16.sp,
                color: AppColorsDark.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final source = await showModalBottomSheet<ImageSource>(
        context: context,
        backgroundColor: AppColorsDark.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        builder:
            (context) => SafeArea(
              child: Wrap(
                children: [
                  ListTile(
                    leading: const Icon(
                      Icons.photo_camera,
                      color: AppColorsDark.primary,
                    ),
                    title: const Text('Camera'),
                    onTap: () => Navigator.pop(context, ImageSource.camera),
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.photo_library,
                      color: AppColorsDark.primary,
                    ),
                    title: const Text('Gallery'),
                    onTap: () => Navigator.pop(context, ImageSource.gallery),
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.cancel,
                      color: AppColorsDark.error,
                    ),
                    title: const Text('Cancel'),
                    onTap: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
      );

      if (source != null) {
        final XFile? image = await picker.pickImage(
          source: source,
          maxWidth: 512,
          maxHeight: 512,
          imageQuality: 85,
        );

        if (image != null) {
          setState(() {
            _selectedImage = File(image.path);
            _hasChanges = true;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e'),
            backgroundColor: AppColorsDark.error,
          ),
        );
      }
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    bool enabled = true,
    Widget? suffixIcon,
    String? helperText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.labelMedium().copyWith(
            color: AppColorsDark.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 8.h),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          enabled: enabled,
          style: AppTextStyles.bodyLarge().copyWith(
            color:
                enabled
                    ? AppColorsDark.textPrimary
                    : AppColorsDark.textTertiary,
          ),
          decoration: InputDecoration(
            prefixIcon: Icon(
              icon,
              color:
                  enabled ? AppColorsDark.primary : AppColorsDark.textTertiary,
            ),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor:
                enabled
                    ? AppColorsDark.surfaceContainer
                    : AppColorsDark.surfaceContainer.withOpacity(0.5),
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
            helperText: helperText,
            helperStyle: AppTextStyles.bodySmall().copyWith(
              color: AppColorsDark.textTertiary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneChangeWarning() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColorsDark.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColorsDark.warning.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: AppColorsDark.warning,
            size: 20.sp,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Phone Number Changed',
                  style: AppTextStyles.labelMedium().copyWith(
                    color: AppColorsDark.warning,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'You will need to verify your new phone number before you can place orders.',
                  style: AppTextStyles.bodySmall().copyWith(
                    color: AppColorsDark.warning,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColorsDark.info.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColorsDark.info.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: AppColorsDark.info, size: 20.sp),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'About Profile Changes',
                  style: AppTextStyles.labelMedium().copyWith(
                    color: AppColorsDark.info,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Your email cannot be changed. Phone number changes require verification via SMS.',
                  style: AppTextStyles.bodySmall().copyWith(
                    color: AppColorsDark.info,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: const BoxDecoration(
        color: AppColorsDark.surface,
        boxShadow: [
          BoxShadow(
            color: AppColorsDark.shadow,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: ElevatedButton(
          onPressed: _isLoading || !_hasChanges ? null : _handleSave,
          style: ElevatedButton.styleFrom(
            minimumSize: Size(double.infinity, 56.h),
            backgroundColor: AppColorsDark.primary,
            disabledBackgroundColor: AppColorsDark.surfaceContainer,
          ),
          child:
              _isLoading
                  ? SizedBox(
                    height: 24.h,
                    width: 24.w,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColorsDark.white,
                    ),
                  )
                  : Text(
                    'Save Changes',
                    style: AppTextStyles.button().copyWith(
                      fontSize: 16.sp,
                      color:
                          _hasChanges
                              ? AppColorsDark.white
                              : AppColorsDark.textTertiary,
                    ),
                  ),
        ),
      ),
    );
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final name = _nameController.text.trim();
      final phone = _phoneController.text.trim();
      final phoneChanged = phone != _originalPhone;

      final success = await ref
          .read(authProvider.notifier)
          .updateProfile(
            name: name,
            phone: phone,
            profileImage: _selectedImage,
          );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12.w),
                const Text('Profile updated successfully'),
              ],
            ),
            backgroundColor: AppColorsDark.success,
            behavior: SnackBarBehavior.floating,
          ),
        );

        if (phoneChanged) {
          context.go('/phone-verification');
        } else {
          context.pop();
        }
      } else {
        throw Exception('Failed to update profile');
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
        setState(() => _isLoading = false);
      }
    }
  }

  void _handleBack(BuildContext context) {
    if (_hasChanges) {
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              backgroundColor: AppColorsDark.surface,
              title: Text(
                'Discard Changes?',
                style: AppTextStyles.titleMedium().copyWith(
                  color: AppColorsDark.textPrimary,
                ),
              ),
              content: Text(
                'You have unsaved changes. Are you sure you want to go back?',
                style: AppTextStyles.bodyMedium().copyWith(
                  color: AppColorsDark.textSecondary,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: AppColorsDark.textSecondary),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    context.pop();
                  },
                  child: const Text(
                    'Discard',
                    style: TextStyle(color: AppColorsDark.error),
                  ),
                ),
              ],
            ),
      );
    } else {
      context.pop();
    }
  }
}
