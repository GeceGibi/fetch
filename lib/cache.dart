// ignore_for_file: constant_identifier_names

part of fetch;

enum CacheStrategy {
  URL,
  URL_WITHOUT_QUERY_PARAMS,
}

//! ----------------------------------------------------------------------------
class FetchCacheOptions {
  const FetchCacheOptions({
    this.duration = Duration.zero,
    this.strategy = CacheStrategy.URL,
  });

  final Duration duration;
  final CacheStrategy strategy;
}

//! ----------------------------------------------------------------------------
class FetchCache {
  const FetchCache(this.response, this.duration, this.date);
  final http.Response response;
  final Duration duration;
  final DateTime date;
}

//! ----------------------------------------------------------------------------
class FetchCacheFactory {
  FetchCacheFactory();
  final _caches = <Uri, FetchCache>{};

  FetchCache? resolve(Uri uri, FetchCacheOptions options) {
    uri = uri.removeFragment();

    switch (options.strategy) {
      case CacheStrategy.URL:
        return _caches[uri];

      case CacheStrategy.URL_WITHOUT_QUERY_PARAMS:
        return _caches[uri.replace(query: '')];
    }
  }

  bool isCached(Uri uri, FetchCacheOptions options) {
    uri = uri.removeFragment();

    if (options.duration == Duration.zero) {
      return false;
    }

    if (CacheStrategy.URL_WITHOUT_QUERY_PARAMS == options.strategy) {
      uri = uri.replace(query: '');
    }

    final contains = _caches.containsKey(uri);

    if (contains) {
      final entry = _caches[uri]!;
      final isAfter = entry.date.add(entry.duration).isAfter(
            DateTime.now(),
          );

      if (!isAfter) {
        _caches.remove(uri);
      }

      return isAfter;
    }

    return false;
  }

  void cache(http.Response response, Uri uri, FetchCacheOptions options) {
    uri = uri.removeFragment();

    if (options.duration == Duration.zero) {
      return;
    }

    switch (options.strategy) {
      case CacheStrategy.URL:
        _caches[uri] = FetchCache(
          response,
          options.duration,
          DateTime.now(),
        );
        break;

      case CacheStrategy.URL_WITHOUT_QUERY_PARAMS:
        _caches[uri.replace(query: '')] = FetchCache(
          response,
          options.duration,
          DateTime.now(),
        );

        break;
    }
  }

  void clear() {
    _caches.clear();
  }

  void remove(Uri uri) {
    uri.removeFragment();
    _caches.remove(uri);
  }
}
