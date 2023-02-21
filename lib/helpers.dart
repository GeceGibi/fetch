part of fetch;

abstract class FetchHelpers {
  static T handleResponseBody<T>(HttpResponse response) {
    final contentType = (response.headers['content-type'] ?? '');
    final jsonTypes = ['application/json', 'application/javascript'];

    for (final type in jsonTypes) {
      if (contentType.contains(type)) {
        return jsonDecode(response.body);
      }
    }

    return response.body as T;
  }
}
