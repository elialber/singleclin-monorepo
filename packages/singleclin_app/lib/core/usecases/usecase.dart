import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:singleclin_app/core/errors/failures.dart';

/// Base class for all use cases
abstract class UseCase<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}

/// Use this class when the use case doesn't need parameters
class NoParams extends Equatable {
  @override
  List<Object?> get props => [];
}