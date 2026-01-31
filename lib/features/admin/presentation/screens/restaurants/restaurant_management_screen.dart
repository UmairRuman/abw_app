// lib/features/admin/presentation/screens/restaurants/restaurant_management_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../core/theme/colors/app_colors_dark.dart';
import '../../../../../core/theme/text_styles/app_text_styles.dart';

class RestaurantManagementScreen extends ConsumerStatefulWidget {
  const RestaurantManagementScreen({super.key});

  @override
  ConsumerState<RestaurantManagementScreen> createState() =>
      _RestaurantManagementScreenState();
}

class _RestaurantManagementScreenState
    extends ConsumerState<RestaurantManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _filterCategory = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColorsDark.background,
      appBar: AppBar(
        backgroundColor: AppColorsDark.surface,
        title: Text(
          'Restaurant Management',
          style: AppTextStyles.titleLarge().copyWith(
            color: AppColorsDark.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            color: AppColorsDark.textPrimary,
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildFilters(),
          Expanded(child: _buildRestaurantList()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddRestaurantDialog(),
        backgroundColor: AppColorsDark.primary,
        icon: const Icon(Icons.add),
        label: const Text('Add Restaurant'),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: TextField(
        controller: _searchController,
        style: AppTextStyles.bodyMedium().copyWith(
          color: AppColorsDark.textPrimary,
        ),
        decoration: InputDecoration(
          hintText: 'Search restaurants...',
          hintStyle: AppTextStyles.bodyMedium().copyWith(
            color: AppColorsDark.textTertiary,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: AppColorsDark.textSecondary,
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
        ),
      ),
    );
  }

  Widget _buildFilters() {
    final categories = ['All', 'Fast Food', 'Pizza', 'Asian', 'Desserts'];

    return SizedBox(
      height: 50.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = category == _filterCategory;

          return Padding(
            padding: EdgeInsets.only(right: 8.w),
            child: FilterChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (selected) {
                setState(() => _filterCategory = category);
              },
              backgroundColor: AppColorsDark.surfaceVariant,
              selectedColor: AppColorsDark.primary,
              labelStyle: AppTextStyles.labelMedium().copyWith(
                color: isSelected
                    ? AppColorsDark.background
                    : AppColorsDark.textPrimary,
              ),
            ),
          );
        }
        ),
      );
    
  }

  Widget _buildRestaurantList() {
    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: 10, // TODO: Replace with actual data
      itemBuilder: (context, index) => _buildRestaurantCard(index),
    );
  }

  Widget _buildRestaurantCard(int index) {
    final isActive = index % 3 != 0;

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: AppColorsDark.cardBackground,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColorsDark.border),
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(12.w),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(12.r),
                  child: Image.network(
                    'https://via.placeholder.com/80',
                    width: 80.w,
                    height: 80.w,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 80.w,
                      height: 80.w,
                      color: AppColorsDark.surfaceContainer,
                      child: Icon(
                        Icons.restaurant,
                        color: AppColorsDark.textTertiary,
                      ),
                    ),
                  ),
                ),

                SizedBox(width: 12.w),

                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Restaurant ${index + 1}',
                              style: AppTextStyles.titleMedium().copyWith(
                                color: AppColorsDark.textPrimary,
                              ),
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8.w,
                              vertical: 4.h,
                            ),
                            decoration: BoxDecoration(
                              color: (isActive
                                      ? AppColorsDark.success
                                      : AppColorsDark.error)
                                  .withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6.r),
                            ),
                            child: Text(
                              isActive ? 'ACTIVE' : 'INACTIVE',
                              style: AppTextStyles.labelSmall().copyWith(
                                color: isActive
                                    ? AppColorsDark.success
                                    : AppColorsDark.error,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'Fast Food, Burgers',
                        style: AppTextStyles.bodySmall().copyWith(
                          color: AppColorsDark.textSecondary,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Row(
                        children: [
                          Icon(
                            Icons.star,
                            size: 14.sp,
                            color: AppColorsDark.foodRating,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            '4.${5 - (index % 5)}',
                            style: AppTextStyles.bodySmall().copyWith(
                              color: AppColorsDark.textPrimary,
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Icon(
                            Icons.shopping_bag_outlined,
                            size: 14.sp,
                            color: AppColorsDark.textSecondary,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            '${150 + index * 10} orders',
                            style: AppTextStyles.bodySmall().copyWith(
                              color: AppColorsDark.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Actions
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: () => _showEditRestaurantDialog(index),
                  icon: Icon(
                    Icons.edit,
                    size: 18.sp,
                    color: AppColorsDark.primary,
                  ),
                  label: Text(
                    'Edit',
                    style: AppTextStyles.bodyMedium().copyWith(
                      color: AppColorsDark.primary,
                    ),
                  ),
                ),
              ),
              Container(
                width: 1,
                height: 40.h,
                color: AppColorsDark.border,
              ),
              Expanded(
                child: TextButton.icon(
                  onPressed: () {},
                  icon: Icon(
                    Icons.menu_book,
                    size: 18.sp,
                    color: AppColorsDark.accent,
                  ),
                  label: Text(
                    'Menu',
                    style: AppTextStyles.bodyMedium().copyWith(
                      color: AppColorsDark.accent,
                    ),
                  ),
                ),
              ),
              Container(
                width: 1,
                height: 40.h,
                color: AppColorsDark.border,
              ),
              Expanded(
                child: TextButton.icon(
                  onPressed: () => _showDeleteConfirmation(index),
                  icon: Icon(
                    Icons.delete_outline,
                    size: 18.sp,
                    color: AppColorsDark.error,
                  ),
                  label: Text(
                    'Delete',
                    style: AppTextStyles.bodyMedium().copyWith(
                      color: AppColorsDark.error,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddRestaurantDialog() {
    showDialog(
      context: context,
      builder: (context) => _RestaurantFormDialog(
        title: 'Add Restaurant',
        onSave: (data) {
          // TODO: Implement add restaurant
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Restaurant added successfully!'),
              backgroundColor: AppColorsDark.success,
            ),
          );
        },
      ),
    );
  }

  void _showEditRestaurantDialog(int index) {
    showDialog(
      context: context,
      builder: (context) => _RestaurantFormDialog(
        title: 'Edit Restaurant',
        initialName: 'Restaurant ${index + 1}',
        onSave: (data) {
          // TODO: Implement edit restaurant
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Restaurant updated successfully!'),
              backgroundColor: AppColorsDark.success,
            ),
          );
        },
      ),
    );
  }

  void _showDeleteConfirmation(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColorsDark.surface,
        title: Text(
          'Delete Restaurant',
          style: AppTextStyles.titleLarge().copyWith(
            color: AppColorsDark.textPrimary,
          ),
        ),
        content: Text(
          'Are you sure you want to delete Restaurant ${index + 1}? This action cannot be undone.',
          style: AppTextStyles.bodyMedium().copyWith(
            color: AppColorsDark.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: AppTextStyles.bodyMedium().copyWith(
                color: AppColorsDark.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Restaurant deleted successfully!'),
                  backgroundColor: AppColorsDark.error,
                ),
              );
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

class _RestaurantFormDialog extends StatefulWidget {
  final String title;
  final String? initialName;
  final Function(Map<String, dynamic>) onSave;

  const _RestaurantFormDialog({
    required this.title,
    this.initialName,
    required this.onSave,
  });

  @override
  State<_RestaurantFormDialog> createState() => _RestaurantFormDialogState();
}

class _RestaurantFormDialogState extends State<_RestaurantFormDialog> {
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _addressController = TextEditingController();
    _phoneController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColorsDark.surface,
      title: Text(
        widget.title,
        style: AppTextStyles.titleLarge().copyWith(
          color: AppColorsDark.textPrimary,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Restaurant Name'),
              style: AppTextStyles.bodyMedium().copyWith(
                color: AppColorsDark.textPrimary,
              ),
            ),
            SizedBox(height: 16.h),
            TextField(
              controller: _addressController,
              decoration: const InputDecoration(labelText: 'Address'),
              style: AppTextStyles.bodyMedium().copyWith(
                color: AppColorsDark.textPrimary,
              ),
            ),
            SizedBox(height: 16.h),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: 'Phone'),
              keyboardType: TextInputType.phone,
              style: AppTextStyles.bodyMedium().copyWith(
                color: AppColorsDark.textPrimary,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style: AppTextStyles.bodyMedium().copyWith(
              color: AppColorsDark.textSecondary,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onSave({
              'name': _nameController.text,
              'address': _addressController.text,
              'phone': _phoneController.text,
            });
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}