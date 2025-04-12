class HttpService {
  final String baseUrl = 'http://localhost:3000';

  // Future<http.Response> get(String path) async {
  //   final response = await http.get(Uri.parse('$_baseUrl$path'));

  //   if (response.statusCode == 200) {
  //     return response.body;
  //   } else {
  //     throw Exception('Failed to load data');
  //   }
  // }
}
