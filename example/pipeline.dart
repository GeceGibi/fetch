import 'dart:async';
import 'package:via/via.dart';

void main() async {
  final via = Via(
    base: Uri.parse('https://httpbin.org'),
    executor: ViaExecutor(
      pipelines: [
        // Using our project-specific config pipeline
        AppConfigPipeline(),
        // Built-in logger with cURL support
        ViaLoggerPipeline(includeCurl: true),
      ],
    ),
  );

  print('--- Pipeline Test (Check logs for cURL and headers) ---');
  await via.get('/get');
}

class AppConfigPipeline extends ViaPipeline<ViaResult> {
  @override
  FutureOr<ViaRequest> onRequest(ViaRequest request) {
    // Values are embedded directly inside for a project-specific config
    final newUri = request.uri.replace(
      queryParameters: {
        ...request.uri.queryParameters,
        'env': 'production',
        'api_key': 'my_secret_key',
      },
    );

    final newHeaders = {
      ...?request.headers,
      'X-App-Name': 'ViaExample',
      'App-Version': '1.0.0',
    };

    return request.copyWith(uri: newUri, headers: newHeaders);
  }
}
