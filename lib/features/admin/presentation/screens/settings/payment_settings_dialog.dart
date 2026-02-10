// lib/features/admin/presentation/screens/settings/payment_settings_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../core/theme/colors/app_colors_dark.dart';
import '../../../../../core/theme/text_styles/app_text_styles.dart';
import '../../../../payment/data/models/payment_settings_model.dart';
import '../../../../payment/presentation/providers/payment_settings_provider.dart';

class PaymentSettingsDialog extends ConsumerStatefulWidget {
  const PaymentSettingsDialog({super.key});

  @override
  ConsumerState<PaymentSettingsDialog> createState() =>
      _PaymentSettingsDialogState();
}

class _PaymentSettingsDialogState extends ConsumerState<PaymentSettingsDialog> {
  final _formKey = GlobalKey<FormState>();
  final _jazzcashController = TextEditingController();
  final _easypaisaController = TextEditingController();
  final _bankTitleController = TextEditingController();
  final _bankNumberController = TextEditingController();
  final _bankNameController = TextEditingController();

  bool _isCodEnabled = true;
  bool _isJazzcashEnabled = true;
  bool _isEasypaisaEnabled = true;
  bool _isBankEnabled = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentSettings();
  }

  void _loadCurrentSettings() {
    final settingsState = ref.read(paymentSettingsProvider);
    if (settingsState is PaymentSettingsLoaded) {
      _populateFields(settingsState.settings);
    } else {
      // Load if not loaded
      ref.read(paymentSettingsProvider.notifier).loadSettings().then((_) {
        final state = ref.read(paymentSettingsProvider);
        if (state is PaymentSettingsLoaded && mounted) {
          _populateFields(state.settings);
        }
      });
    }
  }

  void _populateFields(PaymentSettingsModel settings) {
    setState(() {
      _jazzcashController.text = settings.jazzcashNumber;
      _easypaisaController.text = settings.easypaisaNumber;
      _bankTitleController.text = settings.bankAccountTitle;
      _bankNumberController.text = settings.bankAccountNumber;
      _bankNameController.text = settings.bankName;
      _isCodEnabled = settings.isCodEnabled;
      _isJazzcashEnabled = settings.isJazzcashEnabled;
      _isEasypaisaEnabled = settings.isEasypaisaEnabled;
      _isBankEnabled = settings.isBankTransferEnabled;
    });
  }

  @override
  void dispose() {
    _jazzcashController.dispose();
    _easypaisaController.dispose();
    _bankTitleController.dispose();
    _bankNumberController.dispose();
    _bankNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColorsDark.surface,
      insetPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(maxHeight: 700.h),
        child: Column(
          children: [
            // Header
            _buildHeader(),

            // Form Content
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(20.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // COD Section
                      _buildMethodSection(
                        title: 'Cash on Delivery',
                        icon: Icons.money,
                        color: AppColorsDark.success,
                        isEnabled: _isCodEnabled,
                        onToggle:
                            (value) => setState(() => _isCodEnabled = value),
                        children: [
                          _buildInfoNote(
                            'No configuration needed. Customer pays cash upon delivery.',
                          ),
                        ],
                      ),

                      SizedBox(height: 20.h),

                      // JazzCash Section
                      _buildMethodSection(
                        title: 'JazzCash',
                        icon: Icons.account_balance_wallet,
                        color: const Color(0xFFFF6B00),
                        isEnabled: _isJazzcashEnabled,
                        onToggle:
                            (value) =>
                                setState(() => _isJazzcashEnabled = value),
                        children: [
                          _buildTextField(
                            controller: _jazzcashController,
                            label: 'JazzCash Number',
                            hint: 'e.g., 03001234567',
                            icon: Icons.phone,
                            enabled: _isJazzcashEnabled,
                            validator:
                                _isJazzcashEnabled
                                    ? (v) =>
                                        v?.isEmpty ?? true ? 'Required' : null
                                    : null,
                          ),
                        ],
                      ),

                      SizedBox(height: 20.h),

                      // EasyPaisa Section
                      _buildMethodSection(
                        title: 'EasyPaisa',
                        icon: Icons.payment,
                        color: const Color(0xFF00A651),
                        isEnabled: _isEasypaisaEnabled,
                        onToggle:
                            (value) =>
                                setState(() => _isEasypaisaEnabled = value),
                        children: [
                          _buildTextField(
                            controller: _easypaisaController,
                            label: 'EasyPaisa Number',
                            hint: 'e.g., 03001234567',
                            icon: Icons.phone,
                            enabled: _isEasypaisaEnabled,
                            validator:
                                _isEasypaisaEnabled
                                    ? (v) =>
                                        v?.isEmpty ?? true ? 'Required' : null
                                    : null,
                          ),
                        ],
                      ),

                      SizedBox(height: 20.h),

                      // Bank Transfer Section
                      _buildMethodSection(
                        title: 'Bank Transfer',
                        icon: Icons.account_balance,
                        color: AppColorsDark.info,
                        isEnabled: _isBankEnabled,
                        onToggle:
                            (value) => setState(() => _isBankEnabled = value),
                        children: [
                          _buildTextField(
                            controller: _bankTitleController,
                            label: 'Account Title',
                            hint: 'e.g., ABW Services',
                            icon: Icons.person,
                            enabled: _isBankEnabled,
                            validator:
                                _isBankEnabled
                                    ? (v) =>
                                        v?.isEmpty ?? true ? 'Required' : null
                                    : null,
                          ),
                          SizedBox(height: 12.h),
                          _buildTextField(
                            controller: _bankNumberController,
                            label: 'Account Number / IBAN',
                            hint: 'e.g., PK36SCBL0000001123456702',
                            icon: Icons.numbers,
                            enabled: _isBankEnabled,
                            validator:
                                _isBankEnabled
                                    ? (v) =>
                                        v?.isEmpty ?? true ? 'Required' : null
                                    : null,
                          ),
                          SizedBox(height: 12.h),
                          _buildTextField(
                            controller: _bankNameController,
                            label: 'Bank Name',
                            hint: 'e.g., HBL / Meezan Bank',
                            icon: Icons.account_balance,
                            enabled: _isBankEnabled,
                            validator:
                                _isBankEnabled
                                    ? (v) =>
                                        v?.isEmpty ?? true ? 'Required' : null
                                    : null,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Actions
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: AppColorsDark.primaryGradient,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.r),
          topRight: Radius.circular(20.r),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.payment, color: AppColorsDark.white, size: 24.sp),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Payment Settings',
                  style: AppTextStyles.titleMedium().copyWith(
                    color: AppColorsDark.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Manage payment methods & numbers',
                  style: AppTextStyles.bodySmall().copyWith(
                    color: AppColorsDark.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: AppColorsDark.white),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildMethodSection({
    required String title,
    required IconData icon,
    required Color color,
    required bool isEnabled,
    required ValueChanged<bool> onToggle,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColorsDark.cardBackground,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isEnabled ? color.withOpacity(0.3) : AppColorsDark.border,
          width: isEnabled ? 1.5 : 1,
        ),
      ),
      child: Column(
        children: [
          // Section Header with Toggle
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(
                    color:
                        isEnabled
                            ? color.withOpacity(0.15)
                            : AppColorsDark.surfaceVariant,
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Icon(
                    icon,
                    color: isEnabled ? color : AppColorsDark.textTertiary,
                    size: 20.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    title,
                    style: AppTextStyles.titleSmall().copyWith(
                      color:
                          isEnabled
                              ? AppColorsDark.textPrimary
                              : AppColorsDark.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Switch(
                  value: isEnabled,
                  onChanged: onToggle,
                  activeColor: color,
                ),
              ],
            ),
          ),

          // Section Content
          if (isEnabled) ...[
            const Divider(color: AppColorsDark.border, height: 1),
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(children: children),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool enabled = true,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      style: AppTextStyles.bodyMedium().copyWith(
        color: AppColorsDark.textPrimary,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 20.sp),
      ),
      validator: validator,
    );
  }

  Widget _buildInfoNote(String text) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColorsDark.success.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: AppColorsDark.success.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: AppColorsDark.success, size: 16.sp),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodySmall().copyWith(
                color: AppColorsDark.success,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColorsDark.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _isSaving ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveSettings,
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
                      : const Text('Save Settings'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final currentState = ref.read(paymentSettingsProvider);
      final existingSettings =
          currentState is PaymentSettingsLoaded
              ? currentState.settings
              : PaymentSettingsModel.defaultSettings();

      final updatedSettings = existingSettings.copyWith(
        jazzcashNumber: _jazzcashController.text.trim(),
        easypaisaNumber: _easypaisaController.text.trim(),
        bankAccountTitle: _bankTitleController.text.trim(),
        bankAccountNumber: _bankNumberController.text.trim(),
        bankName: _bankNameController.text.trim(),
        isCodEnabled: _isCodEnabled,
        isJazzcashEnabled: _isJazzcashEnabled,
        isEasypaisaEnabled: _isEasypaisaEnabled,
        isBankTransferEnabled: _isBankEnabled,
        updatedAt: DateTime.now(),
        updatedBy: 'admin',
      );

      final success = await ref
          .read(paymentSettingsProvider.notifier)
          .updateSettings(updatedSettings);

      if (success && mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment settings updated successfully'),
            backgroundColor: AppColorsDark.success,
          ),
        );
      } else {
        throw Exception('Failed to save settings');
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
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}
