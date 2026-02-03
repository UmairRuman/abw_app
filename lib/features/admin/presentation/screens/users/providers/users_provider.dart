// lib/features/admin/presentation/screens/users/providers/users_provider.dart

import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../auth/data/models/customer_model.dart';
import '../../../../../auth/data/models/rider_model.dart';
import '../../../../../auth/data/datasources/auth_remote_datasource.dart';

final usersProvider = NotifierProvider<UsersNotifier, UsersState>(
  UsersNotifier.new,
);

class UsersNotifier extends Notifier<UsersState> {
  late final AuthRemoteDataSource _dataSource;

  @override
  UsersState build() {
    // Create AuthRemoteDataSource directly
    _dataSource = AuthRemoteDataSource(
      firebaseAuth: FirebaseAuth.instance,
      firestore: FirebaseFirestore.instance,
      googleSignIn: GoogleSignIn.instance,
    );
    return UsersInitial();
  }

  /// Load all customers
  Future<void> loadCustomers() async {
    state = UsersLoading();

    try {
      final customersData = await _dataSource.getAllCustomers();

      final customers = customersData
          .map((data) => CustomerModel.fromJson(data))
          .toList();

      final currentState = state;
      if (currentState is UsersLoaded) {
        state = currentState.copyWith(customers: customers);
      } else {
        state = UsersLoaded(customers: customers, riders: []);
      }

      log('Loaded ${customers.length} customers');
    } catch (e) {
      state = UsersError(error: e.toString());
      log('Error loading customers: ${e.toString()}');
    }
  }

  /// Load all riders
  Future<void> loadRiders() async {
    try {
      final ridersData = await _dataSource.getAllRiders();

      final riders = ridersData
          .map((data) => RiderModel.fromJson(data))
          .toList();

      final currentState = state;
      if (currentState is UsersLoaded) {
        state = currentState.copyWith(riders: riders);
      } else {
        state = UsersLoaded(customers: [], riders: riders);
      }

      log('Loaded ${riders.length} riders');
    } catch (e) {
      state = UsersError(error: e.toString());
      log('Error loading riders: ${e.toString()}');
    }
  }

  /// Search users
  Future<void> searchUsers(String query) async {
    // This will be handled by the UI filtering
    // Could be implemented server-side for large datasets
  }
}

// States
abstract class UsersState {}

class UsersInitial extends UsersState {}

class UsersLoading extends UsersState {}

class UsersLoaded extends UsersState {
  final List<CustomerModel> customers;
  final List<RiderModel> riders;

  UsersLoaded({
    required this.customers,
    required this.riders,
  });

  UsersLoaded copyWith({
    List<CustomerModel>? customers,
    List<RiderModel>? riders,
  }) {
    return UsersLoaded(
      customers: customers ?? this.customers,
      riders: riders ?? this.riders,
    );
  }
}

class UsersError extends UsersState {
  final String error;

  UsersError({required this.error});
}