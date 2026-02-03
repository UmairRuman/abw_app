// lib/core/constants/permission_constants.dart

class PermissionConstants {
  PermissionConstants._();

  // Permission keys
  static const String manageCategories = 'manage_categories';
  static const String manageStores = 'manage_stores';
  static const String approveStores = 'approve_stores';
  static const String manageProducts = 'manage_products';
  static const String manageUsers = 'manage_users';
  static const String manageRiders = 'manage_riders';
  static const String approveRiders = 'approve_riders';
  static const String viewOrders = 'view_orders';
  static const String manageOrders = 'manage_orders';
  static const String manageSubAdmins = 'manage_sub_admins';
  static const String viewAnalytics = 'view_analytics';

  // All available permissions
  static const List<String> allPermissions = [
    manageCategories,
    manageStores,
    approveStores,
    manageProducts,
    manageUsers,
    manageRiders,
    approveRiders,
    viewOrders,
    manageOrders,
    manageSubAdmins,
    viewAnalytics,
  ];

  // Permission descriptions (for UI)
  static const Map<String, String> permissionDescriptions = {
    manageCategories: 'Add, edit, and delete categories',
    manageStores: 'Manage store information',
    approveStores: 'Approve or reject store registrations',
    manageProducts: 'Add, edit, and delete products',
    manageUsers: 'View and manage customer accounts',
    manageRiders: 'Manage rider accounts',
    approveRiders: 'Approve or reject rider applications',
    viewOrders: 'View all orders',
    manageOrders: 'Update order status and assign riders',
    manageSubAdmins: 'Create and manage sub-admin accounts',
    viewAnalytics: 'View reports and analytics',
  };

  // Permission groups (for organized UI)
  static const Map<String, List<String>> permissionGroups = {
    'Content Management': [
      manageCategories,
      manageStores,
      manageProducts,
    ],
    'Approvals': [
      approveStores,
      approveRiders,
    ],
    'User Management': [
      manageUsers,
      manageRiders,
      manageSubAdmins,
    ],
    'Operations': [
      viewOrders,
      manageOrders,
      viewAnalytics,
    ],
  };
}