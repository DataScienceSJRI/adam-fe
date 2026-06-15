import 'package:http/http.dart' as http;

class LoggingClient extends http.BaseClient {
  final http.Client _inner = http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    print('╔════════════════ NETWORK REQUEST ════════════════╗');
    print('║ 🚀 METHOD : ${request.method}');
    print('║ 🔗 URL    : ${request.url}');
    print('║ 📑 HEADERS: ${request.headers}');

    if (request is http.Request && request.body.isNotEmpty) {
      print('║ 📦 BODY   : ${request.body}');
    }
    print('╚═════════════════════════════════════════════════╝');

    final response = await _inner.send(request);

    final bytes = await response.stream.toBytes();
    final responseBody = String.fromCharCodes(bytes);

    print('╔════════════════ NETWORK RESPONSE ═══════════════╗');
    print('║ 🔗 URL    : ${request.url}');
    print('║ 🚦 STATUS : ${response.statusCode}');
    print('║ 📦 BODY   : $responseBody');
    print('╚═════════════════════════════════════════════════╝');

    return http.StreamedResponse(
      Stream.value(bytes),
      response.statusCode,
      contentLength: response.contentLength,
      request: request,
      headers: response.headers,
      isRedirect: response.isRedirect,
      persistentConnection: response.persistentConnection,
      reasonPhrase: response.reasonPhrase,
    );
  }
}
