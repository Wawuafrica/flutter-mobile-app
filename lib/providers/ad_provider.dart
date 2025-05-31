import 'package:wawu_mobile/providers/base_provider.dart';
import '../models/ad.dart';
import '../services/api_service.dart';

class AdProvider extends BaseProvider {
  final ApiService _apiService;
  List<Ad> _ads = [];

  AdProvider({required ApiService apiService})
    : _apiService = apiService,
      super();

  List<Ad> get ads => _ads;

  Future<void> fetchAds() async {
    setLoading();

    try {
      print('AdProvider: Fetching from .../ads?paginate=1&pageNumber=1');
      final response = await _apiService.get(
        '/ads?paginate=1&pageNumber=1',
        fromJson: (data) {
          final List<dynamic> adsData = data['data'];
          return adsData.map((json) => Ad.fromJson(json)).toList();
        },
      );
      print('AdProvider: Ads fetched successfully: ${response.length} ads');
      setSuccess();
      _ads = response;
    } catch (e) {
      print('AdProvider: Error fetching ads: $e');
      setError('error message: ${e.toString()}');
    }
  }

  void reset() {
    _ads = [];
    setSuccess();
  }
}
