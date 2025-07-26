import 'package:freezed_annotation/freezed_annotation.dart';

part 'failures.freezed.dart';

@freezed
class Failure with _$Failure {
  const factory Failure.serverFailure(String message) = ServerFailure;
  const factory Failure.networkFailure(String message) = NetworkFailure;
  const factory Failure.authFailure(String message) = AuthFailure;
  const factory Failure.unknownFailure(String message) = UnknownFailure;
  
  @override
  // TODO: implement message
  String get message => throw UnimplementedError();
}
