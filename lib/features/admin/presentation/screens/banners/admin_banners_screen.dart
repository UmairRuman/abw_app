// lib/features/admin/presentation/screens/banners/admin_banners_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
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
  bool _isUploading = false;

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
          return Column(
            children: [
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
                        'Max 4 banners shown on home screen. Toggle to show/hide.',
                        style: AppTextStyles.bodySmall().copyWith(
                          color: AppColorsDark.info,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  itemCount: banners.length,
                  itemBuilder:
                      (context, index) => _buildBannerTile(banners[index]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBannerTile(BannerModel banner) {
    return Container(
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
          ClipRRect(
            borderRadius: BorderRadius.vertical(top: Radius.circular(14.r)),
            child:
                banner.imageUrl.isNotEmpty
                    ? Image.network(
                      banner.imageUrl,
                      width: double.infinity,
                      height: 160.h,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildImagePlaceholder(),
                    )
                    : _buildImagePlaceholder(),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
            child: Row(
              children: [
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
                    SizedBox(width: 6.w),
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

  void _showAddBannerDialog() {
    final titleController = TextEditingController();
    File? selectedImage;

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
                        // Image picker area
                        GestureDetector(
                          onTap: () async {
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
                          style: AppTextStyles.bodyMedium().copyWith(
                            color: AppColorsDark.textPrimary,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Banner Title (optional)',
                            hintText: 'e.g., Summer Sale, New Arrivals',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                          ),
                        ),
                        if (_isUploading) ...[
                          SizedBox(height: 16.h),
                          const LinearProgressIndicator(
                            color: AppColorsDark.primary,
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            'Uploading banner...',
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
                          _isUploading
                              ? null
                              : () {
                                titleController.dispose();
                                Navigator.pop(ctx);
                              },
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed:
                          selectedImage == null || _isUploading
                              ? null
                              : () async {
                                final imageFile = selectedImage!;
                                final title = titleController.text.trim();

                                setState(() => _isUploading = true);
                                setDialogState(() {}); // refresh dialog

                                try {
                                  // ✅ FIX 3: Renamed storage reference to 'storageRef'
                                  // to avoid shadowing Riverpod's 'ref' variable.
                                  final id =
                                      DateTime.now().millisecondsSinceEpoch
                                          .toString();
                                  final storageRef = FirebaseStorage.instance
                                      .ref()
                                      .child('banners')
                                      .child('$id.jpg');

                                  await storageRef.putFile(
                                    imageFile,
                                    SettableMetadata(contentType: 'image/jpeg'),
                                  );
                                  final downloadUrl =
                                      await storageRef.getDownloadURL();

                                  // Get current banner count for ordering
                                  final snapshot =
                                      await FirebaseFirestore.instance
                                          .collection('banners')
                                          .get();
                                  final order = snapshot.docs.length;

                                  await ref
                                      .read(bannersProvider.notifier)
                                      .addBanner(
                                        imageUrl: downloadUrl,
                                        title: title,
                                        order: order,
                                      );

                                  titleController.dispose();
                                  if (mounted) Navigator.pop(ctx);
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Banner added successfully ✅',
                                        ),
                                        backgroundColor: AppColorsDark.success,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Upload failed: $e'),
                                        backgroundColor: AppColorsDark.error,
                                      ),
                                    );
                                  }
                                } finally {
                                  if (mounted)
                                    setState(() => _isUploading = false);
                                }
                              },
                      child: const Text('Upload & Add'),
                    ),
                  ],
                ),
          ),
    ).then((_) {
      // Dispose safely after dialog fully closes
      if (!_isUploading) titleController.dispose();
    });
  }

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
                  // ✅ Also delete from Firebase Storage if possible
                  try {
                    if (banner.imageUrl.isNotEmpty) {
                      await FirebaseStorage.instance
                          .refFromURL(banner.imageUrl)
                          .delete();
                    }
                  } catch (_) {
                    // Storage delete failing shouldn't block Firestore delete
                  }
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
