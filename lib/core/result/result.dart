// Lightweight Result type.
import 'package:equatable/equatable.dart';
import 'package:task_map_flow/core/errors/failure.dart';

sealed class Result<T> extends Equatable {
  const Result();
}

final class Success<T> extends Result<T> {
  const Success(this.value);
  final T value;

  @override
  List<Object?> get props => [value];
}

final class Err<T> extends Result<T> {
  const Err(this.failure);
  final Failure failure;

  @override
  List<Object?> get props => [failure];
}

extension ResultX<T> on Result<T> {
  bool get isSuccess => this is Success<T>;
  bool get isError => this is Err<T>;

  T? get valueOrNull => switch (this) {
        Success<T>(:final value) => value,
        Err<T>() => null,
      };

  Failure? get failureOrNull => switch (this) {
        Success<T>() => null,
        Err<T>(:final failure) => failure,
      };
}
