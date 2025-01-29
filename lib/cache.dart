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
  Cache(this.response, this.options) : date = DateTime.now();

  final FetchResponse response;
  final CacheOptions options;
  final DateTime date;

  bool get isExpired {
    return date.add(options.duration).isBefore(DateTime.now());
  }
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

    final entry = _caches[url];

    if (entry != null && entry.isExpired) {
      removeCache(url);
      return null;
    }

    return _caches[url];
  }

  void cache(FetchResponse response, Uri uri, CacheOptions options) {
    if (!options.canCache(response)) {
      return;
    }

    if (options.duration == Duration.zero) {
      return;
    }

    final cachedData = Cache(response, options);
    final url = switch (options.strategy) {
      CacheStrategy.urlWithoutQuery => uri.replace(query: ''),
      CacheStrategy.fullUrl => uri,
    }
        .removeFragment();

    _caches[url] = cachedData;
  }

  void clearCache() {
    _caches.clear();
  }

  void removeCache(Uri uri) {
    _caches.remove(uri.removeFragment());
  }
}
