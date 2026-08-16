import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// Minimal in-memory [HttpClientAdapter] for unit tests — no extra
/// dependencies (dio ships the `ResponseBody` helpers we need).
///
/// Provide a [handler] that inspects [RequestOptions] (path, headers, body)
/// and returns a `ResponseBody` or throws a `DioException`.
class FakeDioAdapter implements HttpClientAdapter {
  FakeDioAdapter({this.handler});

  /// Mutable so each test can swap in its own handler.
  Future<ResponseBody> Function(RequestOptions options)? handler;

  /// Number of fetch calls performed.
  int requestCount = 0;

  /// Last options seen by the adapter (for assertions).
  RequestOptions? lastOptions;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requestCount++;
    lastOptions = options;
    if (handler != null) return handler!(options);
    return ResponseBody.fromString(
      '{"message":"no handler registered"}',
      404,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>[Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// Builds a JSON [ResponseBody].
ResponseBody jsonBody(Object data, int statusCode) => ResponseBody.fromString(
      jsonEncode(data),
      statusCode,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>[Headers.jsonContentType],
      },
    );

/// Builds a [DioException] for adapter handlers that simulate transport
/// failures (e.g. offline).
DioException dioError(
  RequestOptions options, {
  DioExceptionType type = DioExceptionType.connectionError,
}) =>
    DioException(requestOptions: options, type: type);
