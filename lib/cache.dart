// ignore_for_file: constant_identifier_names

part of fetch;

enum CacheStrategy {
  URL_WITHOUT_QUERY,
  FULL_URL,
}

//! ----------------------------------------------------------------------------
class CacheOptions {
  const CacheOptions({
    this.duration = Duration.zero,
    this.strategy = CacheStrategy.FULL_URL,
  });

  final Duration duration;
  final CacheStrategy strategy;
}

//! ----------------------------------------------------------------------------
class Cache {
  const Cache(
    this.response,
    this.duration,
    this.date,
  );

  final HttpResponse response;
  final Duration duration;
  final DateTime date;
}

//! ----------------------------------------------------------------------------
class CacheFactory {
  CacheFactory();
  final _caches = <Uri, Cache>{};

  Cache? resolve(Uri uri, CacheOptions options) {
    uri = uri.removeFragment();

    switch (options.strategy) {
      case CacheStrategy.FULL_URL:
        return _caches[uri];

      case CacheStrategy.URL_WITHOUT_QUERY:
        return _caches[uri.replace(query: '')];
    }
  }

  bool isCached(Uri uri, CacheOptions options) {
    uri = uri.removeFragment();

    if (options.duration == Duration.zero) {
      return false;
    }

    if (CacheStrategy.URL_WITHOUT_QUERY == options.strategy) {
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

  void cache(HttpResponse response, Uri uri, CacheOptions options) {
    uri = uri.removeFragment();

    if (options.duration == Duration.zero) {
      return;
    }

    switch (options.strategy) {
      case CacheStrategy.FULL_URL:
        _caches[uri] = Cache(
          response,
          options.duration,
          DateTime.now(),
        );
        break;

      case CacheStrategy.URL_WITHOUT_QUERY:
        _caches[uri.replace(query: '')] = Cache(
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
