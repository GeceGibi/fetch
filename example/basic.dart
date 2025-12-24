import 'package:via/via.dart';

Future<void> main() async {
  // Simple initialization
  final via = Via(base: Uri.parse('https://httpbin.org'));

  print('--- Basic GET Request ---');
  final getResult = await via.get('/get', queryParams: {'id': '123'});
  final getData = await getResult.asMap<String, dynamic>();
  print('Status: ${getResult.statusCode}');
  print('Args: ${getData['args']}');

  print('\n--- Basic POST Request ---');
  final postResult = await via.post('/post', {'name': 'Via'});
  final postData = await postResult.asMap<String, dynamic>();
  print('Status: ${postResult.statusCode}');
  print('Data Sent: ${postData['json']}');
}
