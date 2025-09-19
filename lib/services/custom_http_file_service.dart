import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:http/http.dart' as http;

/// A custom FileService to bypass server-side cache-control headers.
class CustomHttpFileService extends HttpFileService {
  final http.Client _httpClient;

  CustomHttpFileService({http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  @override
  Future<FileServiceResponse> get(String url, {Map<String, String>? headers}) async {
    final Uri uri = Uri.parse(url);
    final http.StreamedResponse response = await _httpClient.send(
      http.Request('GET', uri)..headers.addAll(headers ?? {}),
    );

    // This is where we return our custom response handler.
    return CustomFileServiceResponse(response);
  }
}

/// A custom FileServiceResponse that overrides the cache validity.
class CustomFileServiceResponse extends HttpGetResponse {
  CustomFileServiceResponse(super.response);

  @override
  DateTime get validTill {
    // This is the magic. 🧙‍♂️
    // We ignore the 'Cache-Control' header from the server and force
    // the cache to be valid for 365 days.
    return DateTime.now().add(const Duration(days: 365));
  }
}