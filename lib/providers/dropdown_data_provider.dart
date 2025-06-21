import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:wawu_mobile/models/certification.dart';
import 'package:wawu_mobile/models/institution.dart';
import 'package:wawu_mobile/services/api_service.dart';

class DropdownDataProvider with ChangeNotifier {
  final ApiService _apiService;
  final Logger _logger = Logger();

  DropdownDataProvider({required ApiService apiService})
    : _apiService = apiService;

  List<Certification> _certifications = [];
  List<Institution> _institutions = [];
  bool _isLoading = false;
  String? _error;

  List<Certification> get certifications => _certifications;
  List<Institution> get institutions => _institutions;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchDropdownData() async {
    _logger.i('Attempting to fetch dropdown data...');
    if (_certifications.isNotEmpty && _institutions.isNotEmpty) {
      _logger.i(
        'Certification and institution data already exist. Skipping fetch.',
      );
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final certResponseFuture = _apiService.get('/certification');
      final instResponseFuture = _apiService.get('/institution');

      final responses = await Future.wait([
        certResponseFuture,
        instResponseFuture,
      ]);

      final certResponse = responses[0];
      _logger.d('Certification API Response: $certResponse');
      if (certResponse['statusCode'] == 200) {
        _certifications =
            (certResponse['data'] as List)
                .map((item) => Certification.fromJson(item))
                .toList();
        _logger.d('Parsed Certifications: $_certifications');
      } else {
        throw 'Failed to fetch certifications';
      }

      final instResponse = responses[1];
      _logger.d('Institution API Response: $instResponse');
      if (instResponse['statusCode'] == 200) {
        _institutions =
            (instResponse['data'] as List)
                .map((item) => Institution.fromJson(item))
                .toList();
        _logger.d('Parsed Institutions: $_institutions');
      } else {
        throw 'Failed to fetch institutions';
      }
    } catch (e) {
      _logger.e('Error fetching dropdown data: $e');
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
