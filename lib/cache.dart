// ignore_for_file: constant_identifier_names, parameter_assignments

part of 'fetch.dart';

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

  final FetchResponse response;
  final Duration duration;
  final DateTime date;
}

//! ----------------------------------------------------------------------------
mixin CacheFactory {
  final _caches = <Uri, Cache>{};

  Cache? resolveCache(Uri uri, CacheOptions options) {
    uri = uri.removeFragment();

    return switch (options.strategy) {
      CacheStrategy.FULL_URL => _caches[uri],
      CacheStrategy.URL_WITHOUT_QUERY => _caches[uri.replace(query: '')],
    };
  }

  bool isCached(Uri uri, CacheOptions options) {
    uri = uri.removeFragment();

    if (CacheStrategy.URL_WITHOUT_QUERY == options.strategy) {
      uri = uri.replace(query: '');
    }

    var contains = _caches.containsKey(uri);

    if (options.duration == Duration.zero && contains) {
      contains = false;
      _caches.remove(uri);
    }

    if (contains) {
      final entry = _caches[uri]!;
      final isAfter = entry.date.add(entry.duration).isAfter(DateTime.now());

      if (!isAfter) {
        _caches.remove(uri);
      }

      return isAfter;
    }

    return false;
  }

  void cache(FetchResponse response, Uri uri, CacheOptions options) {
    uri = uri.removeFragment();

    if (options.duration == Duration.zero) {
      return;
    }

    final cachedData = Cache(
      response,
      options.duration,
      DateTime.now(),
    );

    final uriKey = options.strategy == CacheStrategy.FULL_URL
        ? uri
        : uri.replace(query: '');

    _caches[uriKey] = cachedData;
  }

  void clearCache() {
    _caches.clear();
  }

  void removeCache(Uri uri) {
    uri = uri.removeFragment();
    _caches.remove(uri);
  }
}
