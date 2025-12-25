import 'dart:async';
import 'package:via/via.dart';

/// 1. Create a Custom Result class by extending ViaResult
class MyApiResponse extends ViaResult {
  MyApiResponse({required super.request, required super.response});

  /// Custom property to check for a specific field in your API
  bool get hasError => body.contains('error');

  /// Custom helper to get a specific value from the response
  String? get message => headers['x-message'];
}

/// 2. Create a Pipeline that works with your Custom Result
class MyResponsePipeline extends ViaPipeline {
  @override
  FutureOr<ViaBaseResult> onResult(ViaBaseResult result) {
    print('Processing MyApiResponse in pipeline...');

    // Only transform if it's a buffered result
    if (result is ViaResult) {
      return MyApiResponse(
        request: result.request,
        response: result.response,
      );
    }
    return result;
  }
}

Future<void> main() async {
  // 3. Initialize Via with your Custom Result type
  final via = Via<MyApiResponse>(
    base: Uri.parse('https://httpbin.org'),
    executor: ViaExecutor(
      pipelines: [MyResponsePipeline()],
    ),
  );

  print('--- Custom Result & Pipeline Example ---');

  // 4. The return type is now automatically MyApiResponse
  final result = await via.get('/get');

  print('Is Success: ${result.isSuccess}');
  print('Has Error: ${result.hasError}');
  print('Original Status: ${result.statusCode}');
}
