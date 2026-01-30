// lib/shared/enums/user_role.dart

enum UserRole {
  customer,
  rider,
  admin;

  String get displayName {
    switch (this) {
      case UserRole.customer:
        return 'Customer';
      case UserRole.rider:
        return 'Rider';
      case UserRole.admin:
        return 'Admin';
    }
  }

  String get collectionName {
    switch (this) {
      case UserRole.customer:
        return 'users';
      case UserRole.rider:
        return 'riders';
      case UserRole.admin:
        return 'admins';
    }
  }

  static UserRole fromString(String role) {
    switch (role.toLowerCase()) {
      case 'customer':
        return UserRole.customer;
      case 'rider':
        return UserRole.rider;
      case 'admin':
        return UserRole.admin;
      default:
        throw ArgumentError('Invalid user role: $role');
    }
  }
}