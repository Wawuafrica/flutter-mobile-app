import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../models/ad.dart';
import '../services/api_service.dart';

class AdProvider extends ChangeNotifier {
  final ApiService _apiService;
  List<Ad> _ads = [];
  bool _isLoading = false;
  String? _errorMessage;

  AdProvider({required ApiService apiService}) : _apiService = apiService;

  List<Ad> get ads => _ads;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchAds() async {
    if (_isLoading) return; // Prevent multiple concurrent fetches

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

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
      _ads = response;
      _errorMessage = null;
    } catch (e) {
      print('AdProvider: Error fetching ads: $e');
      if (e is DioException) {
        _errorMessage = 'Failed to load ads: ${e.message}';
        if (e.response != null) {
          _errorMessage ?? ' (Status: ${e.response!.statusCode})';
        }
        if (e.type == DioExceptionType.connectionError) {
          _errorMessage ?? ' - Check CORS or network connectivity';
        }
      } else {
        _errorMessage = 'Failed to load ads: ${e.toString()}';
      }
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