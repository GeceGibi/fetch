import 'package:fetch/fetch.dart';

void main(List<String> args) async {
  final fetch = Fetch(from: 'https://jsonplaceholder.typicode.com');

  fetch.enableLogger = true;
  fetch.baseHeaders.addAll({
    'content-type': 'application/json',
  });

  fetch.get('https://www.google.com');
  // fetch.post('/posts', jsonEncode({'foo': 1}));
}
