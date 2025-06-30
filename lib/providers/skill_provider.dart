import 'package:flutter/material.dart';
import 'package:wawu_mobile/models/skill.dart';
import 'package:wawu_mobile/services/api_service.dart';

class SkillProvider extends ChangeNotifier {
  final ApiService apiService;
  SkillProvider({required this.apiService});

  List<Skill> _skills = [];
  bool _isLoading = false;
  String? _error;

  List<Skill> get skills => _skills;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchSkills() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final response = await apiService.get<Map<String, dynamic>>('/skill');
      if (response['statusCode'] == 200 && response['data'] is List) {
        _skills = (response['data'] as List)
            .map((item) => Skill(
                  id: item['id'].toString(),
                  name: item['name'] ?? '',
                ))
            .toList();
      } else {
        _error = response['message'] ?? 'Failed to fetch skills';
      }
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }
}
