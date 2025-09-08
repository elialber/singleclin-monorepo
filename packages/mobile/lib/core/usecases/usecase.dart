import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:singleclin_mobile/core/errors/failures.dart';

/// Base typedef for all use cases
typedef UseCase<Type, Params> = Future<Either<Failure, Type>> Function(Params params);

/// Use this class when the use case doesn't need parameters
class NoParams extends Equatable {
  @override
  List<Object?> get props => [];
}
