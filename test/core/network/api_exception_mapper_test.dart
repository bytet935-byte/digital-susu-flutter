import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:digital_susu/core/errors/app_exception.dart';
import 'package:digital_susu/core/network/api_exception_mapper.dart';

void main() {
  RequestOptions options() => RequestOptions(path: '/test');

  DioException ofType(DioExceptionType type) =>
      DioException(requestOptions: options(), type: type);

  DioException ofStatus(int status, {Object? data}) => DioException(
        requestOptions: options(),
        type: DioExceptionType.badResponse,
        response: Response<dynamic>(
          requestOptions: options(),
          statusCode: status,
          data: data,
        ),
      );

  group('ApiExceptionMapper — transport errors (spec §12)', () {
    test('timeouts map to ApiTimeoutException', () {
      expect(
        ApiExceptionMapper.fromDioException(ofType(DioExceptionType.connectionTimeout)),
        isA<ApiTimeoutException>(),
      );
      expect(
        ApiExceptionMapper.fromDioException(ofType(DioExceptionType.receiveTimeout)),
        isA<ApiTimeoutException>(),
      );
      expect(
        ApiExceptionMapper.fromDioException(ofType(DioExceptionType.sendTimeout)),
        isA<ApiTimeoutException>(),
      );
    });

    test('connection failures map to NetworkException', () {
      expect(
        ApiExceptionMapper.fromDioException(
            ofType(DioExceptionType.connectionError)),
        isA<NetworkException>(),
      );
      expect(
        ApiExceptionMapper.fromDioException(
            ofType(DioExceptionType.badCertificate)),
        isA<NetworkException>(),
      );
      expect(
        ApiExceptionMapper.fromDioException(
            ofType(DioExceptionType.unknown)),
        isA<NetworkException>(),
      );
    });

    test('pre-mapped AppException from interceptors passes through', () {
      final wrapped = DioException(
        requestOptions: options(),
        type: DioExceptionType.unknown,
        error: const SessionExpiredException(),
      );
      expect(
        ApiExceptionMapper.fromDioException(wrapped),
        isA<SessionExpiredException>(),
      );
    });
  });

  group('ApiExceptionMapper — HTTP status codes', () {
    test('4xx statuses map to their domain exceptions', () {
      expect(ApiExceptionMapper.fromDioException(ofStatus(400)),
          isA<ValidationException>());
      expect(ApiExceptionMapper.fromDioException(ofStatus(422)),
          isA<ValidationException>());
      expect(ApiExceptionMapper.fromDioException(ofStatus(401)),
          isA<TokenExpiredException>());
      expect(ApiExceptionMapper.fromDioException(ofStatus(403)),
          isA<ForbiddenException>());
      expect(ApiExceptionMapper.fromDioException(ofStatus(404)),
          isA<NotFoundException>());
      expect(ApiExceptionMapper.fromDioException(ofStatus(409)),
          isA<ConflictException>());
      expect(ApiExceptionMapper.fromDioException(ofStatus(429)),
          isA<RateLimitException>());
    });

    test('5xx maps to ServerException', () {
      expect(ApiExceptionMapper.fromDioException(ofStatus(500)),
          isA<ServerException>());
      expect(ApiExceptionMapper.fromDioException(ofStatus(503)),
          isA<ServerException>());
    });

    test('unexpected status maps to MalformedResponseException', () {
      expect(ApiExceptionMapper.fromDioException(ofStatus(418)),
          isA<MalformedResponseException>());
    });

    test('server message is preferred over generic copy', () {
      final error = ApiExceptionMapper.fromDioException(
          ofStatus(400, data: <String, dynamic>{'message': 'Phone is invalid'}));
      expect(error.message, 'Phone is invalid');
    });

    test('friendly generic copy is used when no server message exists', () {
      final error =
          ApiExceptionMapper.fromDioException(ofStatus(500));
      expect(error.message, contains('trouble'));
    });
  });
}
