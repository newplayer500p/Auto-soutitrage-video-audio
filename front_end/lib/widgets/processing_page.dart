// processing_page.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:front_end/pages/helper/make_absolute_url.dart';
import 'package:front_end/services/download_serive.dart';
import 'package:http/http.dart' as http;

class ProcessingPage extends StatefulWidget {
  final String baseUrl; // ex: "http://localhost:8000"
  final String jobId;
  final List<Map<String, dynamic>> initialTasks;

  const ProcessingPage({
    super.key,
    required this.baseUrl,
    required this.jobId,
    required this.initialTasks,
  });

  @override
  State<ProcessingPage> createState() => _ProcessingPageState();
}

class _ProcessingPageState extends State<ProcessingPage> {
  late Map<String, Map<String, dynamic>> tasksMap;
  StreamSubscription<String>? _sseSubscription;
  bool _connected = false;
  String _log = "";

  @override
  void initState() {
    super.initState();
    tasksMap = {
      for (var t in widget.initialTasks)
        t['id'] as String: Map<String, dynamic>.from(t),
    };
    _startListening();
  }

  void _addLog(String line) {
    setState(() {
      _log = "$_log$line\n";
    });
  }

  Future<void> _startListening() async {
    final uri = Uri.parse(
      "${widget.baseUrl.replaceAll(RegExp(r'/$'), '')}/stream/${widget.jobId}",
    );
    final client = http.Client();
    try {
      final request = http.Request('GET', uri);
      final streamed = await client.send(request);

      // SSE parsing: accumule les lignes 'data: ...' jusqu'à empty line \n\n
      final controller = StreamController<String>();
      StringBuffer buffer = StringBuffer();
      streamed.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(
            (line) {
              if (line.startsWith('data:')) {
                buffer.writeln(line.substring(5).trim());
              } else if (line.isEmpty) {
                final dataText = buffer.toString().trim();
                buffer.clear();
                if (dataText.isNotEmpty) {
                  controller.add(dataText);
                }
              } else if (line.startsWith(':')) {
                // keepalive comment - ignore
              } else {
                // other SSE fields (id:, event:) - ignore for now
              }
            },
            onDone: () {
              controller.close();
              _addLog("SSE stream closed by server");
              setState(() => _connected = false);
            },
            onError: (e) {
              controller.close();
              _addLog("SSE error: $e");
              setState(() => _connected = false);
            },
          );

      _sseSubscription = controller.stream.listen((dataChunk) {
        try {
          final obj = jsonDecode(dataChunk) as Map<String, dynamic>;
          _handleSseEvent(obj);
        } catch (e) {
          _addLog("Invalid JSON SSE: $e - payload: $dataChunk");
        }
      });

      setState(() => _connected = true);
    } catch (e) {
      _addLog("Impossible d'ouvrir SSE: $e");
      setState(() => _connected = false);
    }
  }

  void _handleSseEvent(Map<String, dynamic> obj) {
    final event = obj['event'] as String?;
    final payload = obj['payload'] as Map<String, dynamic>? ?? {};
    _addLog("evt: $event payload: $payload");

    // Use canonical fields from backend:
    // - payload['task'] : id de la tâche
    // - payload['data'] : contenu (string path OR map)
    // - payload['info'] : message humain
    // - payload['download'] : "True"/"False" (backend currently returns strings)

    if (event == 'task_started') {
      final taskId = payload['task'] as String?;
      if (taskId != null) {
        setState(() {
          tasksMap[taskId]?['status'] = 'in_progress';
        });
      }
    } else if (event == 'task_finished') {
      final taskId = payload['task'] as String?;
      if (taskId != null) {
        setState(() {
          tasksMap[taskId]?['status'] = 'done';
          // info pour affichage humain
          if (payload.containsKey('info')) {
            tasksMap[taskId]?['info'] = payload['info'];
          }
          // data pour download
          if (payload.containsKey('data')) {
            tasksMap[taskId]?['data'] = payload['data'];
          }
          if (payload.containsKey('download')) {
            tasksMap[taskId]?['download'] =
                (payload['download'].toString().toLowerCase() == 'true');
          }
        });
      }
    } else if (event == 'error') {
      final taskId = payload['task'] as String?;
      setState(() {
        if (taskId != null) {
          tasksMap[taskId]?['status'] = 'error';
          tasksMap[taskId]?['info'] = payload;
        } else {
          // global error
          tasksMap['finished']?['status'] = 'error';
          tasksMap['finished']?['info'] = payload;
        }
      });
    } else if (event == 'finished') {
      // job global terminé: backend sends 'data' maybe with final path
      final dataOrInfo = payload.containsKey('data')
          ? payload['data']
          : payload;
      setState(() {
        tasksMap['finished']?['status'] = 'done';
        tasksMap['finished']?['info'] = dataOrInfo;
        if (payload.containsKey('download')) {
          tasksMap['finished']?['download'] =
              (payload['download'].toString().toLowerCase() == 'true');
        }
      });
    }
  }

  @override
  void dispose() {
    _sseSubscription?.cancel();
    super.dispose();
  }

  Widget _buildTile(Map<String, dynamic> t) {
    final status = (t['status'] as String?) ?? 'pending';
    final label = t['label'] ?? t['id'];
    final infoRaw = t['info'];
    final subtitleText = _subtitleTextFromInfo(infoRaw);

    Widget leading;
    if (status == 'pending') {
      leading = Icon(Icons.schedule, color: Colors.grey);
    } else if (status == 'in_progress') {
      leading = SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    } else if (status == 'done') {
      leading = Icon(Icons.check_circle, color: Colors.green);
    } else if (status == 'error') {
      leading = Icon(Icons.error, color: Colors.red);
    } else {
      leading = Icon(Icons.circle);
    }

    return ListTile(
      leading: leading,
      title: Text(label),
      subtitle: subtitleText != null ? Text(subtitleText) : null,
      trailing: _downloadButtonIfAvailable(t),
    );
  }

  String? _subtitleTextFromInfo(dynamic info) {
    if (info == null) return null;
    if (info is String) return info;
    try {
      return jsonEncode(info);
    } catch (_) {
      return info.toString();
    }
  }

  Widget? _downloadButtonIfAvailable(Map<String, dynamic> t) {
    final status = t['status'] as String?;
    final infoRaw = t['info'];
    final downloadFlag = t['download'] as bool? ?? false;

    // Heuristique simple :
    // - si la tâche est 'done' et download flag vrai -> on cherche une URL/chemin dans info
    // - si info est String => on suppose c'est un chemin relatif (ex: /uploads/...)
    // - si info est Map => on regarde 'data' (string) ou fouille tout map pour une string
    if (status == 'done' && (downloadFlag || _looksLikePath(infoRaw))) {
      final path = t['data'] as String?; // <-- pour le download
      if (path != null && path.isNotEmpty) {
        final fullUrl = makeAbsolute(widget.baseUrl, path);
        final filename = path.split('/').last;
        return IconButton(
          icon: Icon(Icons.download),
          onPressed: () => _onDownload(fullUrl, filename),
          tooltip: "Télécharger",
        );
      }
    }
    return null;
  }

  bool _looksLikePath(dynamic info) {
    if (info == null) return false;
    if (info is String) {
      return info.contains("/uploads") || info.startsWith("/");
    }
    return false;
  }

  /// Retourne la première valeur string qui ressemble à un chemin/url dans `info`

  void _onDownload(String url, String filename) async {
    try {
      await Downloader().downloadFile(url, filename);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Téléchargement lancé: $filename")),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erreur téléchargement: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Build tasks in the same order as initialTasks to preserve UI order
    final tasks = [
      for (var t in widget.initialTasks)
        tasksMap[t['id']] ??
            Map<String, dynamic>.from({
              'id': t['id'],
              'label': t['label'],
              'status': 'pending',
              'info': null,
            }),
    ];

    return Scaffold(
      appBar: AppBar(title: Text("Traitement — job ${widget.jobId}")),
      body: Column(
        children: [
          if (!_connected)
            Container(
              color: Colors.yellow[100],
              padding: EdgeInsets.all(8),
              child: Row(
                children: [
                  Icon(Icons.wifi_off),
                  SizedBox(width: 8),
                  Flexible(
                    child: Text("Connexion SSE non établie / interrompue."),
                  ),
                ],
              ),
            ),
          Expanded(
            child: ListView.builder(
              itemCount: tasks.length,
              itemBuilder: (_, i) => _buildTile(tasks[i]),
            ),
          ),
          Divider(),
          Padding(
            padding: EdgeInsets.all(8),
            child: Row(
              children: [
                ElevatedButton.icon(
                  icon: Icon(Icons.arrow_back),
                  label: Text("Retour"),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Log: (debug)\n$_log",
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
