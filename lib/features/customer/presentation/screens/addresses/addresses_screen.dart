// lib/features/customer/presentation/screens/addresses/addresses_screen.dart

import 'package:abw_app/features/auth/presentation/providers/auth_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../core/theme/colors/app_colors_dark.dart';
import '../../../../../core/theme/text_styles/app_text_styles.dart';
import '../../../../addresses/presentation/providers/addresses_provider.dart';
import '../../../../addresses/data/models/address_model.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';
import 'widgets/add_edit_address_dialog.dart';

class AddressesScreen extends ConsumerStatefulWidget {
  const AddressesScreen({super.key});

  @override
  ConsumerState<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends ConsumerState<AddressesScreen> {
  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
     await Future.delayed(const Duration(milliseconds: 200)); // Ensure context is available
    final authState = ref.read(authProvider);
    if (authState is Authenticated) {
      await ref
          .read(addressesProvider.notifier)
          .loadUserAddresses(authState.user.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final addressesState = ref.watch(addressesProvider);
    final authState = ref.read(authProvider);

    if (authState is! Authenticated) {
      return const Scaffold(
        body: Center(child: Text('Please login to view addresses')),
      );
    }

    return Scaffold(
      backgroundColor: AppColorsDark.background,
      appBar: AppBar(
        backgroundColor: AppColorsDark.surface,
        title: Text(
          'My Addresses',
          style: AppTextStyles.titleLarge().copyWith(
            color: AppColorsDark.textPrimary,
          ),
        ),
      ),
      body: addressesState is AddressesLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColorsDark.primary))
          : addressesState is AddressesLoaded
              ? addressesState.addresses.isEmpty
                  ? _buildEmptyState(authState.user.id)
                  : _buildAddressesList(addressesState, authState.user.id)
              : addressesState is AddressesError
                  ? _buildErrorState(addressesState.error)
                  : _buildEmptyState(authState.user.id),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddAddressDialog(authState.user.id),
        backgroundColor: AppColorsDark.primary,
        icon: const Icon(Icons.add_location_alt),
        label: const Text('Add Address'),
      ),
    );
  }

  Widget _buildEmptyState(String userId) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.location_off,
            size: 120.sp,
            color: AppColorsDark.textTertiary,
          ),
          SizedBox(height: 24.h),
          Text(
            'No addresses saved',
            style: AppTextStyles.headlineMedium().copyWith(
              color: AppColorsDark.textPrimary,
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            'Add your delivery address',
            style: AppTextStyles.bodyMedium().copyWith(
              color: AppColorsDark.textSecondary,
            ),
          ),
          SizedBox(height: 32.h),
          ElevatedButton.icon(
            onPressed: () => _showAddAddressDialog(userId),
            icon: const Icon(Icons.add_location_alt),
            label: const Text('Add Address'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64.sp,
            color: AppColorsDark.error,
          ),
          SizedBox(height: 16.h),
          Text(
            'Error loading addresses',
            style: AppTextStyles.titleMedium().copyWith(
              color: AppColorsDark.textPrimary,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            error,
            style: AppTextStyles.bodySmall().copyWith(
              color: AppColorsDark.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAddressesList(AddressesLoaded state, String userId) {
    return RefreshIndicator(
      onRefresh: _loadAddresses,
      color: AppColorsDark.primary,
      backgroundColor: AppColorsDark.surface,
      child: ListView.builder(
        padding: EdgeInsets.all(16.w),
        itemCount: state.addresses.length,
        itemBuilder: (context, index) {
          final address = state.addresses[index];
          return _buildAddressCard(address, userId);
        },
      ),
    );
  }

  Widget _buildAddressCard(AddressModel address, String userId) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: AppColorsDark.cardBackground,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: address.isDefault
              ? AppColorsDark.primary
              : AppColorsDark.border,
          width: address.isDefault ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: address.isDefault
                  ? AppColorsDark.primary.withOpacity(0.1)
                  : null,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16.r),
                topRight: Radius.circular(16.r),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(
                    color: address.isDefault
                        ? AppColorsDark.primary.withOpacity(0.2)
                        : AppColorsDark.surfaceVariant,
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Icon(
                    _getAddressIcon(address.addressType),
                    color: address.isDefault
                        ? AppColorsDark.primary
                        : AppColorsDark.textSecondary,
                    size: 24.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            address.label,
                            style: AppTextStyles.titleSmall().copyWith(
                              color: AppColorsDark.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (address.isDefault) ...[
                            SizedBox(width: 8.w),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8.w,
                                vertical: 4.h,
                              ),
                              decoration: BoxDecoration(
                                color: AppColorsDark.primary,
                                borderRadius: BorderRadius.circular(6.r),
                              ),
                              child: Text(
                                'DEFAULT',
                                style: AppTextStyles.labelSmall().copyWith(
                                  color: AppColorsDark.white,
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        address.name,
                        style: AppTextStyles.bodyMedium().copyWith(
                          color: AppColorsDark.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.more_vert,
                    color: AppColorsDark.textSecondary,
                  ),
                  color: AppColorsDark.surface,
                  onSelected: (value) =>
                      _handleAddressAction(value, address, userId),
                  itemBuilder: (context) => [
                    if (!address.isDefault)
                      PopupMenuItem(
                        value: 'default',
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, size: 20.sp),
                            SizedBox(width: 8.w),
                            const Text('Set as Default'),
                          ],
                        ),
                      ),
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 20.sp),
                          SizedBox(width: 8.w),
                          const Text('Edit'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete,
                            size: 20.sp,
                            color: AppColorsDark.error,
                          ),
                          SizedBox(width: 8.w),
                          const Text(
                            'Delete',
                            style: TextStyle(color: AppColorsDark.error),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Address Details
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Full Address
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 20.sp,
                      color: AppColorsDark.textSecondary,
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        address.getFullAddress(),
                        style: AppTextStyles.bodyMedium().copyWith(
                          color: AppColorsDark.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 12.h),

                // Phone
                Row(
                  children: [
                    Icon(
                      Icons.phone,
                      size: 20.sp,
                      color: AppColorsDark.textSecondary,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      address.phone,
                      style: AppTextStyles.bodyMedium().copyWith(
                        color: AppColorsDark.textPrimary,
                      ),
                    ),
                  ],
                ),

                // Landmark (if available)
                if (address.landmark != null && address.landmark!.isNotEmpty) ...[
                  SizedBox(height: 12.h),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.location_searching,
                        size: 20.sp,
                        color: AppColorsDark.textSecondary,
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          'Landmark: ${address.landmark}',
                          style: AppTextStyles.bodySmall().copyWith(
                            color: AppColorsDark.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getAddressIcon(String type) {
    switch (type.toLowerCase()) {
      case 'home':
        return Icons.home;
      case 'work':
        return Icons.work;
      case 'other':
        return Icons.location_on;
      default:
        return Icons.location_on;
    }
  }

  void _handleAddressAction(
    String action,
    AddressModel address,
    String userId,
  ) async {
    switch (action) {
      case 'default':
        await ref
            .read(addressesProvider.notifier)
            .setDefaultAddress(userId, address.id);
        break;
      case 'edit':
        _showEditAddressDialog(userId, address);
        break;
      case 'delete':
        _showDeleteDialog(userId, address);
        break;
    }
  }

  void _showAddAddressDialog(String userId) {
    showDialog(
      context: context,
      builder: (context) => AddEditAddressDialog(userId: userId),
    );
  }

  void _showEditAddressDialog(String userId, AddressModel address) {
    showDialog(
      context: context,
      builder: (context) => AddEditAddressDialog(
        userId: userId,
        address: address,
      ),
    );
  }

  void _showDeleteDialog(String userId, AddressModel address) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColorsDark.surface,
        title: Text(
          'Delete Address',
          style: AppTextStyles.titleMedium().copyWith(
            color: AppColorsDark.error,
          ),
        ),
        content: Text(
          'Are you sure you want to delete "${address.label}"?',
          style: AppTextStyles.bodyMedium().copyWith(
            color: AppColorsDark.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await ref
                  .read(addressesProvider.notifier)
                  .deleteAddress(userId, address.id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColorsDark.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}