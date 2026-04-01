// lib/features/admin/presentation/screens/banners/admin_banners_screen.dart

import 'dart:io';
import 'package:abw_app/core/presentation/providers/image_upload_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../../core/theme/colors/app_colors_dark.dart';
import '../../../../../core/theme/text_styles/app_text_styles.dart';
import '../../../../banners/presentation/providers/banners_provider.dart';

class AdminBannersScreen extends ConsumerStatefulWidget {
  const AdminBannersScreen({super.key});

  @override
  ConsumerState<AdminBannersScreen> createState() => _AdminBannersScreenState();
}

class _AdminBannersScreenState extends ConsumerState<AdminBannersScreen> {
  @override
  Widget build(BuildContext context) {
    final bannersAsync = ref.watch(allBannersStreamProvider);

    return Scaffold(
      backgroundColor: AppColorsDark.background,
      appBar: AppBar(
        title: Text(
          'Banner Management',
          style: AppTextStyles.titleLarge().copyWith(
            color: AppColorsDark.textPrimary,
          ),
        ),
        backgroundColor: AppColorsDark.surface,
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: AppColorsDark.primary, size: 28.sp),
            onPressed: _showAddBannerDialog,
            tooltip: 'Add Banner',
          ),
        ],
      ),
      body: bannersAsync.when(
        loading:
            () => const Center(
              child: CircularProgressIndicator(color: AppColorsDark.primary),
            ),
        error:
            (e, _) => Center(
              child: Text(
                'Error: $e',
                style: AppTextStyles.bodyMedium().copyWith(
                  color: AppColorsDark.error,
                ),
              ),
            ),
        data: (banners) {
          if (banners.isEmpty) return _buildEmptyState();

          // Sort by order field
          final sorted = [...banners]
            ..sort((a, b) => a.order.compareTo(b.order));

          return Column(
            children: [
              // Info + reorder hint
              Container(
                margin: EdgeInsets.all(16.w),
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: AppColorsDark.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: AppColorsDark.info.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppColorsDark.info,
                      size: 18.sp,
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        'Max 4 banners shown on home. Toggle to show/hide. '
                        'Drag ☰ to reorder.',
                        style: AppTextStyles.bodySmall().copyWith(
                          color: AppColorsDark.info,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ✅ Drag-to-reorder list
              Expanded(
                child: ReorderableListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  itemCount: sorted.length,
                  onReorder:
                      (oldIndex, newIndex) =>
                          _onReorder(sorted, oldIndex, newIndex),
                  itemBuilder: (context, index) {
                    final banner = sorted[index];
                    return _buildBannerTile(banner, key: Key(banner.id));
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── Reorder handler ────────────────────────────────────────────────────────

  Future<void> _onReorder(
    List<BannerModel> sorted,
    int oldIndex,
    int newIndex,
  ) async {
    if (newIndex > oldIndex) newIndex--;
    final reordered = [...sorted];
    final item = reordered.removeAt(oldIndex);
    reordered.insert(newIndex, item);

    // Write new order values to Firestore
    final batch = FirebaseFirestore.instance.batch();
    for (int i = 0; i < reordered.length; i++) {
      batch.update(
        FirebaseFirestore.instance.collection('banners').doc(reordered[i].id),
        {'order': i},
      );
    }
    await batch.commit();
  }

  // ── Banner tile ────────────────────────────────────────────────────────────

  Widget _buildBannerTile(BannerModel banner, {required Key key}) {
    return Container(
      key: key,
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: AppColorsDark.cardBackground,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color:
              banner.isActive
                  ? AppColorsDark.primary.withOpacity(0.4)
                  : AppColorsDark.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ Image — now correctly uses secure_url from Cloudinary
          ClipRRect(
            borderRadius: BorderRadius.vertical(top: Radius.circular(14.r)),
            child:
                banner.imageUrl.isNotEmpty
                    ? Image.network(
                      banner.imageUrl,
                      width: double.infinity,
                      height: 160.h,
                      fit: BoxFit.cover,
                      loadingBuilder:
                          (_, child, progress) =>
                              progress == null
                                  ? child
                                  : Container(
                                    height: 160.h,
                                    color: AppColorsDark.surfaceContainer,
                                    child: const Center(
                                      child: CircularProgressIndicator(
                                        color: AppColorsDark.primary,
                                      ),
                                    ),
                                  ),
                      errorBuilder: (_, err, __) {
                        debugPrint('Banner image error: $err');
                        return _buildImagePlaceholder();
                      },
                    )
                    : _buildImagePlaceholder(),
          ),

          Padding(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
            child: Row(
              children: [
                // ✅ Drag handle
                Icon(
                  Icons.drag_handle,
                  color: AppColorsDark.textTertiary,
                  size: 24.sp,
                ),
                SizedBox(width: 8.w),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        banner.title.isNotEmpty
                            ? banner.title
                            : 'Untitled Banner',
                        style: AppTextStyles.titleSmall().copyWith(
                          color: AppColorsDark.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        'Position: ${banner.order + 1}',
                        style: AppTextStyles.bodySmall().copyWith(
                          color: AppColorsDark.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                // Toggle
                Row(
                  children: [
                    Text(
                      banner.isActive ? 'Active' : 'Hidden',
                      style: AppTextStyles.bodySmall().copyWith(
                        color:
                            banner.isActive
                                ? AppColorsDark.success
                                : AppColorsDark.textTertiary,
                      ),
                    ),
                    SizedBox(width: 4.w),
                    Switch(
                      value: banner.isActive,
                      onChanged:
                          (val) => ref
                              .read(bannersProvider.notifier)
                              .toggleBanner(banner.id, val),
                      activeColor: AppColorsDark.primary,
                    ),
                  ],
                ),

                // Delete
                IconButton(
                  icon: Icon(
                    Icons.delete_outline,
                    color: AppColorsDark.error,
                    size: 22.sp,
                  ),
                  onPressed: () => _confirmDelete(banner),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePlaceholder() => Container(
    width: double.infinity,
    height: 160.h,
    color: AppColorsDark.surfaceContainer,
    child: Icon(
      Icons.image_outlined,
      size: 48.sp,
      color: AppColorsDark.textTertiary,
    ),
  );

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_outlined,
            size: 80.sp,
            color: AppColorsDark.textTertiary,
          ),
          SizedBox(height: 16.h),
          Text(
            'No Banners Yet',
            style: AppTextStyles.titleLarge().copyWith(
              color: AppColorsDark.textPrimary,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Tap + to add your first banner',
            style: AppTextStyles.bodyMedium().copyWith(
              color: AppColorsDark.textSecondary,
            ),
          ),
          SizedBox(height: 24.h),
          ElevatedButton.icon(
            onPressed: _showAddBannerDialog,
            icon: Icon(Icons.add, size: 20.sp),
            label: const Text('Add Banner'),
          ),
        ],
      ),
    );
  }

  // ── Add banner dialog ──────────────────────────────────────────────────────

  void _showAddBannerDialog() {
    final titleController = TextEditingController();
    File? selectedImage;
    bool isUploading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (ctx) => StatefulBuilder(
            builder:
                (ctx, setDialogState) => AlertDialog(
                  backgroundColor: AppColorsDark.surface,
                  title: Text(
                    'Add New Banner',
                    style: AppTextStyles.titleLarge().copyWith(
                      color: AppColorsDark.textPrimary,
                    ),
                  ),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Image picker
                        GestureDetector(
                          onTap:
                              isUploading
                                  ? null
                                  : () async {
                                    final picker = ImagePicker();
                                    final file = await picker.pickImage(
                                      source: ImageSource.gallery,
                                      imageQuality: 80,
                                    );
                                    if (file != null) {
                                      setDialogState(
                                        () => selectedImage = File(file.path),
                                      );
                                    }
                                  },
                          child: Container(
                            width: double.infinity,
                            height: 150.h,
                            decoration: BoxDecoration(
                              color: AppColorsDark.surfaceContainer,
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(color: AppColorsDark.border),
                            ),
                            child:
                                selectedImage != null
                                    ? ClipRRect(
                                      borderRadius: BorderRadius.circular(12.r),
                                      child: Image.file(
                                        selectedImage!,
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        height: double.infinity,
                                      ),
                                    )
                                    : Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.add_photo_alternate,
                                          size: 48.sp,
                                          color: AppColorsDark.textTertiary,
                                        ),
                                        SizedBox(height: 8.h),
                                        Text(
                                          'Tap to select image',
                                          style: AppTextStyles.bodySmall()
                                              .copyWith(
                                                color:
                                                    AppColorsDark.textSecondary,
                                              ),
                                        ),
                                      ],
                                    ),
                          ),
                        ),
                        SizedBox(height: 16.h),
                        TextFormField(
                          controller: titleController,
                          enabled: !isUploading,
                          style: AppTextStyles.bodyMedium().copyWith(
                            color: AppColorsDark.textPrimary,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Banner Title (optional)',
                            hintText: 'e.g., Summer Sale',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                          ),
                        ),
                        if (isUploading) ...[
                          SizedBox(height: 16.h),
                          const LinearProgressIndicator(
                            color: AppColorsDark.primary,
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            'Uploading to Cloudinary...',
                            style: AppTextStyles.bodySmall().copyWith(
                              color: AppColorsDark.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed:
                          isUploading
                              ? null
                              : () {
                                titleController.dispose();
                                Navigator.pop(ctx);
                              },
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed:
                          selectedImage == null || isUploading
                              ? null
                              : () async {
                                final imageFile = selectedImage!;
                                final title = titleController.text.trim();
                                setDialogState(() => isUploading = true);

                                try {
                                  // ✅ uploadAppBanner returns a real secure_url
                                  final secureUrl = await ref
                                      .read(imageUploadProvider.notifier)
                                      .uploadAppBanner(imageFile);

                                  if (secureUrl == null || secureUrl.isEmpty) {
                                    throw Exception(
                                      'No URL returned — check Cloudinary preset',
                                    );
                                  }

                                  final countSnap =
                                      await FirebaseFirestore.instance
                                          .collection('banners')
                                          .get();
                                  final order = countSnap.docs.length;

                                  await ref
                                      .read(bannersProvider.notifier)
                                      .addBanner(
                                        imageUrl: secureUrl,
                                        title: title,
                                        order: order,
                                      );

                                  titleController.dispose();
                                  if (ctx.mounted) Navigator.pop(ctx);
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Banner added ✅'),
                                        backgroundColor: AppColorsDark.success,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (ctx.mounted) {
                                    setDialogState(() => isUploading = false);
                                  }
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Upload failed: $e'),
                                        backgroundColor: AppColorsDark.error,
                                      ),
                                    );
                                  }
                                }
                              },
                      child: const Text('Upload & Add'),
                    ),
                  ],
                ),
          ),
    ).then((_) {
      try {
        titleController.dispose();
      } catch (_) {}
    });
  }

  // ── Delete ─────────────────────────────────────────────────────────────────

  void _confirmDelete(BannerModel banner) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: AppColorsDark.surface,
            title: Text(
              'Delete Banner',
              style: AppTextStyles.titleMedium().copyWith(
                color: AppColorsDark.error,
              ),
            ),
            content: Text(
              'This will permanently delete this banner.',
              style: AppTextStyles.bodyMedium().copyWith(
                color: AppColorsDark.textSecondary,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  await ref
                      .read(bannersProvider.notifier)
                      .deleteBanner(banner.id);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Banner deleted'),
                        backgroundColor: AppColorsDark.success,
                      ),
                    );
                  }
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
