part of 'fetch.dart';

enum CacheStrategy {
  urlWithoutQuery,
  fullUrl;
}

bool _defaultCanCache(FetchResponse response) => true;

//! ----------------------------------------------------------------------------
class CacheOptions {
  const CacheOptions({
    this.duration = Duration.zero,
    this.strategy = CacheStrategy.fullUrl,
    this.canCache = _defaultCanCache,
  });

  final Duration duration;
  final CacheStrategy strategy;
  final bool Function(FetchResponse response) canCache;
}

//! ----------------------------------------------------------------------------
class Cache {
  const Cache(
    this.response,
    this.options,
    this.date,
  );

  final FetchResponse response;
  final CacheOptions options;
  final DateTime date;
}

//! ----------------------------------------------------------------------------
mixin CacheFactory {
  final _caches = <Uri, Cache>{};

  Cache? resolveCache(Uri uri, CacheOptions options) {
    final url = switch (options.strategy) {
      CacheStrategy.urlWithoutQuery => uri.replace(query: ''),
      CacheStrategy.fullUrl => uri,
    }
        .removeFragment();

    if (options.duration == Duration.zero || !_caches.containsKey(url)) {
      return _caches[url];
    }

    final entry = _caches[url]!;
    final isAfter = entry.date.add(entry.options.duration).isAfter(
          DateTime.now(),
        );

    if (!isAfter) {
      _caches.remove(url);
    }

    return null;
  }

  void cache(FetchResponse response, Uri uri, CacheOptions options) {
    if (!options.canCache(response)) {
      return;
    }

    uri = uri.removeFragment();

    if (options.duration == Duration.zero) {
      return;
    }

    final now = DateTime.now();
    final cachedData = Cache(response, options, now);

    final uriKey = switch (options.strategy) {
      CacheStrategy.urlWithoutQuery => uri.replace(query: ''),
      CacheStrategy.fullUrl => uri,
    };

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
