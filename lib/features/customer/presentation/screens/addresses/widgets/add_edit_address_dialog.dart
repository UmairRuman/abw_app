// lib/features/customer/presentation/screens/addresses/widgets/add_edit_address_dialog.dart

import 'package:abw_app/core/utils/validators.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../../core/theme/colors/app_colors_dark.dart';
import '../../../../../../core/theme/text_styles/app_text_styles.dart';
import '../../../../../addresses/presentation/providers/addresses_provider.dart';
import '../../../../../addresses/data/models/address_model.dart';

class AddEditAddressDialog extends ConsumerStatefulWidget {
  final String userId;
  final AddressModel? address;

  const AddEditAddressDialog({super.key, required this.userId, this.address});

  @override
  ConsumerState<AddEditAddressDialog> createState() =>
      _AddEditAddressDialogState();
}

class _AddEditAddressDialogState extends ConsumerState<AddEditAddressDialog> {
  final _formKey = GlobalKey<FormState>();
  final _labelController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressLine1Controller = TextEditingController();
  final _addressLine2Controller = TextEditingController();
  final _areaController = TextEditingController();
  final _cityController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _landmarkController = TextEditingController();

  String _selectedType = 'home';
  bool _isDefault = false;
  bool _isLoading = false;

  final List<String> _addressTypes = ['home', 'work', 'other'];

  @override
  void initState() {
    super.initState();
    if (widget.address != null) {
      _populateFields(widget.address!);
    }
  }

  void _populateFields(AddressModel address) {
    _labelController.text = address.label;
    _nameController.text = address.name;
    _phoneController.text = address.phone;
    _addressLine1Controller.text = address.addressLine1;
    _addressLine2Controller.text = address.addressLine2 ?? '';
    _areaController.text = address.area;
    _cityController.text = address.city;
    _postalCodeController.text = address.postalCode ?? '';
    _landmarkController.text = address.landmark ?? '';
    _selectedType = address.addressType;
    _isDefault = address.isDefault;
  }

  @override
  void dispose() {
    _labelController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _areaController.dispose();
    _cityController.dispose();
    _postalCodeController.dispose();
    _landmarkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColorsDark.surface,
      insetPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
      child: Container(
        constraints: BoxConstraints(maxHeight: 700.h),
        child: Column(
          children: [
            // Header
            _buildHeader(),

            // Form
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(20.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Label & Type
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _labelController,
                              label: 'Label',
                              hint: 'e.g., Home, Office',
                              validator:
                                  (v) => v?.isEmpty ?? true ? 'Required' : null,
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(child: _buildTypeDropdown()),
                        ],
                      ),
                      SizedBox(height: 16.h),

                      // Name & Phone
                      _buildTextField(
                        controller: _nameController,
                        label: 'Full Name',
                        validator:
                            (v) => v?.isEmpty ?? true ? 'Required' : null,
                      ),
                      SizedBox(height: 16.h),
                      _buildTextField(
                        controller: _phoneController,
                        label: 'Phone Number',
                        hint: '03001234567',
                        keyboardType: TextInputType.phone,
                        validator:
                            Validators
                                .validatePakistaniPhone, // ✅ USE VALIDATOR
                      ),
                      SizedBox(height: 16.h),

                      // Address
                      _buildTextField(
                        controller: _addressLine1Controller,
                        label: 'Address Line 1',
                        hint: 'House/Flat No, Building',
                        validator:
                            (v) => v?.isEmpty ?? true ? 'Required' : null,
                      ),
                      SizedBox(height: 16.h),
                      _buildTextField(
                        controller: _addressLine2Controller,
                        label: 'Address Line 2 (Optional)',
                        hint: 'Street, Colony',
                      ),
                      SizedBox(height: 16.h),

                      // Area & City
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _areaController,
                              label: 'Area',
                              validator:
                                  (v) => v?.isEmpty ?? true ? 'Required' : null,
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: _buildTextField(
                              controller: _cityController,
                              label: 'City',
                              validator:
                                  (v) => v?.isEmpty ?? true ? 'Required' : null,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16.h),

                      // Postal Code & Landmark
                      _buildTextField(
                        controller: _postalCodeController,
                        label: 'Postal Code (Optional)',
                        keyboardType: TextInputType.number,
                      ),
                      SizedBox(height: 16.h),
                      _buildTextField(
                        controller: _landmarkController,
                        label: 'Landmark (Optional)',
                        hint: 'Nearby location',
                      ),
                      SizedBox(height: 16.h),

                      // Default checkbox
                      CheckboxListTile(
                        title: Text(
                          'Set as default address',
                          style: AppTextStyles.bodyMedium().copyWith(
                            color: AppColorsDark.textPrimary,
                          ),
                        ),
                        value: _isDefault,
                        onChanged: (value) {
                          setState(() => _isDefault = value ?? false);
                        },
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
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
          Icon(Icons.location_on, color: AppColorsDark.white, size: 24.sp),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              widget.address == null ? 'Add Address' : 'Edit Address',
              style: AppTextStyles.titleMedium().copyWith(
                color: AppColorsDark.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (!_isLoading)
            IconButton(
              icon: const Icon(Icons.close, color: AppColorsDark.white),
              onPressed: () => Navigator.pop(context),
            ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: AppTextStyles.bodyMedium().copyWith(
        color: AppColorsDark.textPrimary,
      ),
      decoration: InputDecoration(labelText: label, hintText: hint),
      validator: validator,
    );
  }

  Widget _buildTypeDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedType,
      decoration: const InputDecoration(labelText: 'Type'),
      items:
          _addressTypes.map((type) {
            return DropdownMenuItem(
              value: type,
              child: Text(type.toUpperCase()),
            );
          }).toList(),
      onChanged: (value) {
        setState(() => _selectedType = value ?? 'home');
      },
    );
  }

  Widget _buildActions() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColorsDark.border, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _isLoading ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleSubmit,
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
                      : Text(widget.address == null ? 'Add' : 'Update'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final address = AddressModel(
        id:
            widget.address?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        userId: widget.userId,
        label: _labelController.text.trim(),
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        addressLine1: _addressLine1Controller.text.trim(),
        addressLine2:
            _addressLine2Controller.text.trim().isEmpty
                ? null
                : _addressLine2Controller.text.trim(),
        area: _areaController.text.trim(),
        city: _cityController.text.trim(),
        state: 'Punjab', // TODO: Add state selector
        postalCode:
            _postalCodeController.text.trim().isEmpty
                ? '' // ✅ FIXED: Use empty string instead of null
                : _postalCodeController.text.trim(),
        country: 'Pakistan',
        latitude: 0.0, // TODO: Get from map
        longitude: 0.0,
        isDefault: _isDefault,
        addressType: _selectedType,
        landmark:
            _landmarkController.text.trim().isEmpty
                ? null
                : _landmarkController.text.trim(),
        createdAt: widget.address?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // ✅ FIXED: Remove userId parameter, just pass the address
      final success =
          widget.address == null
              ? await ref
                  .read(addressesProvider.notifier)
                  .addAddress(address) // ✅ Only pass address
              : await ref
                  .read(addressesProvider.notifier)
                  .updateAddress(address); // ✅ Only pass address

      if (success && mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.address == null
                  ? 'Address added successfully'
                  : 'Address updated successfully',
            ),
            backgroundColor: AppColorsDark.success,
          ),
        );
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
        setState(() => _isLoading = false);
      }
    }
  }
}
