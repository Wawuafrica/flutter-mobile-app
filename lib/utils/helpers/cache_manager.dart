import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// A custom cache manager singleton to provide a centralized caching strategy
/// for network images throughout the application.
///
/// This implementation uses a lazy-initialized singleton pattern to ensure that
/// the CacheManager instance is only created when it's first needed,
/// improving initial app startup time.
class CustomCacheManager {
  static const _cacheKey = 'customCacheKey';

  static CacheManager? _instance;

  // Private constructor to prevent direct instantiation.
  CustomCacheManager._();

  /// Provides a single, shared instance of [CacheManager] with a custom configuration.
  static CacheManager get instance {
    // Lazily initialize the CacheManager instance.
    _instance ??= CacheManager(
        Config(
          _cacheKey,
          // stalePeriod: Defines how long a file is considered 'fresh'. After this
          // period, the cache manager will still return the cached file but will
          // also trigger a background check to see if a newer version is available.
          // A 30-day period is a good balance for assets that don't change often,
          // reducing unnecessary network requests.
          stalePeriod: const Duration(days: 30),

          // maxNrOfCacheObjects: Sets the upper limit on the number of files
          // stored in the cache. When this limit is reached, the least recently
          // used file is automatically evicted. This prevents the cache from
          // consuming excessive storage space. 200 is a reasonable default.
          maxNrOfCacheObjects: 200,

          // fileService: The service responsible for fetching the files.
          // The default HttpFileService is used here, which is suitable for
          // downloading images over standard HTTP/HTTPS protocols.
          fileService: HttpFileService(),
        ),
      );
    return _instance!;
  }
}
