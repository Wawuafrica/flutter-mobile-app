import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class CustomCacheManager {
  static const key = 'customCacheKey';
  static CacheManager instance = CacheManager(
    Config(
      key,
      // How long the file should be cached. After this duration,
      // it will be checked for an update. Set it to a long period
      // like 30 or 90 days.
      stalePeriod: const Duration(days: 30),

      // The maximum number of items you want to store in the cache.
      maxNrOfCacheObjects: 200,

      // Where the files are stored. By default, this is the temporary
      // directory, which can be cleared by the OS. We can specify a
      // more persistent location if needed.
      // fileService: HttpFileService(), // Default
    ),
  );
}