import 'package:fetch/src/core/response.dart';

/// Defines the caching strategy for HTTP requests.
///
/// This enum determines how cache keys are generated for requests.
enum CacheStrategy {
  /// Cache key is generated from URL without query parameters.
  ///
  /// This strategy ignores query parameters when creating cache keys,
  /// which can be useful when query parameters don't affect the response.
  urlWithoutQuery,

  /// Cache key is generated from the full URL including query parameters.
  ///
  /// This strategy includes all query parameters in the cache key,
  /// ensuring that different query parameters result in different cache entries.
  fullUrl;
}

/// Default function to determine if a response can be cached.
///
/// Returns true for all responses by default.
bool _defaultCanCache(FetchResponse response) => true;

/// Configuration options for HTTP response caching.
///
/// This class allows you to configure how responses are cached,
/// including cache duration, strategy, and conditions for caching.
class CacheOptions {
  /// Creates a new CacheOptions instance.
  ///
  /// [duration] - How long to cache responses (default: Duration.zero = no caching)
  /// [strategy] - The caching strategy to use (default: CacheStrategy.fullUrl)
  /// [canCache] - Function to determine if a response can be cached
  ///              (default: all responses)
  const CacheOptions({
    this.duration = Duration.zero,
    this.strategy = CacheStrategy.fullUrl,
    this.canCache = _defaultCanCache,
  });

  /// How long to cache responses
  final Duration duration;

  /// The caching strategy to use
  final CacheStrategy strategy;

  /// Function to determine if a response can be cached
  final bool Function(FetchResponse response) canCache;
}

/// Represents a cached HTTP response.
///
/// This class encapsulates a cached response along with its metadata
/// including when it was cached and the cache options used.
class Cache {
  /// Creates a new Cache instance.
  ///
  /// [response] - The HTTP response to cache
  /// [options] - The cache options used for this response
  Cache(this.response, this.options) : date = DateTime.now();

  /// The cached HTTP response
  final FetchResponse response;

  /// The cache options used for this response
  final CacheOptions options;

  /// When this response was cached
  final DateTime date;

  /// Whether this cached response has expired.
  ///
  /// Returns true if the cache duration has passed since the response was cached.
  bool get isExpired {
    return date.add(options.duration).isBefore(DateTime.now());
  }
}

/// Mixin that provides caching functionality for the Fetch class.
///
/// This mixin manages the cache storage and provides methods to:
/// - Resolve cached responses
/// - Cache new responses
/// - Clear cache
/// - Remove specific cache entries
mixin CacheFactory {
  /// Internal cache storage
  final _caches = <Uri, Cache>{};

  /// Resolves a cached response for the given URI and options.
  ///
  /// [uri] - The URI to look up in cache
  /// [options] - The cache options to use
  ///
  /// Returns the cached response if available and not expired,
  /// null otherwise.
  Cache? resolveCache(Uri uri, CacheOptions options) {
    final url = switch (options.strategy) {
      CacheStrategy.urlWithoutQuery => uri.replace(query: ''),
      CacheStrategy.fullUrl => uri,
    }
        .removeFragment();

    final entry = _caches[url];

    if (entry == null) {
      return null;
    }

    if (entry.isExpired) {
      removeCache(url);
      return null;
    }

    return entry;
  }

  /// Caches a response for the given URI and options.
  ///
  /// [response] - The HTTP response to cache
  /// [uri] - The URI to cache the response for
  /// [options] - The cache options to use
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

  /// Clears all cached responses.
  ///
  /// This method removes all entries from the cache.
  void clearCache() {
    _caches.clear();
  }

  /// Removes a specific cache entry.
  ///
  /// [uri] - The URI whose cache entry should be removed
  void removeCache(Uri uri) {
    _caches.remove(uri.removeFragment());
  }
}
