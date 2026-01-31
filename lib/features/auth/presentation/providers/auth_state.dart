// lib/features/auth/presentation/providers/auth_state.dart

import 'package:equatable/equatable.dart';
import '../../domain/entities/user_entity.dart';

/// Base auth state
sealed class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// Initial state when app starts
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// Loading state during auth operations
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// User is authenticated
class Authenticated extends AuthState {
  final UserEntity user;

  const Authenticated(this.user);

  @override
  List<Object?> get props => [user];
}

/// User is not authenticated
class Unauthenticated extends AuthState {
  const Unauthenticated();
}

/// Auth error occurred
class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}

/// Rider pending approval
class RiderPendingApproval extends AuthState {
  final UserEntity user;

  const RiderPendingApproval(this.user);

  @override
  List<Object?> get props => [user];
}