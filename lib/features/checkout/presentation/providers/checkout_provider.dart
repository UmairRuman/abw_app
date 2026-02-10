// lib/features/checkout/presentation/providers/checkout_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/checkout_model.dart';
import '../../../cart/presentation/providers/cart_provider.dart';
import '../../../addresses/presentation/providers/addresses_provider.dart';
import '../../../stores/presentation/providers/stores_provider.dart';
import '../../../addresses/data/models/address_model.dart';

// Checkout State
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

// Checkout Provider
class CheckoutNotifier extends StateNotifier<CheckoutState> {
  final Ref ref;

  CheckoutNotifier(this.ref) : super(CheckoutInitial());

  // Prepare checkout from cart
  Future<void> prepareCheckout(String userId) async {
    state = CheckoutLoading();

    try {
      // Get cart
      final cartState = ref.read(cartProvider);
      if (cartState is! CartLoaded || cartState.cart.items.isEmpty) {
        state = CheckoutError('Cart is empty');
        return;
      }

      final cart = cartState.cart;

      // Get store details for delivery fee and times
      final storesState = ref.read(storesProvider);
      if (storesState is! StoresLoaded) {
        state = CheckoutError('Unable to load store details');
        return;
      }

      final store = storesState.stores.firstWhere(
        (s) => s.id == cart.storeId,
        orElse: () => throw Exception('Store not found'),
      );

      // Get default address or first address
      final addressesState = ref.read(addressesProvider);
      AddressModel? deliveryAddress;

      if (addressesState is AddressesLoaded) {
        // Try to get default address
        try {
          deliveryAddress =
              addressesState.addresses.firstWhere((a) => a.isDefault)
                  as AddressModel;
        } catch (e) {
          // If no default, get first address
          if (addressesState.addresses.isNotEmpty) {
            deliveryAddress = addressesState.addresses.first as AddressModel;
          }
        }
      }

      if (deliveryAddress == null) {
        state = CheckoutError('Please add a delivery address');
        return;
      }

      // Calculate totals
      final subtotal = cart.total;
      final deliveryFee = store.deliveryFee;
      final total = subtotal + deliveryFee;

      // Create checkout
      final checkout = CheckoutModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        storeId: cart.storeId!,
        storeName: cart.storeName!,
        items: cart.items,
        deliveryAddress: deliveryAddress,
        deliveryTimeSlot: 'ASAP', // Not used, just placeholder
        specialInstructions: null,
        subtotal: subtotal,
        deliveryFee: deliveryFee,
        total: total,
        createdAt: DateTime.now(),
      );

      state = CheckoutLoaded(checkout);
    } catch (e) {
      state = CheckoutError(e.toString());
    }
  }

  // Update delivery address
  void updateDeliveryAddress(AddressModel address) {
    if (state is CheckoutLoaded) {
      final currentCheckout = (state as CheckoutLoaded).checkout;
      final updatedCheckout = currentCheckout.copyWith(
        deliveryAddress: address,
      );
      state = CheckoutLoaded(updatedCheckout);
    }
  }

  // Update special instructions
  void updateSpecialInstructions(String? instructions) {
    if (state is CheckoutLoaded) {
      final currentCheckout = (state as CheckoutLoaded).checkout;
      final updatedCheckout = currentCheckout.copyWith(
        specialInstructions: instructions,
      );
      state = CheckoutLoaded(updatedCheckout);
    }
  }

  // Calculate estimated delivery time
  DateTime calculateEstimatedDeliveryTime() {
    if (state is CheckoutLoaded) {
      final checkout = (state as CheckoutLoaded).checkout;

      // Get store
      final storesState = ref.read(storesProvider);
      if (storesState is StoresLoaded) {
        final store = storesState.stores.firstWhere(
          (s) => s.id == checkout.storeId,
        );

        // Current time + store delivery time
        return DateTime.now().add(Duration(minutes: store.deliveryTime));
      }
    }
    return DateTime.now().add(Duration(minutes: 30)); // Default 30 mins
  }

  // Get delivery time range (for display)
  String getDeliveryTimeRange() {
    if (state is CheckoutLoaded) {
      final checkout = (state as CheckoutLoaded).checkout;

      // Get store
      final storesState = ref.read(storesProvider);
      if (storesState is StoresLoaded) {
        final store = storesState.stores.firstWhere(
          (s) => s.id == checkout.storeId,
        );

        final minTime = store.deliveryTime - 5; // e.g., 25 mins
        final maxTime = store.deliveryTime + 5; // e.g., 35 mins

        return '$minTime-$maxTime mins';
      }
    }
    return '30-40 mins'; // Default
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
