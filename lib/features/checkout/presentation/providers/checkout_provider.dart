// lib/features/checkout/presentation/providers/checkout_provider.dart

import 'dart:developer';

import 'package:abw_app/core/services/notification_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer' as dev;
import '../../data/models/checkout_model.dart';
import '../../../cart/presentation/providers/cart_provider.dart';
import '../../../addresses/presentation/providers/addresses_provider.dart';
import '../../../addresses/data/models/address_model.dart';
import '../../../stores/data/models/store_model.dart';
import '../../../../core/services/location_service.dart';

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

  Future<String?> placeOrder({
    required String userId,
    required String userName,
    required String userPhone,
    required CheckoutModel checkout,
    required String paymentMethod,
    String? paymentProofUrl,
    String? paymentTransactionId,
  }) async {
    state = CheckoutLoading();

    try {
      final orderId = DateTime.now().millisecondsSinceEpoch.toString();

      // ── ✅ FIX: Fetch store coordinates for pickup lat/lng ────────────────
      // prepareCheckout fetched the store but didn't pass coords to placeOrder.
      // We fetch them again here so every order gets pickup + delivery coords.
      double? pickupLat;
      double? pickupLng;
      double distance = 0.0;

      try {
        final storeDoc =
            await FirebaseFirestore.instance
                .collection('stores')
                .doc(checkout.storeId)
                .get();

        if (storeDoc.exists && storeDoc.data() != null) {
          final data = storeDoc.data()!;
          pickupLat = (data['latitude'] as num?)?.toDouble();
          pickupLng = (data['longitude'] as num?)?.toDouble();

          // ✅ Recalculate distance now that we have all 4 coords
          final deliveryLat = checkout.deliveryAddress.latitude;
          final deliveryLng = checkout.deliveryAddress.longitude;

          if (pickupLat != null &&
              pickupLng != null &&
              pickupLat != 0.0 &&
              pickupLng != 0.0 &&
              deliveryLat != 0.0 &&
              deliveryLng != 0.0) {
            distance = LocationService.calculateDistance(
              startLat: pickupLat,
              startLng: pickupLng,
              endLat: deliveryLat,
              endLng: deliveryLng,
            );
            dev.log('✅ Distance: ${LocationService.formatDistance(distance)}');
          }
        }
      } catch (e) {
        dev.log('⚠️ Could not fetch store coords for order: $e');
      }

      final orderData = {
        'id': orderId,
        'userId': userId,
        'userName': userName,
        'userPhone': userPhone,
        'storeId': checkout.storeId,
        'storeName': checkout.storeName,
        'items':
            checkout.items
                .map(
                  (item) => {
                    'productId': item.productId,
                    'productName': item.productName,
                    'productImage': item.productImage,
                    'quantity': item.quantity,
                    'price': item.discountedPrice,
                    'total': item.discountedPrice * item.quantity,
                    'selectedVariant':
                        item.selectedVariant != null
                            ? {
                              'id': item.selectedVariant!.id,
                              'name': item.selectedVariant!.name,
                              'price': item.selectedVariant!.price,
                            }
                            : null,
                    'selectedAddons':
                        item.selectedAddons
                            .map(
                              (a) => {
                                'id': a.id,
                                'name': a.name,
                                'price': a.price,
                              },
                            )
                            .toList(),
                    'specialInstructions': item.specialInstructions,
                  },
                )
                .toList(),
        'deliveryAddress': {
          'addressLine1': checkout.deliveryAddress.addressLine1,
          'addressLine2': checkout.deliveryAddress.addressLine2,
          'area': checkout.deliveryAddress.area,
          'city': checkout.deliveryAddress.city,
          'latitude': checkout.deliveryAddress.latitude,
          'longitude': checkout.deliveryAddress.longitude,
        },

        // ✅ FIX: Top-level coordinate fields — these are what OrderMapWidget reads.
        // Previously these were never written, so the map always showed
        // "Location Not Available" even when coordinates existed.
        'pickupLatitude': pickupLat,
        'pickupLongitude': pickupLng,
        'deliveryLatitude':
            checkout.deliveryAddress.latitude != 0.0
                ? checkout.deliveryAddress.latitude
                : null,
        'deliveryLongitude':
            checkout.deliveryAddress.longitude != 0.0
                ? checkout.deliveryAddress.longitude
                : null,
        'distance': distance > 0 ? distance : null,

        'subtotal': checkout.subtotal,
        'deliveryFee': checkout.deliveryFee,
        'total': checkout.total,
        'discount': 0.0,
        'specialInstructions': checkout.specialInstructions,
        'paymentMethod': paymentMethod,
        'paymentStatus': paymentMethod == 'cod' ? 'pending' : 'completed',
        'paymentProofUrl': paymentProofUrl,
        'paymentTransactionId': paymentTransactionId,
        'status': 'pending',
        'statusHistory': [
          {
            'status': 'pending',
            'timestamp': Timestamp.now(),
            'note': 'Order placed',
            'updatedBy': 'customer',
          },
        ],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .set(orderData);

      dev.log('✅ Order created: $orderId');
      dev.log('   pickup: $pickupLat, $pickupLng');
      dev.log(
        '   delivery: ${checkout.deliveryAddress.latitude}, ${checkout.deliveryAddress.longitude}',
      );
      dev.log('   distance: $distance');

      await NotificationService.sendNewOrderNotificationToAdmin(
        orderId: orderId,
        customerName: userName,
        total: checkout.total,
        paymentMethod: paymentMethod,
        paymentProofUrl: paymentProofUrl,
      );

      log('✅ Admin notifications sent');

      await FirebaseFirestore.instance.collection('carts').doc(userId).delete();
      log('✅ Cart cleared');

      state = CheckoutInitial();
      return orderId;
    } catch (e) {
      dev.log('❌ Error placing order: $e');
      state = CheckoutError(e.toString());
      return null;
    }
  }

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

      if (phone == null || phone.isEmpty) {
        state = CheckoutError('phone_missing');
        return;
      }

      if (!isPhoneVerified) {
        state = CheckoutError('phone_not_verified');
        return;
      }

      // ── Step 1: Get cart ───────────────────────────────────────────────────
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

      // ── Step 2: Load store ─────────────────────────────────────────────────
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
        dev.log('✅ Store loaded: ${store.name}');
        dev.log('✅ Store location: ${store.latitude}, ${store.longitude}');
        dev.log('✅ Store delivery fee: PKR ${store.deliveryFee}');
      } catch (e) {
        state = CheckoutError('Failed to load store details: $e');
        return;
      }

      // ── Step 3: Load addresses ─────────────────────────────────────────────
      final addressesState = ref.read(addressesProvider);
      if (addressesState is! AddressesLoaded) {
        await ref.read(addressesProvider.notifier).loadUserAddresses(userId);
      }

      // ── Step 4: Get delivery address ───────────────────────────────────────
      final freshAddressesState = ref.read(addressesProvider);
      AddressModel? deliveryAddress;

      if (freshAddressesState is AddressesLoaded &&
          freshAddressesState.addresses.isNotEmpty) {
        try {
          deliveryAddress = freshAddressesState.addresses.firstWhere(
            (a) => a.isDefault,
          );
        } catch (_) {
          deliveryAddress = freshAddressesState.addresses.first;
        }
      }

      if (deliveryAddress == null) {
        state = CheckoutError('Please add a delivery address first');
        return;
      }

      // ── Step 5: Calculate distance ─────────────────────────────────────────
      double distance = 0.0;
      if (store.latitude != 0.0 &&
          store.longitude != 0.0 &&
          deliveryAddress.latitude != 0.0 &&
          deliveryAddress.longitude != 0.0) {
        distance = LocationService.calculateDistance(
          startLat: store.latitude,
          startLng: store.longitude,
          endLat: deliveryAddress.latitude,
          endLng: deliveryAddress.longitude,
        );
        dev.log(
          '✅ Distance calculated: ${LocationService.formatDistance(distance)}',
        );
      } else {
        dev.log('⚠️ Missing coordinates, distance set to 0');
      }

      // ── Step 6: Calculate totals ───────────────────────────────────────────
      final double subtotal = cart.subtotal;
      final double deliveryFee = store.deliveryFee;
      final double total = subtotal + deliveryFee;

      dev.log(
        '💰 Checkout totals → subtotal: $subtotal + delivery: $deliveryFee = $total',
      );

      // ── Step 7: Build checkout model ──────────────────────────────────────
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

  void updateDeliveryAddress(AddressModel address) {
    if (state is CheckoutLoaded) {
      final current = (state as CheckoutLoaded).checkout;
      state = CheckoutLoaded(current.copyWith(deliveryAddress: address));
    }
  }

  void updateSpecialInstructions(String? instructions) {
    if (state is CheckoutLoaded) {
      final current = (state as CheckoutLoaded).checkout;
      state = CheckoutLoaded(
        current.copyWith(specialInstructions: instructions),
      );
    }
  }

  DateTime calculateEstimatedDeliveryTime() {
    return DateTime.now().add(const Duration(minutes: 30));
  }

  String getDeliveryTimeRange() => '25-35 mins';

  void reset() {
    state = CheckoutInitial();
  }
}

// Provider
final checkoutProvider = StateNotifierProvider<CheckoutNotifier, CheckoutState>(
  (ref) => CheckoutNotifier(ref),
);
