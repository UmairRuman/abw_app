// lib/features/auth/domain/usecases/signup_rider_usecase.dart

import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/rider_entity.dart';
import '../repositories/auth_repository.dart';

class SignUpRiderUseCase {
  final AuthRepository repository;

  SignUpRiderUseCase(this.repository);

  Future<Either<Failure, RiderEntity>> call({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String vehicleType,
    required String vehicleNumber,
    String? licenseNumber,
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

    if (vehicleType.trim().isEmpty) {
      return const Left(ValidationFailure(message: 'Vehicle type is required'));
    }

    if (vehicleNumber.trim().isEmpty) {
      return const Left(
        ValidationFailure(message: 'Vehicle number is required'),
      );
    }

    // Proceed with signup
    return await repository.signUpRider(
      email: email,
      password: password,
      name: name,
      phone: phone,
      vehicleType: vehicleType,
      vehicleNumber: vehicleNumber,
      licenseNumber: licenseNumber,
    );
  }
}