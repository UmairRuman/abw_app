// lib/features/admin/presentation/screens/products/widgets/add_edit_product_dialog.dart

import 'dart:io';
import 'package:abw_app/features/admin/presentation/screens/products/widgets/helper_classes.dart';
import 'package:abw_app/features/products/domain/entities/product_variant.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../../../core/theme/colors/app_colors_dark.dart';
import '../../../../../../core/theme/text_styles/app_text_styles.dart';
import '../../../../../../core/presentation/providers/image_upload_provider.dart';
import '../../../../../categories/presentation/providers/categories_provider.dart';
import '../../../../../stores/presentation/providers/stores_provider.dart';
import '../../../../../products/presentation/providers/products_provider.dart';
import '../../../../../products/data/models/product_model.dart';

class AddEditProductDialog extends ConsumerStatefulWidget {
  final ProductModel? product;
  final String? storeId; // null for add, populated for edit

  const AddEditProductDialog({super.key, this.product, this.storeId});

  @override
  ConsumerState<AddEditProductDialog> createState() =>
      _AddEditProductDialogState();
}

class _AddEditProductDialogState extends ConsumerState<AddEditProductDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _shortDescController = TextEditingController();
  final _priceController = TextEditingController();
  final _originalPriceController = TextEditingController();
  final _discountController = TextEditingController();
  final _unitController = TextEditingController();
  final _quantityController = TextEditingController();
  final _minOrderController = TextEditingController();
  final _maxOrderController = TextEditingController();
  final _prepTimeController = TextEditingController();
  // Controllers for adding variants/addons
  final _variantNameController = TextEditingController();
  final _variantPriceController = TextEditingController();
  final _addonNameController = TextEditingController();
  final _addonPriceController = TextEditingController();

  String _selectedCategory = '';
  String _selectedStore = '';
  final List<File> _productImages = [];
  bool _isLoading = false;

  // Checkboxes
  bool _isAvailable = true;
  bool _isFeatured = false;
  bool _isPopular = false;
  bool _isVegetarian = false;
  bool _isVegan = false;
  bool _isSpicy = false;

  // ✅ ADD THESE
  bool _hasVariants = false;
  final List<ProductVariantInput> _variants = [];
  final List<ProductAddonInput> _addons = [];

  // Tags
  final List<String> _availableTags = [
    'New',
    'Best Seller',
    'Hot Deal',
    'Limited',
    'Organic',
    'Fresh',
  ];
  final List<String> _selectedTags = [];

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _populateFields(widget.product!);
    }
    _loadData();
  }

  void _populateFields(ProductModel product) {
    _nameController.text = product.name;
    _descController.text = product.description;
    _shortDescController.text = product.shortDescription;
    _priceController.text = product.price.toString();
    _originalPriceController.text = product.originalPrice.toString();
    _discountController.text = product.discount.toString();
    _unitController.text = product.unit;
    _quantityController.text = product.quantity.toString();
    _minOrderController.text = product.minOrderQuantity.toString();
    _maxOrderController.text = product.maxOrderQuantity.toString();
    _prepTimeController.text = product.preparationTime.toString();

    _selectedCategory = product.categoryId;
    _selectedStore = product.storeId;
    _isAvailable = product.isAvailable;
    _isFeatured = product.isFeatured;
    _isPopular = product.isPopular;
    _isVegetarian = product.isVegetarian;
    _isVegan = product.isVegan;
    _isSpicy = product.isSpicy;
    _selectedTags.addAll(product.tags);

    _hasVariants = product.hasVariants;
    if (product.variants.isNotEmpty) {
      _variants.addAll(
        product.variants.map((v) => ProductVariantInput.fromVariant(v)),
      );
    }
    if (product.addons.isNotEmpty) {
      _addons.addAll(product.addons.map((a) => ProductAddonInput.fromAddon(a)));
    }
  }

  Future<void> _loadData() async {
    await Future.delayed(const Duration(milliseconds: 300));

    // ✅ FIXED: Handle null case properly
    String? storeId = widget.product?.storeId ?? widget.storeId;

    // If no storeId, just load categories and all stores
    if (storeId == null) {
      await Future.wait([
        ref.read(categoriesProvider.notifier).getAllCategories(),
        ref.read(storesProvider.notifier).getAllStores(),
      ]);
      return;
    }

    // If we have storeId, load specific store
    await Future.wait([
      ref.read(categoriesProvider.notifier).getAllCategories(),
      ref.read(storesProvider.notifier).getStore(storeId),
    ]);

    // Set initial store selection
    if (mounted) {
      final storesState = ref.read(storesProvider);
      if (storesState is StoreSingleLoaded) {
        setState(() {
          _selectedStore = storesState.store.id;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _shortDescController.dispose();
    _priceController.dispose();
    _originalPriceController.dispose();
    _discountController.dispose();
    _unitController.dispose();
    _quantityController.dispose();
    _minOrderController.dispose();
    _maxOrderController.dispose();
    _prepTimeController.dispose();
    // Disposing the new controllers for variants/addons
    _variantNameController.dispose();
    _variantPriceController.dispose();
    _addonNameController.dispose();
    _addonPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesState = ref.watch(categoriesProvider);
    final storesState = ref.watch(storesProvider);

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
                        label: 'Product Name',
                        hint: 'e.g., Margherita Pizza',
                        validator:
                            (v) => v?.isEmpty ?? true ? 'Required' : null,
                      ),
                      SizedBox(height: 16.h),
                      _buildTextField(
                        controller: _shortDescController,
                        label: 'Short Description',
                        hint: 'Brief tagline',
                        maxLines: 2,
                        validator:
                            (v) => v?.isEmpty ?? true ? 'Required' : null,
                      ),
                      SizedBox(height: 16.h),
                      _buildTextField(
                        controller: _descController,
                        label: 'Full Description',
                        hint: 'Detailed description',
                        maxLines: 4,
                        validator:
                            (v) => v?.isEmpty ?? true ? 'Required' : null,
                      ),
                      SizedBox(height: 16.h),

                      // Category & Store
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final fieldWidth = (constraints.maxWidth - 12.w) / 2;

                          return Row(
                            children: [
                              SizedBox(
                                width: fieldWidth,
                                child: _buildCategoryDropdown(categoriesState),
                              ),
                              SizedBox(width: 12.w),
                              SizedBox(
                                width: fieldWidth,
                                child: _buildStoreDropdown(storesState),
                              ),
                            ],
                          );
                        },
                      ),

                      SizedBox(height: 24.h),

                      // Pricing
                      _buildSectionTitle('Pricing'),
                      SizedBox(height: 12.h),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _priceController,
                              label: 'Price (PKR)',
                              keyboardType: TextInputType.number,
                              validator:
                                  (v) => v?.isEmpty ?? true ? 'Required' : null,
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: _buildTextField(
                              controller: _discountController,
                              label: 'Discount (%)',
                              keyboardType: TextInputType.number,
                              hint: '0',
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16.h),
                      if (_discountController.text.isNotEmpty &&
                          double.tryParse(_discountController.text) != null &&
                          double.parse(_discountController.text) > 0)
                        Container(
                          padding: EdgeInsets.all(12.w),
                          decoration: BoxDecoration(
                            color: AppColorsDark.success.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.local_offer,
                                color: AppColorsDark.success,
                                size: 20.sp,
                              ),
                              SizedBox(width: 8.w),
                              Text(
                                'Discounted Price: PKR ${_calculateDiscountedPrice()}',
                                style: AppTextStyles.bodyMedium().copyWith(
                                  color: AppColorsDark.success,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      SizedBox(height: 24.h),

                      // Inventory
                      _buildSectionTitle('Inventory'),
                      SizedBox(height: 12.h),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _quantityController,
                              label: 'Stock Quantity',
                              keyboardType: TextInputType.number,
                              validator:
                                  (v) => v?.isEmpty ?? true ? 'Required' : null,
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: _buildTextField(
                              controller: _unitController,
                              label: 'Unit',
                              hint: 'kg, piece, liter',
                              validator:
                                  (v) => v?.isEmpty ?? true ? 'Required' : null,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16.h),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _minOrderController,
                              label: 'Min Order',
                              keyboardType: TextInputType.number,
                              hint: '1',
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: _buildTextField(
                              controller: _maxOrderController,
                              label: 'Max Order',
                              keyboardType: TextInputType.number,
                              hint: '99',
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 24.h),

                      // Additional Info
                      _buildSectionTitle('Additional Information'),
                      SizedBox(height: 12.h),
                      _buildTextField(
                        controller: _prepTimeController,
                        label: 'Preparation Time (minutes)',
                        keyboardType: TextInputType.number,
                        hint: 'Optional',
                      ),

                      // ✅ ADD THIS SECTION AFTER "Additional Information"
                      SizedBox(height: 24.h),

                      // Variants Toggle
                      _buildSectionTitle('Product Variations (Optional)'),
                      SizedBox(height: 8.h),
                      Text(
                        'Enable this for products with different sizes (e.g., Small, Medium, Large pizza)',
                        style: AppTextStyles.bodySmall().copyWith(
                          color: AppColorsDark.textSecondary,
                        ),
                      ),
                      SizedBox(height: 12.h),
                      SwitchListTile(
                        title: Text(
                          'This product has size variants',
                          style: AppTextStyles.bodyMedium().copyWith(
                            color: AppColorsDark.textPrimary,
                          ),
                        ),
                        value: _hasVariants,
                        onChanged: (value) {
                          setState(() => _hasVariants = value);
                        },
                        contentPadding: EdgeInsets.zero,
                      ),

                      // Variants List (if enabled)
                      if (_hasVariants) ...[
                        SizedBox(height: 16.h),
                        _buildVariantsSection(),
                      ],

                      SizedBox(height: 24.h),

                      // Addons Section
                      _buildSectionTitle('Add-ons / Extra Toppings (Optional)'),
                      SizedBox(height: 8.h),
                      Text(
                        'Add extra items customers can add (e.g., Extra Cheese, Olives)',
                        style: AppTextStyles.bodySmall().copyWith(
                          color: AppColorsDark.textSecondary,
                        ),
                      ),
                      SizedBox(height: 12.h),
                      _buildAddonsSection(),

                      // Properties
                      _buildSectionTitle('Properties'),
                      SizedBox(height: 12.h),
                      _buildCheckboxTile(
                        'Available for Sale',
                        _isAvailable,
                        (v) => setState(() => _isAvailable = v ?? true),
                      ),
                      _buildCheckboxTile(
                        'Featured Product',
                        _isFeatured,
                        (v) => setState(() => _isFeatured = v ?? false),
                      ),
                      _buildCheckboxTile(
                        'Popular Product',
                        _isPopular,
                        (v) => setState(() => _isPopular = v ?? false),
                      ),
                      _buildCheckboxTile(
                        'Vegetarian',
                        _isVegetarian,
                        (v) => setState(() => _isVegetarian = v ?? false),
                      ),
                      _buildCheckboxTile(
                        'Vegan',
                        _isVegan,
                        (v) => setState(() => _isVegan = v ?? false),
                      ),
                      _buildCheckboxTile(
                        'Spicy',
                        _isSpicy,
                        (v) => setState(() => _isSpicy = v ?? false),
                      ),
                      SizedBox(height: 24.h),

                      // Tags
                      _buildSectionTitle('Tags'),
                      SizedBox(height: 12.h),
                      _buildTagsSelector(),
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
          Icon(Icons.inventory, color: AppColorsDark.white, size: 24.sp),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              widget.product == null ? 'Add New Product' : 'Edit Product',
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
      decoration: InputDecoration(labelText: label, hintText: hint),
      validator: validator,
      onChanged: (value) {
        // Recalculate discounted price on discount change
        if (controller == _discountController) {
          setState(() {});
        }
      },
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
        child: const Text('Loading...'),
      );
    }

    return DropdownButtonFormField<String>(
      isExpanded: true,
      value: _selectedCategory.isEmpty ? null : _selectedCategory,
      decoration: const InputDecoration(labelText: 'Category'),
      items:
          state.categories.map((category) {
            return DropdownMenuItem(
              value: category.id,
              child: Text(
                category.name,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            );
          }).toList(),
      onChanged: (value) {
        setState(() => _selectedCategory = value ?? '');
      },
      validator: (v) => v == null ? 'Required' : null,
    );
  }

  // ✅ UPDATE _buildStoreDropdown to handle both cases:

  Widget _buildStoreDropdown(StoresState state) {
    // ✅ If storeId is provided (from Store Products screen), show fixed store
    if (widget.storeId != null && widget.product == null) {
      String storeName = 'Loading...';

      if (state is StoreSingleLoaded) {
        storeName = state.store.name;
      }

      return Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: AppColorsDark.surfaceVariant,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: AppColorsDark.border),
        ),
        child: Row(
          children: [
            Icon(Icons.store, color: AppColorsDark.primary, size: 20.sp),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Store',
                    style: AppTextStyles.bodySmall().copyWith(
                      color: AppColorsDark.textSecondary,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    storeName,
                    style: AppTextStyles.bodyMedium().copyWith(
                      color: AppColorsDark.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // ✅ Normal dropdown for general product management
    if (state is! StoresLoaded) {
      return Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: AppColorsDark.surfaceVariant,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: const Text('Loading...'),
      );
    }

    return DropdownButtonFormField<String>(
      isExpanded: true,
      value: _selectedStore.isEmpty ? null : _selectedStore,
      decoration: const InputDecoration(labelText: 'Store'),
      items:
          state.stores.map((store) {
            return DropdownMenuItem(
              value: store.id,
              child: Text(
                store.name,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            );
          }).toList(),
      onChanged: (value) {
        setState(() => _selectedStore = value ?? '');
      },
      validator: (v) => v == null ? 'Required' : null,
    );
  }

  Widget _buildCheckboxTile(
    String title,
    bool value,
    void Function(bool?) onChanged,
  ) {
    return CheckboxListTile(
      title: Text(
        title,
        style: AppTextStyles.bodyMedium().copyWith(
          color: AppColorsDark.textPrimary,
        ),
      ),
      value: value,
      onChanged: onChanged,
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
      dense: true,
    );
  }

  Widget _buildTagsSelector() {
    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      children:
          _availableTags.map((tag) {
            final isSelected = _selectedTags.contains(tag);
            return FilterChip(
              label: Text(tag),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedTags.add(tag);
                  } else {
                    _selectedTags.remove(tag);
                  }
                });
              },
              selectedColor: AppColorsDark.primary.withOpacity(0.3),
              checkmarkColor: AppColorsDark.primary,
            );
          }).toList(),
    );
  }

  Widget _buildImagesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionTitle('Product Images (${_productImages.length}/5)'),
            if (_productImages.length < 5)
              TextButton.icon(
                onPressed: _pickProductImage,
                icon: Icon(Icons.add_photo_alternate, size: 18.sp),
                label: const Text('Add'),
              ),
          ],
        ),
        SizedBox(height: 12.h),
        if (_productImages.isEmpty)
          Container(
            height: 150.h,
            decoration: BoxDecoration(
              color: AppColorsDark.surfaceVariant,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: AppColorsDark.border),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_photo_alternate,
                    size: 48.sp,
                    color: AppColorsDark.textTertiary,
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Add product images',
                    style: AppTextStyles.bodyMedium().copyWith(
                      color: AppColorsDark.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          SizedBox(
            height: 120.h,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _productImages.length,
              separatorBuilder: (context, index) => SizedBox(width: 8.w),
              itemBuilder: (context, index) {
                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12.r),
                      child: Image.file(
                        _productImages[index],
                        width: 120.w,
                        height: 120.h,
                        fit: BoxFit.cover,
                      ),
                    ),
                    if (index == 0)
                      Positioned(
                        bottom: 4.h,
                        left: 4.w,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 4.h,
                          ),
                          decoration: BoxDecoration(
                            color: AppColorsDark.primary,
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: Text(
                            'Main',
                            style: AppTextStyles.labelSmall().copyWith(
                              color: AppColorsDark.white,
                              fontSize: 10.sp,
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      top: 4.h,
                      right: 4.w,
                      child: InkWell(
                        onTap: () {
                          setState(() => _productImages.removeAt(index));
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
                      : Text(widget.product == null ? 'Add Product' : 'Update'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickProductImage() async {
    if (_productImages.length >= 5) return;

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (pickedFile != null) {
      setState(() {
        _productImages.add(File(pickedFile.path));
      });
    }
  }

  String _calculateDiscountedPrice() {
    final price = double.tryParse(_priceController.text) ?? 0;
    final discount = double.tryParse(_discountController.text) ?? 0;
    final discountedPrice = price - (price * discount / 100);
    return discountedPrice.toStringAsFixed(0);
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

    if (_selectedStore == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a store'),
          backgroundColor: AppColorsDark.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Upload images
      List<String> imageUrls = widget.product?.images ?? [];
      String thumbnailUrl = widget.product?.thumbnail ?? '';

      final productId =
          widget.product?.id ??
          DateTime.now().millisecondsSinceEpoch.toString();

      if (_productImages.isNotEmpty) {
        final publicIds = await ref
            .read(imageUploadProvider.notifier)
            .uploadProductImages(_productImages, productId);

        imageUrls =
            publicIds
                .map(
                  (id) => ref
                      .read(imageUploadProvider.notifier)
                      .getOptimizedUrl(id),
                )
                .toList();

        // First image is thumbnail
        if (publicIds.isNotEmpty) {
          thumbnailUrl = ref
              .read(imageUploadProvider.notifier)
              .getThumbnailUrl(publicIds.first);
        }
      }

      // ✅ CONVERT VARIANTS & ADDONS
      final variants =
          _variants
              .map(
                (v) => ProductVariant(
                  id: v.id,
                  name: v.name,
                  price: v.price,
                  isAvailable: v.isAvailable,
                  sortOrder: v.sortOrder,
                ),
              )
              .toList();

      final addons =
          _addons
              .map(
                (a) => ProductAddon(
                  id: a.id,
                  name: a.name,
                  price: a.price,
                  isAvailable: a.isAvailable,
                  maxQuantity: a.maxQuantity,
                ),
              )
              .toList();

      // Get category and store names
      final categoriesState = ref.read(categoriesProvider);
      final storesState = ref.read(storesProvider);

      String categoryName = '';
      String storeName = '';

      if (categoriesState is CategoriesLoaded) {
        final category = categoriesState.categories.firstWhere(
          (c) => c.id == _selectedCategory,
        );
        categoryName = category.name;
      }

      if (storesState is StoresLoaded) {
        final store = storesState.stores.firstWhere(
          (s) => s.id == _selectedStore,
        );
        storeName = store.name;
      }

      // Calculate values
      final price = double.parse(_priceController.text);
      final discount = double.tryParse(_discountController.text) ?? 0;
      final discountedPrice = price - (price * discount / 100);

      // Create product model
      final product = ProductModel(
        id: productId,
        storeId: _selectedStore,
        storeName: storeName,
        categoryId: _selectedCategory,
        categoryName: categoryName,
        name: _nameController.text.trim(),
        description: _descController.text.trim(),
        shortDescription: _shortDescController.text.trim(),
        images: imageUrls,
        thumbnail: thumbnailUrl,
        price: price,
        originalPrice: double.tryParse(_originalPriceController.text) ?? price,
        discount: discount,
        discountedPrice: discountedPrice,
        unit: _unitController.text.trim(),
        quantity: int.parse(_quantityController.text),
        minOrderQuantity: int.tryParse(_minOrderController.text) ?? 1,
        maxOrderQuantity: int.tryParse(_maxOrderController.text) ?? 99,
        isAvailable: _isAvailable,
        isFeatured: _isFeatured,
        isPopular: _isPopular,
        isVegetarian: _isVegetarian,
        isVegan: _isVegan,
        isSpicy: _isSpicy,
        preparationTime: int.tryParse(_prepTimeController.text) ?? 0,
        tags: _selectedTags,
        createdAt: widget.product?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: 'admin-id', // TODO: Get from auth
        hasVariants: _hasVariants, // ✅ ADD
        variants: variants, // ✅ ADD
        addons: addons, // ✅ ADD
        specialInstructions: null,
      );

      // Save to database
      final success =
          widget.product == null
              ? await ref.read(productsProvider.notifier).addProduct(product)
              : await ref
                  .read(productsProvider.notifier)
                  .updateProduct(product);

      if (success && mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.product == null
                  ? 'Product added successfully'
                  : 'Product updated successfully',
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

  // ✅ ADD THESE METHODS

  Widget _buildVariantsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Existing Variants
        if (_variants.isNotEmpty) ...[
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: AppColorsDark.surfaceVariant,
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Column(
              children:
                  _variants.asMap().entries.map((entry) {
                    final index = entry.key;
                    final variant = entry.value;
                    return _buildVariantItem(variant, index);
                  }).toList(),
            ),
          ),
          SizedBox(height: 12.h),
        ],

        // Add Variant Button
        OutlinedButton.icon(
          onPressed: _showAddVariantDialog,
          icon: Icon(Icons.add, size: 18.sp),
          label: const Text('Add Size Variant'),
          style: OutlinedButton.styleFrom(
            minimumSize: Size(double.infinity, 44.h),
          ),
        ),
      ],
    );
  }

  Widget _buildVariantItem(ProductVariantInput variant, int index) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColorsDark.cardBackground,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: AppColorsDark.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  variant.name,
                  style: AppTextStyles.titleSmall().copyWith(
                    color: AppColorsDark.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'PKR ${variant.price.toInt()}',
                  style: AppTextStyles.bodySmall().copyWith(
                    color: AppColorsDark.primary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.delete, color: AppColorsDark.error, size: 20.sp),
            onPressed: () {
              setState(() => _variants.removeAt(index));
            },
          ),
        ],
      ),
    );
  }

  void _showAddVariantDialog() {
    _variantNameController.clear();
    _variantPriceController.clear();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: AppColorsDark.surface,
            title: Text(
              'Add Size Variant',
              style: AppTextStyles.titleMedium().copyWith(
                color: AppColorsDark.textPrimary,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _variantNameController,
                  style: AppTextStyles.bodyMedium().copyWith(
                    color: AppColorsDark.textPrimary,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Size Name',
                    hintText: 'e.g., Small, Medium, Large',
                  ),
                ),
                SizedBox(height: 16.h),
                TextField(
                  controller: _variantPriceController,
                  keyboardType: TextInputType.number,
                  style: AppTextStyles.bodyMedium().copyWith(
                    color: AppColorsDark.textPrimary,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Additional Price (PKR)',
                    hintText: 'e.g., 0, 200, 400',
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (_variantNameController.text.trim().isNotEmpty &&
                      _variantPriceController.text.trim().isNotEmpty) {
                    setState(() {
                      _variants.add(
                        ProductVariantInput(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          name: _variantNameController.text.trim(),
                          price: double.parse(_variantPriceController.text),
                          isAvailable: true,
                          sortOrder: _variants.length,
                        ),
                      );
                    });
                    Navigator.pop(context);
                  }
                },
                child: const Text('Add'),
              ),
            ],
          ),
    );
  }

  Widget _buildAddonsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Existing Addons
        if (_addons.isNotEmpty) ...[
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: AppColorsDark.surfaceVariant,
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Column(
              children:
                  _addons.asMap().entries.map((entry) {
                    final index = entry.key;
                    final addon = entry.value;
                    return _buildAddonItem(addon, index);
                  }).toList(),
            ),
          ),
          SizedBox(height: 12.h),
        ],

        // Add Addon Button
        OutlinedButton.icon(
          onPressed: _showAddAddonDialog,
          icon: Icon(Icons.add, size: 18.sp),
          label: const Text('Add Extra Topping'),
          style: OutlinedButton.styleFrom(
            minimumSize: Size(double.infinity, 44.h),
          ),
        ),
      ],
    );
  }

  Widget _buildAddonItem(ProductAddonInput addon, int index) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColorsDark.cardBackground,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: AppColorsDark.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  addon.name,
                  style: AppTextStyles.titleSmall().copyWith(
                    color: AppColorsDark.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  '+PKR ${addon.price.toInt()}',
                  style: AppTextStyles.bodySmall().copyWith(
                    color: AppColorsDark.success,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.delete, color: AppColorsDark.error, size: 20.sp),
            onPressed: () {
              setState(() => _addons.removeAt(index));
            },
          ),
        ],
      ),
    );
  }

  void _showAddAddonDialog() {
    _addonNameController.clear();
    _addonPriceController.clear();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: AppColorsDark.surface,
            title: Text(
              'Add Extra Topping',
              style: AppTextStyles.titleMedium().copyWith(
                color: AppColorsDark.textPrimary,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _addonNameController,
                  style: AppTextStyles.bodyMedium().copyWith(
                    color: AppColorsDark.textPrimary,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Topping Name',
                    hintText: 'e.g., Extra Cheese, Olives',
                  ),
                ),
                SizedBox(height: 16.h),
                TextField(
                  controller: _addonPriceController,
                  keyboardType: TextInputType.number,
                  style: AppTextStyles.bodyMedium().copyWith(
                    color: AppColorsDark.textPrimary,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Additional Price (PKR)',
                    hintText: 'e.g., 50, 100, 150',
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (_addonNameController.text.trim().isNotEmpty &&
                      _addonPriceController.text.trim().isNotEmpty) {
                    setState(() {
                      _addons.add(
                        ProductAddonInput(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          name: _addonNameController.text.trim(),
                          price: double.parse(_addonPriceController.text),
                          isAvailable: true,
                          maxQuantity: 1,
                        ),
                      );
                    });
                    Navigator.pop(context);
                  }
                },
                child: const Text('Add'),
              ),
            ],
          ),
    );
  }
}
