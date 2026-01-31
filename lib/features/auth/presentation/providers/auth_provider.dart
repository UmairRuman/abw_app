// lib/features/auth/presentation/providers/auth_provider.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/get_current_user_usecase.dart';
import '../../domain/usecases/login_with_email_usecase.dart';
import '../../domain/usecases/login_with_google_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/send_password_reset_usecase.dart';
import '../../domain/usecases/signup_customer_usecase.dart';
import '../../domain/usecases/signup_rider_usecase.dart';
import 'auth_notifier.dart';
import 'auth_state.dart';

// Firebase instances
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final googleSignInProvider = Provider<GoogleSignIn>((ref) {
  return GoogleSignIn.instance;
});

// Data source
final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSource(
    firebaseAuth: ref.watch(firebaseAuthProvider),
    firestore: ref.watch(firestoreProvider),
    googleSignIn: ref.watch(googleSignInProvider),
  );
});

// Repository
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    remoteDataSource: ref.watch(authRemoteDataSourceProvider),
  );
});

// Use cases
final loginWithEmailUseCaseProvider = Provider<LoginWithEmailUseCase>((ref) {
  return LoginWithEmailUseCase(ref.watch(authRepositoryProvider));
});

final loginWithGoogleUseCaseProvider = Provider<LoginWithGoogleUseCase>((ref) {
  return LoginWithGoogleUseCase(ref.watch(authRepositoryProvider));
});

final signUpCustomerUseCaseProvider = Provider<SignUpCustomerUseCase>((ref) {
  return SignUpCustomerUseCase(ref.watch(authRepositoryProvider));
});

final signUpRiderUseCaseProvider = Provider<SignUpRiderUseCase>((ref) {
  return SignUpRiderUseCase(ref.watch(authRepositoryProvider));
});

final sendPasswordResetUseCaseProvider =
    Provider<SendPasswordResetUseCase>((ref) {
  return SendPasswordResetUseCase(ref.watch(authRepositoryProvider));
});

final logoutUseCaseProvider = Provider<LogoutUseCase>((ref) {
  return LogoutUseCase(ref.watch(authRepositoryProvider));
});

final getCurrentUserUseCaseProvider = Provider<GetCurrentUserUseCase>((ref) {
  return GetCurrentUserUseCase(ref.watch(authRepositoryProvider));
});

// Main auth provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    loginWithEmailUseCase: ref.watch(loginWithEmailUseCaseProvider),
    loginWithGoogleUseCase: ref.watch(loginWithGoogleUseCaseProvider),
    signUpCustomerUseCase: ref.watch(signUpCustomerUseCaseProvider),
    signUpRiderUseCase: ref.watch(signUpRiderUseCaseProvider),
    sendPasswordResetUseCase: ref.watch(sendPasswordResetUseCaseProvider),
    logoutUseCase: ref.watch(logoutUseCaseProvider),
    getCurrentUserUseCase: ref.watch(getCurrentUserUseCaseProvider),
  );
});

// Current user provider (for easier access)
final currentUserProvider = Provider((ref) {
  final authState = ref.watch(authProvider);
  if (authState is Authenticated) {
    return authState.user;
  } else if (authState is RiderPendingApproval) {
    return authState.user;
  }
  return null;
});

// Auth state stream provider
final authStateStreamProvider = StreamProvider((ref) {
  return ref.watch(getCurrentUserUseCaseProvider).authStateChanges;
});