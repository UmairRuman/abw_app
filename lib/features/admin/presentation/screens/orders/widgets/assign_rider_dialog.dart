// lib/features/admin/presentation/screens/orders/widgets/assign_rider_dialog.dart

import 'package:abw_app/features/riders/presentation/providers/riders_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../../core/theme/colors/app_colors_dark.dart';
import '../../../../../../core/theme/text_styles/app_text_styles.dart';
import '../../../../../orders/data/models/order_model.dart';
import '../../../../../orders/presentation/providers/orders_provider.dart';

class AssignRiderDialog extends ConsumerStatefulWidget {
  final OrderModel order;

  const AssignRiderDialog({required this.order, super.key});

  @override
  ConsumerState<AssignRiderDialog> createState() => _AssignRiderDialogState();
}

class _AssignRiderDialogState extends ConsumerState<AssignRiderDialog> {
  String? _selectedRiderId;
  String? _selectedRiderName;
  bool _isAssigning = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      return ref.read(ridersProvider.notifier).getAvailableRiders();
    });
  }

  @override
  Widget build(BuildContext context) {
    final ridersState = ref.watch(ridersProvider);

    return Dialog(
      backgroundColor: AppColorsDark.surface,
      insetPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 60.h),
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(maxHeight: 500.h),
        child: Column(
          children: [
            // Header
            Container(
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
                  Icon(
                    Icons.delivery_dining,
                    color: AppColorsDark.white,
                    size: 24.sp,
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      'Assign Rider',
                      style: AppTextStyles.titleMedium().copyWith(
                        color: AppColorsDark.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColorsDark.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            Expanded(
              child:
                  ridersState is RidersLoading
                      ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColorsDark.primary,
                        ),
                      )
                      : ridersState is RidersLoaded
                      ? ridersState.riders.isEmpty
                          ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.delivery_dining,
                                  size: 64.sp,
                                  color: AppColorsDark.textTertiary,
                                ),
                                SizedBox(height: 16.h),
                                Text(
                                  'No available riders',
                                  style: AppTextStyles.bodyMedium().copyWith(
                                    color: AppColorsDark.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          )
                          : ListView.builder(
                            padding: EdgeInsets.all(16.w),
                            itemCount: ridersState.riders.length,
                            itemBuilder: (context, index) {
                              final rider = ridersState.riders[index];
                              final isSelected = _selectedRiderId == rider.id;

                              return InkWell(
                                onTap: () {
                                  setState(() {
                                    _selectedRiderId = rider.id;
                                    _selectedRiderName = rider.name;
                                  });
                                },
                                borderRadius: BorderRadius.circular(12.r),
                                child: Container(
                                  margin: EdgeInsets.only(bottom: 8.h),
                                  padding: EdgeInsets.all(16.w),
                                  decoration: BoxDecoration(
                                    color:
                                        isSelected
                                            ? AppColorsDark.primary.withOpacity(
                                              0.1,
                                            )
                                            : AppColorsDark.cardBackground,
                                    borderRadius: BorderRadius.circular(12.r),
                                    border: Border.all(
                                      color:
                                          isSelected
                                              ? AppColorsDark.primary
                                              : AppColorsDark.border,
                                      width: isSelected ? 2 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      // Avatar
                                      Container(
                                        width: 48.w,
                                        height: 48.w,
                                        decoration: const BoxDecoration(
                                          gradient:
                                              AppColorsDark.primaryGradient,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: Text(
                                            rider.name
                                                .substring(0, 1)
                                                .toUpperCase(),
                                            style: AppTextStyles.titleMedium()
                                                .copyWith(
                                                  color: AppColorsDark.white,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 12.w),

                                      // Info
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              rider.name,
                                              style: AppTextStyles.titleSmall()
                                                  .copyWith(
                                                    color:
                                                        AppColorsDark
                                                            .textPrimary,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                            ),
                                            SizedBox(height: 4.h),
                                            Text(
                                              rider.phone,
                                              style: AppTextStyles.bodySmall()
                                                  .copyWith(
                                                    color:
                                                        AppColorsDark
                                                            .textSecondary,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Selection Indicator
                                      if (isSelected)
                                        Icon(
                                          Icons.check_circle,
                                          color: AppColorsDark.primary,
                                          size: 24.sp,
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          )
                      : const Center(child: Text('Failed to load riders')),
            ),

            // Actions
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColorsDark.border)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed:
                          _selectedRiderId == null || _isAssigning
                              ? null
                              : _assignRider,
                      child:
                          _isAssigning
                              ? SizedBox(
                                height: 20.h,
                                width: 20.w,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColorsDark.white,
                                ),
                              )
                              : const Text('Assign Rider'),
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

  Future<void> _assignRider() async {
    if (_selectedRiderId == null || _selectedRiderName == null) return;

    setState(() => _isAssigning = true);

    try {
      final success = await ref
          .read(ordersProvider.notifier)
          .assignRider(widget.order.id, _selectedRiderId!, _selectedRiderName!);

      if (success && mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Rider $_selectedRiderName assigned successfully!'),
            backgroundColor: AppColorsDark.success,
          ),
        );
      } else {
        throw Exception('Failed to assign rider');
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
      if (mounted) setState(() => _isAssigning = false);
    }
  }
}
