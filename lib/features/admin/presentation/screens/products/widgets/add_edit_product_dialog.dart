// lib/features/admin/presentation/screens/products/widgets/add_edit_product_dialog.dart

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
import '../../../../../products/presentation/providers/products_provider.dart';
import '../../../../../products/data/models/product_model.dart';

class AddEditProductDialog extends ConsumerStatefulWidget {
  final ProductModel? product; // null for add, populated for edit

  const AddEditProductDialog({
    super.key,
    this.product,
  });

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
  }

  Future<void> _loadData() async {
    await Future.delayed(const Duration(milliseconds: 500));
    await Future.wait([
      ref.read(categoriesProvider.notifier).getAllCategories(),
      ref.read(storesProvider.notifier).getAllStores(),
    ]);
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
                        validator: (v) =>
                            v?.isEmpty ?? true ? 'Required' : null,
                      ),
                      SizedBox(height: 16.h),
                      _buildTextField(
                        controller: _shortDescController,
                        label: 'Short Description',
                        hint: 'Brief tagline',
                        maxLines: 2,
                        validator: (v) =>
                            v?.isEmpty ?? true ? 'Required' : null,
                      ),
                      SizedBox(height: 16.h),
                      _buildTextField(
                        controller: _descController,
                        label: 'Full Description',
                        hint: 'Detailed description',
                        maxLines: 4,
                        validator: (v) =>
                            v?.isEmpty ?? true ? 'Required' : null,
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
                              validator: (v) =>
                                  v?.isEmpty ?? true ? 'Required' : null,
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
                              validator: (v) =>
                                  v?.isEmpty ?? true ? 'Required' : null,
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: _buildTextField(
                              controller: _unitController,
                              label: 'Unit',
                              hint: 'kg, piece, liter',
                              validator: (v) =>
                                  v?.isEmpty ?? true ? 'Required' : null,
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
                      SizedBox(height: 24.h),

                      // Properties
                      _buildSectionTitle('Properties'),
                      SizedBox(height: 12.h),
                      _buildCheckboxTile('Available for Sale', _isAvailable,
                          (v) => setState(() => _isAvailable = v ?? true)),
                      _buildCheckboxTile('Featured Product', _isFeatured,
                          (v) => setState(() => _isFeatured = v ?? false)),
                      _buildCheckboxTile('Popular Product', _isPopular,
                          (v) => setState(() => _isPopular = v ?? false)),
                      _buildCheckboxTile('Vegetarian', _isVegetarian,
                          (v) => setState(() => _isVegetarian = v ?? false)),
                      _buildCheckboxTile('Vegan', _isVegan,
                          (v) => setState(() => _isVegan = v ?? false)),
                      _buildCheckboxTile('Spicy', _isSpicy,
                          (v) => setState(() => _isSpicy = v ?? false)),
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
          Icon(
            Icons.inventory,
            color: AppColorsDark.white,
            size: 24.sp,
          ),
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
              icon: Icon(Icons.close, color: AppColorsDark.white),
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
        child: Text('Loading...'),
      );
    }

    return DropdownButtonFormField<String>(isExpanded: true,
      value: _selectedCategory.isEmpty ? null : _selectedCategory,
      decoration: InputDecoration(labelText: 'Category'),
      items: state.categories.map((category) {
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

  Widget _buildStoreDropdown(StoresState state) {
    if (state is! StoresLoaded) {
      return Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: AppColorsDark.surfaceVariant,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Text('Loading...'),
      );
    }

    return DropdownButtonFormField<String>(isExpanded: true,
      value: _selectedStore.isEmpty ? null : _selectedStore,
      decoration: InputDecoration(labelText: 'Store'),
      items: state.stores.map((store) {
        return DropdownMenuItem(
          value: store.id,
          child:Text(
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
      children: _availableTags.map((tag) {
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
                          decoration: BoxDecoration(
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
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColorsDark.border, width: 1),
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
                      child: CircularProgressIndicator(
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
        SnackBar(
          content: Text('Please fill all required fields'),
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

      final productId = widget.product?.id ??
          DateTime.now().millisecondsSinceEpoch.toString();

      if (_productImages.isNotEmpty) {
        final publicIds = await ref
            .read(imageUploadProvider.notifier)
            .uploadProductImages(_productImages, productId);

        imageUrls = publicIds
            .map((id) =>
                ref.read(imageUploadProvider.notifier).getOptimizedUrl(id))
            .toList();

        // First image is thumbnail
        if (publicIds.isNotEmpty) {
          thumbnailUrl = ref
              .read(imageUploadProvider.notifier)
              .getThumbnailUrl(publicIds.first);
        }
      }

      // Get category and store names
      final categoriesState = ref.read(categoriesProvider);
      final storesState = ref.read(storesProvider);

      String categoryName = '';
      String storeName = '';

      if (categoriesState is CategoriesLoaded) {
        final category = categoriesState.categories
            .firstWhere((c) => c.id == _selectedCategory);
        categoryName = category.name;
      }

      if (storesState is StoresLoaded) {
        final store =
            storesState.stores.firstWhere((s) => s.id == _selectedStore);
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
      );

      // Save to database
      final success = widget.product == null
          ? await ref.read(productsProvider.notifier).addProduct(product)
          : await ref.read(productsProvider.notifier).updateProduct(product);

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
}