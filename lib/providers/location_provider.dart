import 'package:flutter/material.dart';
import '../models/country.dart';
import '../models/state_province.dart';
import '../services/api_service.dart';

class LocationProvider with ChangeNotifier {
  final ApiService apiService;
  LocationProvider({required this.apiService});

  List<Country> _countries = [];
  List<StateProvince> _states = [];
  bool _isLoadingCountries = false;
  bool _isLoadingStates = false;
  String? _errorCountries;
  String? _errorStates;

  List<Country> get countries => _countries;
  List<StateProvince> get states => _states;
  bool get isLoadingCountries => _isLoadingCountries;
  bool get isLoadingStates => _isLoadingStates;
  String? get errorCountries => _errorCountries;
  String? get errorStates => _errorStates;

  Future<void> fetchCountries() async {
    _isLoadingCountries = true;
    _errorCountries = null;
    notifyListeners();
    try {
      final response = await apiService.get<Map<String, dynamic>>('/countries');
      if (response['statusCode'] == 200 && response['data'] is List) {
        _countries = (response['data'] as List)
            .map((item) => Country.fromJson(item))
            .toList();
      } else {
        _errorCountries = response['message'] ?? 'Failed to fetch countries';
      }
    } catch (e) {
      _errorCountries = e.toString();
    }
    _isLoadingCountries = false;
    notifyListeners();
  }

  Future<void> fetchStates(int countryId) async {
    _isLoadingStates = true;
    _errorStates = null;
    notifyListeners();
    try {
      final response = await apiService.get<Map<String, dynamic>>('/states/$countryId');
      if (response['statusCode'] == 200 && response['data'] is List) {
        _states = (response['data'] as List)
            .map((item) => StateProvince.fromJson(item))
            .toList();
      } else {
        _errorStates = response['message'] ?? 'Failed to fetch states';
      }
    } catch (e) {
      _errorStates = e.toString();
    }
    _isLoadingStates = false;
    notifyListeners();
  }

  void clearStates() {
    _states = [];
    notifyListeners();
  }
}
