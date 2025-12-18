import 'package:fetch/src/core/payload.dart';
import 'package:fetch/src/core/response.dart';
import 'package:fetch/src/features/interceptor.dart';

/// Defines the caching strategy for HTTP requests.
enum CacheStrategy {
  /// Cache key from URL without query parameters
  urlWithoutQuery,

  /// Cache key from full URL including query parameters
  fullUrl,
}

/// Cache interceptor
///
/// Caches responses based on the configured strategy and duration.
class CacheInterceptor extends Interceptor {
  CacheInterceptor({
    required this.duration,
    this.strategy = CacheStrategy.fullUrl,
    this.canCache,
  }) : _cache = {};

  final Duration duration;
  final CacheStrategy strategy;
  final bool Function(FetchResponse response)? canCache;
  final Map<Uri, _CacheEntry> _cache;

  Uri _getCacheKey(Uri uri) {
    return switch (strategy) {
      CacheStrategy.urlWithoutQuery => uri.replace(query: ''),
      CacheStrategy.fullUrl => uri,
    };
  }

  @override
  FetchPayload onRequest(FetchPayload payload) {
    if (duration == Duration.zero) {
      return payload;
    }

    final key = _getCacheKey(payload.uri);
    final cached = _cache[key];

    // Return cached response if available and not expired
    if (cached != null && !cached.isExpired) {
      throw SkipRequest(cached.response);
    }

    return payload;
  }

  @override
  FetchResponse onResponse(FetchResponse response) {
    if (duration == Duration.zero) {
      return response;
    }

    // Check if response can be cached
    if (canCache != null && !canCache!(response)) {
      return response;
    }

    // Cache the response
    final key = _getCacheKey(response.payload.uri);
    _cache[key] = _CacheEntry(response, duration);

    return response;
  }

  /// Clear all cached responses
  void clearCache() {
    _cache.clear();
  }

  /// Clear cached response for specific URI
  void clearCacheFor(Uri uri) {
    final key = _getCacheKey(uri);
    _cache.remove(key);
  }
}

class _CacheEntry {
  _CacheEntry(this.response, this.duration) : date = DateTime.now();

  final FetchResponse response;
  final Duration duration;
  final DateTime date;

  bool get isExpired => date.add(duration).isBefore(DateTime.now());
}
