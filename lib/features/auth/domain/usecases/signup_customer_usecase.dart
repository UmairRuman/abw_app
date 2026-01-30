// lib/features/auth/domain/usecases/signup_customer_usecase.dart

import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/customer_entity.dart';
import '../repositories/auth_repository.dart';

class SignUpCustomerUseCase {
  final AuthRepository repository;

  SignUpCustomerUseCase(this.repository);

  Future<Either<Failure, CustomerEntity>> call({
    required String email,
    required String password,
    required String name,
    required String phone,
  }) async {
    // Validate inputs
    if (name.trim().isEmpty) {
      return const Left(ValidationFailure(message: 'Name is required'));
    }

    if (phone.trim().isEmpty) {
      return const Left(ValidationFailure(message: 'Phone is required'));
    }

    if (password.length < 8) {
      return const Left(
        ValidationFailure(message: 'Password must be at least 8 characters'),
      );
    }

    // Proceed with signup
    return await repository.signUpCustomer(
      email: email,
      password: password,
      name: name,
      phone: phone,
    );
  }
}