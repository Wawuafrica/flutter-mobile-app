import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:wawu_mobile/providers/base_provider.dart';
import '../models/ad.dart';
import '../services/api_service.dart';

class AdProvider extends BaseProvider {
  final ApiService _apiService;
  List<Ad> _ads = [];
  bool _isLoading = false;
  String? _errorMessage;

  AdProvider({required ApiService apiService})
    : _apiService = apiService,
      super() {
    // TODO: implement AdProvider
    throw UnimplementedError();
  }

  List<Ad> get ads => _ads;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

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
      _errorMessage = null;
    } catch (e) {
      print('AdProvider: Error fetching ads: $e');
      setError('error message: ${e.toString()}');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void reset() {
    _ads = [];
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }
}
