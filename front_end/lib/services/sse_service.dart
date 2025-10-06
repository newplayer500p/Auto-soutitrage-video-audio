import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class SseService {
  final String baseUrl;
  final String jobId;
  final void Function(Map<String, dynamic>) onEvent;
  final void Function(String) onLog;

  StreamSubscription<String>? _subscription;
  http.Client? _client;

  SseService({
    required this.baseUrl,
    required this.jobId,
    required this.onEvent,
    required this.onLog,
  });

  Future<void> connect() async {
    final uri = Uri.parse(
      '${baseUrl.replaceAll(RegExp(r'/$'), '')}/stream/$jobId',
    );
    _client = http.Client();

    try {
      final request = http.Request('GET', uri);
      final streamed = await _client!.send(request);

      final controller = StreamController<String>();
      StringBuffer buffer = StringBuffer();

      streamed.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(
            (line) => _parseLine(line, buffer, controller),
            onDone: () => _handleDisconnect('SSE stream closed by server'),
            onError: (e) => _handleDisconnect('SSE error: $e'),
          );

      _subscription = controller.stream.listen(_handleDataChunk);
      onLog('SSE connection established');
    } catch (e) {
      onLog('Failed to establish SSE connection: $e');
      rethrow;
    }
  }

  void _parseLine(
    String line,
    StringBuffer buffer,
    StreamController<String> controller,
  ) {
    if (line.startsWith('data:')) {
      buffer.writeln(line.substring(5).trim());
    } else if (line.isEmpty) {
      final dataText = buffer.toString().trim();
      buffer.clear();
      if (dataText.isNotEmpty) controller.add(dataText);
    } else if (line.startsWith(':')) {
      // Ignore keepalive comments
    }
  }

  void _handleDataChunk(String dataChunk) {
    try {
      final obj = jsonDecode(dataChunk) as Map<String, dynamic>;
      onEvent(obj);
    } catch (e) {
      onLog('Invalid JSON SSE: $e - payload: $dataChunk');
    }
  }

  void _handleDisconnect(String message) {
    onLog(message);
    disconnect();
  }

  void disconnect() {
    _subscription?.cancel();
    _client?.close();
    _subscription = null;
    _client = null;
  }
}
