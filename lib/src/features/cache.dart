import 'package:fetch/src/core/request.dart';
import 'package:fetch/src/core/result.dart';
import 'package:fetch/src/features/pipeline.dart';

/// Defines the caching strategy for HTTP requests.
enum CacheStrategy {
  /// Cache key from URL without query parameters
  urlWithoutQuery,

  /// Cache key from full URL including query parameters
  fullUrl,
}

/// Cache pipeline
///
/// Caches responses based on the configured strategy and duration.
class CachePipeline extends FetchPipeline {
  CachePipeline({
    required this.duration,
    this.strategy = CacheStrategy.fullUrl,
    this.canCache,
  }) : _cache = {};

  final Duration duration;
  final CacheStrategy strategy;
  final bool Function(FetchResult result)? canCache;
  final Map<Uri, _CacheEntry> _cache;

  Uri _getCacheKey(Uri uri) {
    return switch (strategy) {
      CacheStrategy.urlWithoutQuery => uri.replace(query: ''),
      CacheStrategy.fullUrl => uri,
    };
  }

  @override
  FetchRequest onRequest(FetchRequest request) {
    if (duration == Duration.zero) {
      return request;
    }

    final key = _getCacheKey(request.uri);
    final cached = _cache[key];

    // Return cached response if available and not expired
    if (cached != null && !cached.isExpired) {
      throw SkipRequest(cached.result);
    }

    return request;
  }

  @override
  FetchResult onResult(FetchResult result) {
    if (duration == Duration.zero) {
      return result;
    }

    // Check if response can be cached
    if (canCache != null && !canCache!(result)) {
      return result;
    }

    // Cache the response
    final key = _getCacheKey(result.request.uri);
    _cache[key] = _CacheEntry(result, duration);

    return result;
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
  _CacheEntry(this.result, this.duration) : date = DateTime.now();

  final FetchResult result;
  final Duration duration;
  final DateTime date;

  bool get isExpired => date.add(duration).isBefore(DateTime.now());
}
