// lib/core/routes/app_router.dart

import 'package:abw_app/features/auth/presentation/screens/signup/admin_signup_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/screens/forgot_password/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/login/login_screen.dart';
import '../../features/auth/presentation/screens/rider_request/pending_approval_screen.dart';
import '../../features/auth/presentation/screens/signup/customer_signup_screen.dart';
import '../../features/auth/presentation/screens/signup/rider_signup_screen.dart';
import '../../features/auth/presentation/screens/splash/splash_screen.dart';
import '../../features/customer/presentation/screens/home/customer_home_screen.dart';
import '../../features/customer/presentation/screens/store/store_details_screen.dart';
import '../../features/customer/presentation/screens/search/search_screen.dart';
import '../../features/customer/presentation/screens/cart/cart_screen.dart';
import '../../features/customer/presentation/screens/profile/customer_profile_screen.dart';
import '../../features/customer/presentation/screens/addresses/addresses_screen.dart';
import '../../features/admin/presentation/screens/main/admin_main_screen.dart';
import '../../features/admin/presentation/screens/products/product_management_screen.dart';
import '../../features/admin/presentation/screens/users/users_list_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    debugLogDiagnostics: true,
    routes: [
      // ============================================================
      // SPLASH SCREEN
      // ============================================================
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // ============================================================
      // AUTHENTICATION ROUTES
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
        builder: (context, state) => const AddressesScreen(),
      ),

      // ============================================================
      // ADMIN ROUTES
      // ============================================================
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

      // ============================================================
      // RIDER ROUTES (Milestone 2)
      // ============================================================
      GoRoute(
        path: '/rider/dashboard',
        name: 'rider-dashboard',
        builder: (context, state) => const Scaffold(
          body: Center(
            child: Text(
              'Rider Dashboard - Coming in Milestone 2',
              style: TextStyle(fontSize: 18),
            ),
          ),
        ),
      ),

      // ============================================================
      // ERROR/404 ROUTE
      // ============================================================
      GoRoute(
        path: '/error',
        name: 'error',
        builder: (context, state) => Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Page Not Found',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text('The page you are looking for does not exist.'),
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

    errorBuilder: (context, state) => Scaffold(
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

extension NavigationExtensions on BuildContext {
  // Auth navigation
  void goToLogin() => go('/login');
  void goToCustomerSignup() => go('/signup/customer');
  void goToRiderSignup() => go('/signup/rider');
  void goToForgotPassword() => go('/forgot-password');
  
  // Customer navigation
  void goToCustomerHome() => go('/customer/home');
  void goToStoreDetails(String storeId) => go('/customer/store/$storeId');
  void goToSearch() => go('/customer/search');
  void goToCart() => go('/customer/cart');
  void goToProfile() => go('/customer/profile');
  void goToAddresses() => go('/customer/addresses');
  
  // Admin navigation
  void goToAdminDashboard() => go('/admin/dashboard');
  void goToAdminProducts() => go('/admin/products');
  void goToAdminUsers() => go('/admin/users');
  
  // Rider navigation
  void goToRiderDashboard() => go('/rider/dashboard');
  void goToRiderPending() => go('/rider/pending');
}