/// A minimal `Result<T, E>` type.
///
/// Network and protocol operations return a [Result] instead of throwing
/// across layers (see PROMPT.md §4 rules). The UI layer never sees a raw
/// exception from the protocol layer.
library;

import 'package:meta/meta.dart';

@immutable
sealed class Result<T, E> {
  const Result();

  /// Wraps a successful value.
  const factory Result.ok(T value) = Ok<T, E>;

  /// Wraps a failure.
  const factory Result.err(E error) = Err<T, E>;

  bool get isOk => this is Ok<T, E>;
  bool get isErr => this is Err<T, E>;

  /// The value if [isOk], otherwise null.
  T? get valueOrNull => switch (this) {
        Ok<T, E>(:final value) => value,
        Err<T, E>() => null,
      };

  /// The error if [isErr], otherwise null.
  E? get errorOrNull => switch (this) {
        Ok<T, E>() => null,
        Err<T, E>(:final error) => error,
      };

  /// Transforms the success value, leaving an error untouched.
  Result<R, E> map<R>(R Function(T value) transform) => switch (this) {
        Ok<T, E>(:final value) => Ok(transform(value)),
        Err<T, E>(:final error) => Err(error),
      };

  /// Folds both branches into a single value.
  R fold<R>(R Function(T value) onOk, R Function(E error) onErr) =>
      switch (this) {
        Ok<T, E>(:final value) => onOk(value),
        Err<T, E>(:final error) => onErr(error),
      };
}

@immutable
final class Ok<T, E> extends Result<T, E> {
  const Ok(this.value);
  final T value;

  @override
  bool operator ==(Object other) =>
      other is Ok<T, E> && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'Ok($value)';
}

@immutable
final class Err<T, E> extends Result<T, E> {
  const Err(this.error);
  final E error;

  @override
  bool operator ==(Object other) =>
      other is Err<T, E> && other.error == error;

  @override
  int get hashCode => error.hashCode;

  @override
  String toString() => 'Err($error)';
}
