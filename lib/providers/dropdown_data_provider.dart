import 'package:logger/logger.dart';
import 'package:wawu_mobile/models/certification.dart';
import 'package:wawu_mobile/models/institution.dart';
import 'package:wawu_mobile/providers/base_provider.dart';
import 'package:wawu_mobile/services/api_service.dart';

class DropdownDataProvider extends BaseProvider {
  final ApiService _apiService;
  final Logger _logger = Logger();

  DropdownDataProvider({required ApiService apiService})
    : _apiService = apiService;

  List<Certification> _certifications = [];
  List<Institution> _institutions = [];
  List<Certification> get certifications => _certifications;
  List<Institution> get institutions => _institutions;

  Future<void> fetchDropdownData() async {
    _logger.i('Attempting to fetch dropdown data...');
    if (_certifications.isNotEmpty && _institutions.isNotEmpty) {
      _logger.i(
        'Certification and institution data already exist. Skipping fetch.',
      );
      return;
    }

    setLoading();

    try {
      // Fetch certifications
      final certResponse = await _apiService.get('/certification');
      if (certResponse['statusCode'] == 200 && certResponse['data'] != null) {
        final List<dynamic> certData = certResponse['data'];
        _certifications =
            certData.map((json) => Certification.fromJson(json)).toList();
      } else {
        _logger.e('Failed to fetch certifications: ${certResponse['message']}');
        throw Exception(
          'Failed to fetch certifications: ${certResponse['message']}',
        );
      }

      // Fetch institutions
      final instResponse = await _apiService.get('/institution');
      if (instResponse['statusCode'] == 200 && instResponse['data'] != null) {
        final List<dynamic> instData = instResponse['data'];
        _institutions =
            instData.map((json) => Institution.fromJson(json)).toList();
      } else {
        _logger.e('Failed to fetch institutions: ${instResponse['message']}');
        throw Exception(
          'Failed to fetch institutions: ${instResponse['message']}',
        );
      }

      setSuccess();
    } catch (e) {
      _logger.e('Failed to fetch dropdown data: $e');
      setError(e.toString());
    }
  }

  void clearError() {
    resetState();
  }
}
