// lib/features/auth/domain/usecases/submit_rider_request_usecase.dart

import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/rider_request_entity.dart';
import '../repositories/auth_repository.dart';

class SubmitRiderRequestUseCase {
  final AuthRepository repository;

  SubmitRiderRequestUseCase(this.repository);

  Future<Either<Failure, RiderRequestEntity>> call({
    required String riderId,
    required String riderName,
    required String riderEmail,
    required String riderPhone,
    required String vehicleType,
    required String vehicleNumber,
  }) async {
    return await repository.submitRiderRequest(
      riderId: riderId,
      riderName: riderName,
      riderEmail: riderEmail,
      riderPhone: riderPhone,
      vehicleType: vehicleType,
      vehicleNumber: vehicleNumber,
    );
  }
}