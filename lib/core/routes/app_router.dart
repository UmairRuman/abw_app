// lib/core/routes/app_router.dart

import 'dart:developer';

import 'package:abw_app/features/admin/presentation/screens/analytics/analytics_screen.dart';
import 'package:abw_app/features/admin/presentation/screens/riders/rider_details_screen.dart';
import 'package:abw_app/features/admin/presentation/screens/riders/riders_list_screen.dart';
import 'package:abw_app/features/auth/presentation/screens/location/location_capture_screen.dart';
import 'package:abw_app/features/auth/presentation/screens/phone_verification/phone_confirm_screen.dart';
import 'package:abw_app/features/auth/presentation/screens/phone_verification/phone_input_screen.dart';
import 'package:abw_app/features/auth/presentation/screens/phone_verification/phone_verification_screen.dart';
import 'package:abw_app/features/auth/presentation/screens/signup/admin_signup_screen.dart';
import 'package:abw_app/features/customer/presentation/screens/location/location_picker_screen.dart';
import 'package:abw_app/features/customer/presentation/screens/profile/customer_edit_profile_screen.dart';
import 'package:abw_app/features/rider/presentation/screens/main/rider_main_screen.dart';
import 'package:abw_app/features/rider/presentation/screens/orders/rider_order_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/screens/forgot_password/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/login/login_screen.dart';
import '../../features/auth/presentation/screens/rider_request/pending_approval_screen.dart';
import '../../features/auth/presentation/screens/signup/customer_signup_screen.dart';
import '../../features/auth/presentation/screens/signup/rider_signup_screen.dart';
import '../../features/auth/presentation/screens/splash/splash_screen.dart';

// Customer
import '../../features/customer/presentation/screens/home/customer_home_screen.dart';
import '../../features/customer/presentation/screens/store/store_details_screen.dart';
import '../../features/customer/presentation/screens/search/search_screen.dart';
import '../../features/customer/presentation/screens/cart/cart_screen.dart';
import '../../features/customer/presentation/screens/profile/customer_profile_screen.dart';
import '../../features/customer/presentation/screens/addresses/addresses_screen.dart';

// Checkout & Payment
import '../../features/checkout/presentation/screens/checkout_screen.dart';
import '../../features/payment/presentation/screens/payment_selection_screen.dart';
import '../../features/payment/presentation/screens/cod_confirmation_screen.dart';
import '../../features/payment/presentation/screens/jazzcash_payment_screen.dart';
import '../../features/payment/presentation/screens/easypaisa_payment_screen.dart';
import '../../features/payment/presentation/screens/bank_transfer_payment_screen.dart';
import '../../features/payment/presentation/screens/order_confirmation_screen.dart';

// Orders - Customer
import '../../features/orders/presentation/screens/customer/active_orders_screen.dart';
import '../../features/orders/presentation/screens/customer/order_history_screen.dart';
import '../../features/orders/presentation/screens/customer/order_details_screen.dart';

// Admin
import '../../features/admin/presentation/screens/main/admin_main_screen.dart';
import '../../features/admin/presentation/screens/products/product_management_screen.dart';
import '../../features/admin/presentation/screens/users/users_list_screen.dart';
import '../../features/admin/presentation/screens/orders/admin_orders_screen.dart';
import '../../features/admin/presentation/screens/orders/admin_order_details_screen.dart';

final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    observers: [routeObserver],
    initialLocation: '/splash',
    debugLogDiagnostics: true,
    routes: [
      // ============================================================
      // SPLASH
      // ============================================================
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // ============================================================
      // AUTH ROUTES
      // ============================================================
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup/customer',
        name: 'signup-customer',
        builder: (context, state) => const CustomerSignupScreen(),
      ),
      GoRoute(
        path: '/signup/admin',
        name: 'signup-admin',
        builder: (context, state) => const AdminSignupScreen(),
      ),
      GoRoute(
        path: '/signup/rider',
        name: 'signup-rider',
        builder: (context, state) => const RiderSignupScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        name: 'forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/rider/pending',
        name: 'rider-pending',
        builder: (context, state) => const PendingApprovalScreen(),
      ),

      // ============================================================
      // CUSTOMER ROUTES
      // ============================================================
      GoRoute(
        path: '/customer/home',
        name: 'customer-home',
        builder: (context, state) => const CustomerHomeScreen(),
      ),
      GoRoute(
        path: '/customer/store/:id',
        name: 'store-details',
        builder: (context, state) {
          final storeId = state.pathParameters['id'] ?? '';
          return StoreDetailsScreen(storeId: storeId);
        },
      ),
      GoRoute(
        path: '/customer/search',
        name: 'search',
        builder: (context, state) => const SearchScreen(),
      ),
      GoRoute(
        path: '/customer/cart',
        name: 'cart',
        builder: (context, state) => const CartScreen(),
      ),
      GoRoute(
        path: '/customer/profile',
        name: 'profile',
        builder: (context, state) => const CustomerProfileScreen(),
      ),
      GoRoute(
        path: '/customer/addresses',
        name: 'addresses',
        builder: (context, state) {
          // ✅ Support selection mode via extra param
          final extra = state.extra as Map<String, dynamic>?;
          final isSelectionMode = extra?['isSelectionMode'] as bool? ?? false;
          return const AddressesScreen();
        },
      ),

      // ============================================================
      // CHECKOUT ROUTES
      // ============================================================
      GoRoute(
        path: '/customer/checkout',
        name: 'checkout',
        builder: (context, state) => const CheckoutScreen(),
      ),

      // ============================================================
      // PAYMENT ROUTES
      // ============================================================
      GoRoute(
        path: '/customer/payment',
        name: 'payment-selection',
        builder: (context, state) => const PaymentSelectionScreen(),
      ),
      GoRoute(
        path: '/customer/payment/cod',
        name: 'payment-cod',
        builder: (context, state) => const CodConfirmationScreen(),
      ),
      GoRoute(
        path: '/customer/payment/jazzcash',
        name: 'payment-jazzcash',
        builder: (context, state) => const JazzcashPaymentScreen(),
      ),
      GoRoute(
        path: '/customer/payment/easypaisa',
        name: 'payment-easypaisa',
        builder: (context, state) => const EasypaisaPaymentScreen(),
      ),
      GoRoute(
        path: '/customer/payment/bank',
        name: 'payment-bank',
        builder: (context, state) => const BankTransferPaymentScreen(),
      ),
      GoRoute(
        path: '/customer/payment/confirmation/:orderId',
        name: 'order-confirmation',
        builder: (context, state) {
          final orderId = state.pathParameters['orderId'] ?? '';
          return OrderConfirmationScreen(orderId: orderId);
        },
      ),

      GoRoute(
        path: '/verify-phone',
        name: 'verify-phone',
        builder: (context, state) {
          // ✅ NOW ONLY NEEDS USER ID
          final userId = state.extra as String?;

          if (userId == null) {
            return const Scaffold(
              body: Center(child: Text('Error: User ID not provided')),
            );
          }

          return PhoneVerificationScreen(userId: userId);
        },
      ),

      GoRoute(
        path: '/phone-confirm',
        name: 'phone-confirm',
        builder: (context, state) {
          final userId = state.extra as String?;
          if (userId == null) {
            return const Scaffold(
              body: Center(child: Text('Error: User ID missing')),
            );
          }
          return PhoneConfirmScreen(userId: userId);
        },
      ),

      GoRoute(
        path: '/phone-input',
        name: 'phone-input',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;

          if (extra == null || extra['userId'] == null) {
            return const Scaffold(
              body: Center(child: Text('Error: User ID not provided')),
            );
          }

          return PhoneInputScreen(
            userId: extra['userId'] as String,
            currentPhone: extra['currentPhone'] as String?,
          );
        },
      ),
      // ============================================================
      // ORDER ROUTES - CUSTOMER
      // ============================================================
      GoRoute(
        path: '/customer/orders/active',
        name: 'active-orders',
        builder: (context, state) => const ActiveOrdersScreen(),
      ),
      GoRoute(
        path: '/customer/orders/history',
        name: 'order-history',
        builder: (context, state) => const OrderHistoryScreen(),
      ),
      GoRoute(
        path: '/customer/orders/:orderId',
        name: 'order-details',
        builder: (context, state) {
          final orderId = state.pathParameters['orderId'] ?? '';
          return OrderDetailsScreen(orderId: orderId);
        },
      ),

      GoRoute(
        path: '/customer/edit-profile',
        name: 'edit-profile',
        builder: (context, state) => const CustomerEditProfileScreen(),
      ),

      // ============================================================
      // ADMIN ROUTES
      // ============================================================
      GoRoute(
        path: '/admin/analytics',
        name: 'admin-analytics',
        builder: (context, state) => const AnalyticsScreen(),
      ),
      GoRoute(
        path: '/admin/dashboard',
        name: 'admin-dashboard',
        builder: (context, state) => const AdminMainScreen(),
      ),
      GoRoute(
        path: '/admin/products',
        name: 'admin-products',
        builder: (context, state) => const ProductManagementScreen(),
      ),
      GoRoute(
        path: '/admin/users',
        name: 'admin-users',
        builder: (context, state) => const UsersListScreen(),
      ),
      GoRoute(
        path: '/admin/orders',
        name: 'admin-orders',
        builder: (context, state) => const AdminOrdersScreen(),
      ),
      GoRoute(
        path: '/admin/orders/:orderId',
        name: 'admin-order-details',
        builder: (context, state) {
          final orderId = state.pathParameters['orderId'] ?? '';
          return AdminOrderDetailsScreen(orderId: orderId);
        },
      ),

      // ============================================================
      // RIDER ROUTES
      // ============================================================
      // REPLACE the rider-dashboard route:
      GoRoute(
        path: '/rider/dashboard',
        name: 'rider-dashboard',
        builder: (context, state) => const RiderMainScreen(),
      ),

      // ── Admin Riders ────────────────────────────────────
      GoRoute(
        path: '/admin/riders',
        name: 'admin-riders',
        builder: (context, state) => const RidersListScreen(),
      ),

      GoRoute(
        path: '/admin/riders/pending',
        name: 'admin-riders-pending',
        builder: (context, state) => const RidersListScreen(),
      ),

      GoRoute(
        path: '/admin/riders/:riderId',
        name: 'admin-rider-details',
        builder: (context, state) {
          final riderId = state.pathParameters['riderId'] ?? '';
          return RiderDetailsScreen(riderId: riderId);
        },
      ),

      // ✅ LOCATION CAPTURE ROUTE
      GoRoute(
        path: '/location-capture',
        name: 'location-capture',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final userId = extra?['userId'] as String?;
          final role = extra?['role'] as String? ?? 'customer';

          if (userId == null) {
            return const Scaffold(
              body: Center(child: Text('Error: User ID missing')),
            );
          }

          return LocationCaptureScreen(userId: userId, role: role);
        },
      ),

      GoRoute(
        path: '/location-picker',
        name: 'location-picker',
        builder: (context, state) => const LocationPickerScreen(),
      ),

      // ✅ RIDER ORDER DETAILS ROUTE
      GoRoute(
        path: '/rider/orders/:orderId',
        name: 'rider-order-details',
        builder: (context, state) {
          final orderId = state.pathParameters['orderId'];

          if (orderId == null) {
            return const Scaffold(
              body: Center(child: Text('Error: Order ID missing')),
            );
          }

          return RiderOrderDetailsScreen(orderId: orderId);
        },
      ),
      // ============================================================
      // ERROR ROUTE
      // ============================================================
      GoRoute(
        path: '/error',
        name: 'error',
        builder:
            (context, state) => Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Page Not Found',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => context.go('/login'),
                      child: const Text('Go to Login'),
                    ),
                  ],
                ),
              ),
            ),
      ),
    ],

    errorBuilder:
        (context, state) => Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Something went wrong',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text('Error: ${state.error}'),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => context.go('/login'),
                  child: const Text('Go to Login'),
                ),
              ],
            ),
          ),
        ),
  );
});

// ============================================================
// NAVIGATION EXTENSIONS
// ============================================================

// ADD AT BOTTOM of app_router.dart:

extension NavigationExtensions on BuildContext {
  // ── Auth ──────────────────────────────────────────────
  void goToLogin() => go('/login');
  void goToCustomerSignup() => go('/signup/customer');
  void goToRiderSignup() => go('/signup/rider');
  void goToForgotPassword() => go('/forgot-password');

  // ── Customer ──────────────────────────────────────────
  void goToCustomerHome() => go('/customer/home');
  void goToStoreDetails(String storeId) => go('/customer/store/$storeId');
  void goToSearch() => go('/customer/search');
  void goToCart() => go('/customer/cart');
  void goToProfile() => go('/customer/profile');
  void goToAddresses() => go('/customer/addresses');

  // ✅ NEW - Checkout & Payment
  void goToCheckout() => go('/customer/checkout');
  void goToPaymentSelection() => go('/customer/payment');
  void goToPaymentCOD() => go('/customer/payment/cod');
  void goToPaymentJazzcash() => go('/customer/payment/jazzcash');
  void goToPaymentEasypaisa() => go('/customer/payment/easypaisa');
  void goToPaymentBank() => go('/customer/payment/bank');
  void goToOrderConfirmation(String orderId) =>
      go('/customer/payment/confirmation/$orderId');

  // ✅ NEW - Orders
  void goToActiveOrders() => go('/customer/orders/active');
  void goToOrderHistory() => go('/customer/orders/history');
  void goToOrderDetails(String orderId) => go('/customer/orders/$orderId');

  // ── Admin ─────────────────────────────────────────────
  void goToAdminDashboard() => go('/admin/dashboard');
  void goToAdminProducts() => go('/admin/products');
  void goToAdminUsers() => go('/admin/users');

  // ✅ NEW - Admin Orders
  void goToAdminOrders() => go('/admin/orders');
  void goToAdminOrderDetails(String orderId) => go('/admin/orders/$orderId');

  // ── Admin Riders ──────────────────────────────────
  void goToAdminRiders() => go('/admin/riders');
  void goToAdminRidersPending() => go('/admin/riders/pending');
  void goToAdminRiderDetails(String riderId) => go('/admin/riders/$riderId');

  // ── Rider ─────────────────────────────────────────────
  void goToRiderDashboard() => go('/rider/dashboard');
  void goToRiderPending() => go('/rider/pending');
}
