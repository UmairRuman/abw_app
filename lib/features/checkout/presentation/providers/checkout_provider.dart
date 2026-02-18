// lib/features/checkout/presentation/providers/checkout_provider.dart
// FULL REPLACEMENT:

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/checkout_model.dart';
import '../../../cart/presentation/providers/cart_provider.dart';
import '../../../addresses/presentation/providers/addresses_provider.dart';
import '../../../addresses/data/models/address_model.dart';
import '../../../stores/data/models/store_model.dart';

// States
abstract class CheckoutState {}

class CheckoutInitial extends CheckoutState {}

class CheckoutLoading extends CheckoutState {}

class CheckoutLoaded extends CheckoutState {
  final CheckoutModel checkout;
  CheckoutLoaded(this.checkout);
}

class CheckoutError extends CheckoutState {
  final String message;
  CheckoutError(this.message);
}

// Notifier
class CheckoutNotifier extends StateNotifier<CheckoutState> {
  final Ref ref;

  CheckoutNotifier(this.ref) : super(CheckoutInitial());

  Future<void> prepareCheckout(String userId) async {
    state = CheckoutLoading();

    try {
      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .get();

      if (!userDoc.exists) {
        state = CheckoutError('User not found');
        return;
      }

      final userData = userDoc.data()!;
      final isPhoneVerified = userData['isPhoneVerified'] as bool? ?? false;
      final phone = userData['phone'] as String?;
      // ✅ CHECK IF PHONE EXISTS
      if (phone == null || phone.isEmpty) {
        state = CheckoutError('phone_missing'); // ✅ NEW ERROR CODE
        return;
      }

      if (!isPhoneVerified) {
        state = CheckoutError('phone_not_verified'); // ✅ SPECIAL ERROR CODE
        return;
      }
      // ── Step 1: Get cart ──────────────────────────
      final cartState = ref.read(cartProvider);
      if (cartState is! CartLoaded || cartState.cart.items.isEmpty) {
        state = CheckoutError('Your cart is empty');
        return;
      }
      final cart = cartState.cart;

      if (cart.storeId == null) {
        state = CheckoutError('Invalid cart: no store found');
        return;
      }

      // ── Step 2: Load store DIRECTLY from Firestore ─
      // ✅ Don't rely on storesProvider being loaded
      StoreModel? store;
      try {
        final doc =
            await FirebaseFirestore.instance
                .collection('stores')
                .doc(cart.storeId)
                .get();

        if (!doc.exists || doc.data() == null) {
          state = CheckoutError('Store not found');
          return;
        }
        store = StoreModel.fromJson({'id': doc.id, ...doc.data()!});
      } catch (e) {
        state = CheckoutError('Failed to load store details: $e');
        return;
      }

      // ── Step 3: Load addresses if not loaded ───────
      final addressesState = ref.read(addressesProvider);
      if (addressesState is! AddressesLoaded) {
        await ref.read(addressesProvider.notifier).loadUserAddresses(userId);
      }

      // ── Step 4: Get delivery address ───────────────
      final freshAddressesState = ref.read(addressesProvider);
      AddressModel? deliveryAddress;

      if (freshAddressesState is AddressesLoaded &&
          freshAddressesState.addresses.isNotEmpty) {
        // Try default address first
        try {
          deliveryAddress = freshAddressesState.addresses.firstWhere(
            (a) => a.isDefault,
          );
        } catch (_) {
          // Fall back to first address
          deliveryAddress = freshAddressesState.addresses.first;
        }
      }

      if (deliveryAddress == null) {
        state = CheckoutError('Please add a delivery address first');
        return;
      }

      // ── Step 5: Calculate totals ───────────────────
      final subtotal = cart.total;
      final deliveryFee = store.deliveryFee;
      final total = subtotal + deliveryFee;

      // ── Step 6: Build checkout ─────────────────────
      final checkout = CheckoutModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        storeId: cart.storeId!,
        storeName: cart.storeName ?? store.name,
        items: cart.items,
        deliveryAddress: deliveryAddress,
        deliveryTimeSlot: 'ASAP',
        specialInstructions: null,
        subtotal: subtotal,
        deliveryFee: deliveryFee,
        total: total,
        createdAt: DateTime.now(),
      );

      state = CheckoutLoaded(checkout);
    } catch (e) {
      state = CheckoutError('Unexpected error: ${e.toString()}');
    }
  }

  // Update delivery address
  void updateDeliveryAddress(AddressModel address) {
    if (state is CheckoutLoaded) {
      final current = (state as CheckoutLoaded).checkout;
      state = CheckoutLoaded(current.copyWith(deliveryAddress: address));
    }
  }

  // Update special instructions
  void updateSpecialInstructions(String? instructions) {
    if (state is CheckoutLoaded) {
      final current = (state as CheckoutLoaded).checkout;
      state = CheckoutLoaded(
        current.copyWith(specialInstructions: instructions),
      );
    }
  }

  // Calculate estimated delivery time
  DateTime calculateEstimatedDeliveryTime() {
    // Default 30 mins if we can't read store data
    return DateTime.now().add(const Duration(minutes: 30));
  }

  // Get delivery time range string
  String getDeliveryTimeRange() {
    if (state is CheckoutLoaded) {
      // You can store deliveryTime in checkout if needed
      // For now return a reasonable default
      return '25-35 mins';
    }
    return '25-35 mins';
  }

  // Reset checkout
  void reset() {
    state = CheckoutInitial();
  }
}

// Provider
final checkoutProvider = StateNotifierProvider<CheckoutNotifier, CheckoutState>(
  (ref) => CheckoutNotifier(ref),
);
