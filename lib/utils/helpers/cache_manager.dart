import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:wawu_mobile/services/custom_http_file_service.dart';

class CustomCacheManager {
  // IMPORTANT: Use a new, unique key to prevent conflicts with the old cache.
  static const _cacheKey = 'customCacheKey_ignoreHeaders';

  static CacheManager? _instance;

  CustomCacheManager._();

  static CacheManager get instance {
    _instance ??= CacheManager(
      Config(
        _cacheKey,
        stalePeriod: const Duration(days: 30),
        maxNrOfCacheObjects: 200,
        
        // Here's the change:
        // Plug in your custom file service to handle downloads.
        fileService: CustomHttpFileService(),
      ),
    );
    return _instance!;
  }
}