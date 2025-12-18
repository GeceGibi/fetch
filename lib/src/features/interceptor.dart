import 'dart:async';

import 'package:fetch/src/core/payload.dart';
import 'package:fetch/src/core/response.dart';
import 'package:fetch/src/utils/exception.dart';

/// Abstract Interceptor class
abstract class Interceptor {
  /// Called before request is sent
  FutureOr<FetchPayload> onRequest(FetchPayload payload) => payload;

  /// Called after response is received
  FutureOr<FetchResponse> onResponse(FetchResponse response) => response;

  /// Called when an error occurs
  FutureOr<void> onError(FetchException error) {}
}

/// Request/Response logging interceptor
class LogInterceptor extends Interceptor {
  LogInterceptor({this.logRequest = true, this.logResponse = true});

  final bool logRequest;
  final bool logResponse;

  @override
  FetchPayload onRequest(FetchPayload payload) {
    if (logRequest) {
      print('→ ${payload.method} ${payload.uri}');
      if (payload.headers?.isNotEmpty ?? false) {
        print('  Headers: ${payload.headers}');
      }
      if (payload.body != null) {
        print('  Body: ${payload.body}');
      }
    }
    return payload;
  }

  @override
  FetchResponse onResponse(FetchResponse response) {
    if (logResponse) {
      print(
          '← ${response.response.statusCode} ${response.response.request?.url}');
    }
    return response;
  }

  @override
  void onError(FetchException error) {
    print('✗ Error: ${error.message}');
  }
}

/// Auth token interceptor
class AuthInterceptor extends Interceptor {
  AuthInterceptor({required this.getToken});

  final FutureOr<String?> Function() getToken;

  @override
  Future<FetchPayload> onRequest(FetchPayload payload) async {
    final token = await getToken();
    if (token != null) {
      return payload.copyWith(
        headers: {
          ...?payload.headers,
          'Authorization': 'Bearer $token',
        },
      );
    }
    return payload;
  }
}

/// Retry interceptor
class RetryInterceptor extends Interceptor {
  RetryInterceptor({
    this.maxAttempts = 3,
    this.retryDelay = const Duration(seconds: 1),
    this.retryIf,
  });

  final int maxAttempts;
  final Duration retryDelay;
  final bool Function(FetchException error)? retryIf;

  bool shouldRetry(FetchException error) {
    if (retryIf != null) {
      return retryIf!(error);
    }
    // Default: retry on server errors and connection errors
    return error.isServerError || error.isConnectionError || error.isTimeout;
  }
}
