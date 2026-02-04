// lib/features/auth/domain/usecases/create_admin_usecase.dart


import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/admin_entity.dart';
import '../repositories/auth_repository.dart';

class CreateAdminUseCase {
  final AuthRepository repository;

  CreateAdminUseCase(this.repository);

  Future<Either<Failure, AdminEntity>> call({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String accessKey,
    List<String> permissions = const [],
  }) async {
    return await repository.createAdmin(
      email: email,
      password: password,
      name: name,
      phone: phone,
      accessKey: accessKey,
      permissions: permissions,
    );
  }
}