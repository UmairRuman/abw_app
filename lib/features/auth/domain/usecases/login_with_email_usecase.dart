// lib/features/auth/domain/usecases/login_with_email_usecase.dart

import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../shared/enums/user_role.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class LoginWithEmailUseCase {
  final AuthRepository repository;

  LoginWithEmailUseCase(this.repository);

  Future<Either<Failure, UserEntity>> call({
    required String email,
    required String password,
    required UserRole role,
    String? adminKey,
  }) async {
    // Validate admin key if logging in as admin
    if (role == UserRole.admin) {
      if (adminKey == null || adminKey.isEmpty) {
        return const Left(
          ValidationFailure(message: 'Admin access key is required'),
        );
      }
      if (!repository.verifyAdminKey(adminKey)) {
        return const Left(
          AuthFailure(message: 'Invalid admin access key'),
        );
      }
    }

    // Proceed with login
    return await repository.loginWithEmail(
      email: email,
      password: password,
      role: role,
      adminKey: adminKey,
    );
  }
}