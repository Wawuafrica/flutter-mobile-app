import 'package:flutter/material.dart';
import '../models/link_item.dart';
import '../services/api_service.dart';

class LinksProvider extends ChangeNotifier {
  final ApiService apiService;
  List<LinkItem> _links = [];
  bool _isLoading = false;
  String? _error;

  LinksProvider({required this.apiService});

  List<LinkItem> get links => _links;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchLinks() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final response = await apiService.get('/links');
      if (response['statusCode'] == 200 && response['data'] is List) {
        _links = (response['data'] as List)
            .map((item) => LinkItem.fromJson(item))
            .toList();
      } else {
        _error = response['message']?.toString() ?? 'Unknown error';
      }
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  LinkItem? getLinkByName(String name) {
    try {
      return _links.firstWhere((l) => l.name.toLowerCase() == name.toLowerCase());
    } catch (_) {
      return null;
    }
  }
}
