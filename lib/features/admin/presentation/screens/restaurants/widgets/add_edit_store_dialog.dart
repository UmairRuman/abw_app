// lib/features/admin/presentation/screens/restaurants/widgets/add_edit_store_dialog.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../../../core/theme/colors/app_colors_dark.dart';
import '../../../../../../core/theme/text_styles/app_text_styles.dart';
import '../../../../../../core/presentation/providers/image_upload_provider.dart';
import '../../../../../categories/presentation/providers/categories_provider.dart';
import '../../../../../stores/presentation/providers/stores_provider.dart';
import '../../../../../stores/data/models/store_model.dart';

class AddEditStoreDialog extends ConsumerStatefulWidget {
  final StoreModel? store; // null for add, populated for edit

  const AddEditStoreDialog({
    super.key,
    this.store,
  });

  @override
  ConsumerState<AddEditStoreDialog> createState() => _AddEditStoreDialogState();
}

class _AddEditStoreDialogState extends ConsumerState<AddEditStoreDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _areaController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _ownerEmailController = TextEditingController();
  final _ownerPhoneController = TextEditingController();
  final _deliveryFeeController = TextEditingController();
  final _deliveryTimeController = TextEditingController();
  final _minOrderController = TextEditingController();
  final _openingTimeController = TextEditingController();
  final _closingTimeController = TextEditingController();

  String _selectedCategory = '';
  String _selectedType = 'restaurant';
  File? _logoImage;
  File? _bannerImage;
  final List<File> _storeImages = [];
  bool _isLoading = false;

  final List<String> _storeTypes = [
    'restaurant',
    'pharmacy',
    'grocery',
    'bakery',
    'cafe',
  ];

  final List<String> _workingDays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  final List<String> _selectedWorkingDays = [];

  @override
  void initState() {
    super.initState();
    if (widget.store != null) {
      _populateFields(widget.store!);
    }
    _loadCategories();
  }

  void _populateFields(StoreModel store) {
    _nameController.text = store.name;
    _descController.text = store.description;
    _addressController.text = store.address;
    _cityController.text = store.city;
    _areaController.text = store.area;
    _ownerNameController.text = store.ownerName;
    _ownerEmailController.text = store.ownerEmail;
    _ownerPhoneController.text = store.ownerPhone;
    _deliveryFeeController.text = store.deliveryFee.toString();
    _deliveryTimeController.text = store.deliveryTime.toString();
    _minOrderController.text = store.minimumOrder.toString();
    _openingTimeController.text = store.openingTime;
    _closingTimeController.text = store.closingTime;
    _selectedCategory = store.categoryId;
    _selectedType = store.type;
    _selectedWorkingDays.addAll(store.workingDays);
  }

  Future<void> _loadCategories() async {
     await Future.delayed(const Duration(milliseconds: 500)); 
    await ref.read(categoriesProvider.notifier).getAllCategories();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _areaController.dispose();
    _ownerNameController.dispose();
    _ownerEmailController.dispose();
    _ownerPhoneController.dispose();
    _deliveryFeeController.dispose();
    _deliveryTimeController.dispose();
    _minOrderController.dispose();
    _openingTimeController.dispose();
    _closingTimeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesState = ref.watch(categoriesProvider);

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

            // Form
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(20.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Images Section
                      _buildImagesSection(),
                      SizedBox(height: 24.h),

                      // Basic Info
                      _buildSectionTitle('Basic Information'),
                      SizedBox(height: 12.h),
                      _buildTextField(
                        controller: _nameController,
                        label: 'Store Name',
                        hint: 'e.g., Pizza Palace',
                        validator: (v) =>
                            v?.isEmpty ?? true ? 'Required' : null,
                      ),
                      SizedBox(height: 16.h),
                      _buildTextField(
                        controller: _descController,
                        label: 'Description',
                        hint: 'Brief description of your store',
                        maxLines: 3,
                        validator: (v) =>
                            v?.isEmpty ?? true ? 'Required' : null,
                      ),
                      SizedBox(height: 16.h),

                      // Category & Type
                    Row(
  children: [
    Flexible(
      child: DropdownButtonHideUnderline(
        child: _buildCategoryDropdown(categoriesState),
      ),
    ),
    SizedBox(width: 12.w),
    Flexible(
      child: DropdownButtonHideUnderline(
        child: _buildTypeDropdown(),
      ),
    ),
  ],
),
                      SizedBox(height: 24.h),

                      // Owner Info
                      _buildSectionTitle('Owner Information'),
                      SizedBox(height: 12.h),
                      _buildTextField(
                        controller: _ownerNameController,
                        label: 'Owner Name',
                        validator: (v) =>
                            v?.isEmpty ?? true ? 'Required' : null,
                      ),
                      SizedBox(height: 16.h),
                      _buildTextField(
                        controller: _ownerEmailController,
                        label: 'Email',
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) =>
                            v?.isEmpty ?? true ? 'Required' : null,
                      ),
                      SizedBox(height: 16.h),
                      _buildTextField(
                        controller: _ownerPhoneController,
                        label: 'Phone',
                        keyboardType: TextInputType.phone,
                        validator: (v) =>
                            v?.isEmpty ?? true ? 'Required' : null,
                      ),
                      SizedBox(height: 24.h),

                      // Location
                      _buildSectionTitle('Location'),
                      SizedBox(height: 12.h),
                      _buildTextField(
                        controller: _addressController,
                        label: 'Address',
                        maxLines: 2,
                        validator: (v) =>
                            v?.isEmpty ?? true ? 'Required' : null,
                      ),
                      SizedBox(height: 16.h),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _areaController,
                              label: 'Area',
                              validator: (v) =>
                                  v?.isEmpty ?? true ? 'Required' : null,
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: _buildTextField(
                              controller: _cityController,
                              label: 'City',
                              validator: (v) =>
                                  v?.isEmpty ?? true ? 'Required' : null,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 24.h),

                      // Delivery Info
                      _buildSectionTitle('Delivery Information'),
                      SizedBox(height: 12.h),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _deliveryFeeController,
                              label: 'Delivery Fee (PKR)',
                              keyboardType: TextInputType.number,
                              validator: (v) =>
                                  v?.isEmpty ?? true ? 'Required' : null,
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: _buildTextField(
                              controller: _deliveryTimeController,
                              label: 'Delivery Time (mins)',
                              keyboardType: TextInputType.number,
                              validator: (v) =>
                                  v?.isEmpty ?? true ? 'Required' : null,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16.h),
                      _buildTextField(
                        controller: _minOrderController,
                        label: 'Minimum Order (PKR)',
                        keyboardType: TextInputType.number,
                        validator: (v) =>
                            v?.isEmpty ?? true ? 'Required' : null,
                      ),
                      SizedBox(height: 24.h),

                      // Operating Hours
                      _buildSectionTitle('Operating Hours'),
                      SizedBox(height: 12.h),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTimeField(
                              controller: _openingTimeController,
                              label: 'Opening Time',
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: _buildTimeField(
                              controller: _closingTimeController,
                              label: 'Closing Time',
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16.h),
                      _buildWorkingDaysSelector(),
                      SizedBox(height: 24.h),
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
          Icon(
            Icons.store,
            color: AppColorsDark.white,
            size: 24.sp,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              widget.store == null ? 'Add New Store' : 'Edit Store',
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

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTextStyles.titleSmall().copyWith(
        color: AppColorsDark.textPrimary,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: AppTextStyles.bodyMedium().copyWith(
        color: AppColorsDark.textPrimary,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
      ),
      validator: validator,
    );
  }

Widget _buildCategoryDropdown(CategoriesState state) {
  if (state is! CategoriesLoaded) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColorsDark.surfaceVariant,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Text(
        'Loading categories...',
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.bodyMedium().copyWith(
          color: AppColorsDark.textSecondary,
        ),
      ),
    );
  }

  return DropdownButtonFormField<String>(
    isExpanded: true, // <<< CRITICAL
    value: _selectedCategory.isEmpty ? null : _selectedCategory,
    decoration: InputDecoration(
      labelText: 'Category',
      isDense: true, // <<< CRITICAL
      contentPadding:
          EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h), // <<< CRITICAL
    ),
    items: state.categories.map((category) {
      return DropdownMenuItem(
        value: category.id,
        child: Text(
          category.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      );
    }).toList(),
    onChanged: (value) {
      setState(() => _selectedCategory = value ?? '');
    },
    validator: (v) => v == null ? 'Required' : null,
  );
}


Widget _buildTypeDropdown() {
  return DropdownButtonFormField<String>(
    isExpanded: true, // <<< CRITICAL
    value: _selectedType,
    decoration: InputDecoration(
      labelText: 'Type',
      isDense: true,
      contentPadding:
          EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
    ),
    items: _storeTypes.map((type) {
      return DropdownMenuItem(
        value: type,
        child: Text(
          type.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      );
    }).toList(),
    onChanged: (value) {
      setState(() => _selectedType = value ?? 'restaurant');
    },
  );
}


  Widget _buildTimeField({
    required TextEditingController controller,
    required String label,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: const Icon(Icons.access_time),
      ),
      onTap: () async {
        final time = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.now(),
        );
        if (time != null) {
          controller.text = time.format(context);
        }
      },
      validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
    );
  }

  Widget _buildWorkingDaysSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Working Days',
          style: AppTextStyles.bodyMedium().copyWith(
            color: AppColorsDark.textSecondary,
          ),
        ),
        SizedBox(height: 8.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: _workingDays.map((day) {
            final isSelected = _selectedWorkingDays.contains(day);
            return FilterChip(
              label: Text(day.substring(0, 3)),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedWorkingDays.add(day);
                  } else {
                    _selectedWorkingDays.remove(day);
                  }
                });
              },
              selectedColor: AppColorsDark.primary.withOpacity(0.3),
              checkmarkColor: AppColorsDark.primary,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildImagesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Store Images'),
        SizedBox(height: 12.h),
        
        // Logo
        _buildImagePicker(
          label: 'Logo',
          image: _logoImage,
          onTap: () => _pickImage(ImageType.logo),
        ),
        SizedBox(height: 12.h),
        
        // Banner
        _buildImagePicker(
          label: 'Banner',
          image: _bannerImage,
          onTap: () => _pickImage(ImageType.banner),
          aspectRatio: 3,
        ),
        SizedBox(height: 12.h),
        
        // Gallery
        _buildGalleryPicker(),
      ],
    );
  }

  Widget _buildImagePicker({
    required String label,
    required File? image,
    required VoidCallback onTap,
    double aspectRatio = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.bodySmall().copyWith(
            color: AppColorsDark.textSecondary,
          ),
        ),
        SizedBox(height: 8.h),
      InkWell(
  onTap: onTap,
  borderRadius: BorderRadius.circular(12.r),
  child: aspectRatio == 1
      ? SizedBox(
          height: 110.h,
          width: 110.h,
          child: AspectRatio(
            aspectRatio: 1,
            child: _imageContainer(image, label),
          ),
        )
      : AspectRatio(
          aspectRatio: aspectRatio,
          child: _imageContainer(image, label),
        ),
),

      ],
    );
  }


  Widget _imageContainer(File? image, String label) {
  return Container(
    decoration: BoxDecoration(
      color: AppColorsDark.surfaceVariant,
      borderRadius: BorderRadius.circular(12.r),
      border: Border.all(color: AppColorsDark.border),
    ),
    child: image != null
        ? ClipRRect(
            borderRadius: BorderRadius.circular(12.r),
            child: Image.file(
              image,
              fit: BoxFit.cover,
              width: double.infinity,
            ),
          )
        : Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.add_photo_alternate,
                  size: 32.sp,
                  color: AppColorsDark.textTertiary,
                ),
                SizedBox(height: 6.h),
                Text(
                  'Tap to add $label',
                  style: AppTextStyles.bodySmall().copyWith(
                    color: AppColorsDark.textTertiary,
                  ),
                ),
              ],
            ),
          ),
  );
}


  Widget _buildGalleryPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Store Images (${_storeImages.length}/5)',
              style: AppTextStyles.bodySmall().copyWith(
                color: AppColorsDark.textSecondary,
              ),
            ),
            if (_storeImages.length < 5)
              TextButton.icon(
                onPressed: () => _pickImage(ImageType.gallery),
                icon: Icon(Icons.add, size: 18.sp),
                label: const Text('Add'),
              ),
          ],
        ),
        SizedBox(height: 8.h),
        if (_storeImages.isNotEmpty)
          SizedBox(
            height: 100.h,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _storeImages.length,
              separatorBuilder: (context, index) => SizedBox(width: 8.w),
              itemBuilder: (context, index) {
                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8.r),
                      child: Image.file(
                        _storeImages[index],
                        width: 100.w,
                        height: 100.h,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 4.h,
                      right: 4.w,
                      child: InkWell(
                        onTap: () {
                          setState(() => _storeImages.removeAt(index));
                        },
                        child: Container(
                          padding: EdgeInsets.all(4.w),
                          decoration: const BoxDecoration(
                            color: AppColorsDark.error,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.close,
                            size: 16.sp,
                            color: AppColorsDark.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildActions() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(
            color: AppColorsDark.border,
            width: 1,
          ),
        ),
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
              child: _isLoading
                  ? SizedBox(
                      height: 20.h,
                      width: 20.w,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColorsDark.white,
                      ),
                    )
                  : Text(widget.store == null ? 'Add Store' : 'Update'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage(ImageType type) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (pickedFile != null) {
      setState(() {
        final file = File(pickedFile.path);
        switch (type) {
          case ImageType.logo:
            _logoImage = file;
            break;
          case ImageType.banner:
            _bannerImage = file;
            break;
          case ImageType.gallery:
            if (_storeImages.length < 5) {
              _storeImages.add(file);
            }
            break;
        }
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields'),
          backgroundColor: AppColorsDark.error,
        ),
      );
      return;
    }

    if (_selectedWorkingDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one working day'),
          backgroundColor: AppColorsDark.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Upload images
      String logoUrl = widget.store?.logoUrl ?? '';
      String bannerUrl = widget.store?.bannerUrl ?? '';
      List<String> imageUrls = widget.store?.images ?? [];

      final storeId = widget.store?.id ??
          DateTime.now().millisecondsSinceEpoch.toString();

      if (_logoImage != null) {
        final publicId = await ref
            .read(imageUploadProvider.notifier)
            .uploadStoreLogo(_logoImage!, storeId);
        if (publicId != null) {
          logoUrl = ref
              .read(imageUploadProvider.notifier)
              .getOptimizedUrl(publicId);
        }
      }

      if (_bannerImage != null) {
        final publicId = await ref
            .read(imageUploadProvider.notifier)
            .uploadStoreBanner(_bannerImage!, storeId);
        if (publicId != null) {
          bannerUrl = ref
              .read(imageUploadProvider.notifier)
              .getOptimizedUrl(publicId);
        }
      }

      if (_storeImages.isNotEmpty) {
        final publicIds = await ref
            .read(imageUploadProvider.notifier)
            .uploadStoreImages(_storeImages, storeId);
        imageUrls = publicIds
            .map((id) => ref
                .read(imageUploadProvider.notifier)
                .getOptimizedUrl(id))
            .toList();
      }

      // Get category name
      final categoriesState = ref.read(categoriesProvider);
      String categoryName = '';
      if (categoriesState is CategoriesLoaded) {
        final category = categoriesState.categories
            .firstWhere((c) => c.id == _selectedCategory);
        categoryName = category.name;
      }

      // Create store model
      final store = StoreModel(
        id: storeId,
        name: _nameController.text.trim(),
        description: _descController.text.trim(),
        categoryId: _selectedCategory,
        categoryName: categoryName,
        type: _selectedType,
        ownerId: 'admin-id', // TODO: Get from auth
        ownerName: _ownerNameController.text.trim(),
        ownerEmail: _ownerEmailController.text.trim(),
        ownerPhone: _ownerPhoneController.text.trim(),
        images: imageUrls,
        logoUrl: logoUrl,
        bannerUrl: bannerUrl,
        address: _addressController.text.trim(),
        city: _cityController.text.trim(),
        area: _areaController.text.trim(),
        latitude: 0.0, // TODO: Get from map
        longitude: 0.0,
        deliveryFee: double.parse(_deliveryFeeController.text),
        deliveryTime: int.parse(_deliveryTimeController.text),
        minimumOrder: double.parse(_minOrderController.text),
        openingTime: _openingTimeController.text,
        closingTime: _closingTimeController.text,
        workingDays: _selectedWorkingDays,
        isApproved: true, // Admin added, auto-approve
        createdAt: widget.store?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Save to database
      final success = widget.store == null
          ? await ref.read(storesProvider.notifier).addStore(store)
          : await ref.read(storesProvider.notifier).updateStore(store);

      if (success && mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.store == null
                  ? 'Store added successfully'
                  : 'Store updated successfully',
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

enum ImageType { logo, banner, gallery }