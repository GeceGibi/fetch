import 'package:via/src/core/request.dart';
import 'package:via/src/core/result.dart';
import 'package:via/src/features/pipeline.dart';

/// Caching strategy for HTTP requests.
enum CacheStrategy {
  /// Use URL without query parameters as the cache key.
  urlWithoutQuery,

  /// Use the full URL including query parameters as the cache key.
  fullUrl,
}

/// A pipeline that caches successful GET responses.
///
/// Responses are stored in memory and returned for subsequent requests 
/// to the same URL until the [duration] expires.
class ViaCachePipeline extends ViaPipeline {
  ViaCachePipeline({
    required this.duration,
    this.strategy = CacheStrategy.fullUrl,
    this.maxEntries = 100,
    this.canCache,
  }) : _cache = {};

  /// How long each response should remain in the cache.
  final Duration duration;

  /// The strategy used to generate cache keys.
  final CacheStrategy strategy;

  /// Maximum number of items to keep in memory (FIFO).
  final int maxEntries;

  /// Optional callback to decide if a specific result should be cached.
  final bool Function(ViaResult result)? canCache;
  
  final Map<String, _CacheEntry> _cache;

  String _getCacheKey(ViaRequest request) {
    final ViaRequest(:uri, :method) = request;

    return switch (strategy) {
      CacheStrategy.urlWithoutQuery => '$method:${uri.replace(query: '')}',
      CacheStrategy.fullUrl => '$method:$uri',
    };
  }

  @override
  ViaRequest onRequest(ViaRequest request) {
    if (duration == Duration.zero) {
      return request;
    }

    final key = _getCacheKey(request);
    final cached = _cache[key];

    // Return cached response if available and not expired
    if (cached != null && !cached.isExpired) {
      throw SkipRequest(cached.result);
    }

    return request;
  }

  @override
  ViaResult onResult(ViaResult result) {
    if (duration == Duration.zero) {
      return result;
    }

    // Check if response can be cached
    if (canCache != null && !canCache!(result)) {
      return result;
    }

    // Cache the response
    final key = _getCacheKey(result.request);

    // Memory management: Remove oldest entry if limit reached
    if (_cache.length >= maxEntries) {
      _cache.remove(_cache.keys.first);
    }

    _cache[key] = _CacheEntry(result, duration);

    return result;
  }

  /// Clear all cached responses
  void clearCache() {
    _cache.clear();
  }

  /// Clear cached response for specific URI
  void clearCacheFor(ViaRequest request) {
    final key = _getCacheKey(request);
    _cache.remove(key);
  }
}

class _CacheEntry {
  _CacheEntry(this.result, this.duration) : date = DateTime.now();

  final ViaResult result;
  final Duration duration;
  final DateTime date;

  bool get isExpired => date.add(duration).isBefore(DateTime.now());
}
