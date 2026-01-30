// lib/features/auth/domain/usecases/send_password_reset_usecase.dart

import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/auth_repository.dart';

class SendPasswordResetUseCase {
  final AuthRepository repository;

  SendPasswordResetUseCase(this.repository);

  Future<Either<Failure, void>> call(String email) async {
    if (email.trim().isEmpty) {
      return const Left(ValidationFailure(message: 'Email is required'));
    }

    return await repository.sendPasswordResetEmail(email);
  }
}