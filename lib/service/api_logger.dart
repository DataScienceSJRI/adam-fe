import 'package:http/http.dart' as http;

class LoggingClient extends http.BaseClient {
  final http.Client _inner = http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    // --- 1. Log Outgoing Request ---
    print('╔════════════════ NETWORK REQUEST ════════════════╗');
    print('║ 🚀 METHOD : ${request.method}');
    print('║ 🔗 URL    : ${request.url}');
    print('║ 📑 HEADERS: ${request.headers}');

    if (request is http.Request && request.body.isNotEmpty) {
      print('║ 📦 BODY   : ${request.body}');
    }
    print('╚═════════════════════════════════════════════════╝');

    // Execute the actual request
    final response = await _inner.send(request);

    // --- 2. Intercept and Log Response ---
    // We split the stream so we can read the body for logging without breaking the response data flow
    final bytes = await response.stream.toBytes();
    final responseBody = String.fromCharCodes(bytes);

    print('╔════════════════ NETWORK RESPONSE ═══════════════╗');
    print('║ 🔗 URL    : ${request.url}');
    print('║ 🚦 STATUS : ${response.statusCode}');
    print('║ 📦 BODY   : $responseBody');
    print('╚═════════════════════════════════════════════════╝');

    // Return a new streamed response since the original stream was already consumed by us
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