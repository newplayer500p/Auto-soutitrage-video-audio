// processing_page_design.dart
import 'package:flutter/material.dart';
import 'package:front_end/pages/helper/make_absolute_url.dart';
import 'package:front_end/services/download_serive.dart';
import 'package:front_end/services/sse_service.dart';
import 'package:front_end/services/task_model.dart';
import '../widgets/task_tile.dart';

class ProcessingPage extends StatefulWidget {
  final String baseUrl;
  final String jobId;
  final List<Task> initialTasks;

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
  final Map<String, Task> _tasks = {};
  final StringBuffer _logBuffer = StringBuffer();
  SseService? _sseService;
  bool _connected = false;
  bool _showLogs = false;

  @override
  void initState() {
    super.initState();
    _initializeTasks();
    _startSseConnection();
  }

  void _initializeTasks() {
    for (final task in widget.initialTasks) {
      _tasks[task.id] = task;
    }
  }

  void _startSseConnection() {
    _sseService =
        SseService(
            baseUrl: widget.baseUrl,
            jobId: widget.jobId,
            onEvent: _handleSseEvent,
            onLog: _addLog,
          )
          ..connect().catchError((e) {
            _addLog('Connection failed: $e');
            setState(() => _connected = false);
          });

    setState(() => _connected = true);
  }

  void _handleSseEvent(Map<String, dynamic> event) {
    final eventType = event['event'] as String?;
    final payload = event['payload'] as Map<String, dynamic>? ?? {};

    _addLog("Event: $eventType - Payload: $payload");

    switch (eventType) {
      case 'task_started':
        _updateTaskStatus(payload['task'], 'in_progress');
      case 'task_finished':
        _updateTask(payload['task'], 'done', payload);
      case 'error':
        _handleError(payload);
      case 'finished':
        _handleFinished(payload);
    }
  }

  void _updateTask(
    String? taskId,
    String status,
    Map<String, dynamic> payload,
  ) {
    if (taskId == null) return;

    setState(() {
      final task = _tasks[taskId];
      if (task != null) {
        task.status = status;
        if (payload.containsKey('info')) task.info = payload['info'];
        if (payload.containsKey('data')) task.data = payload['data'];
        if (payload.containsKey('download')) {
          task.download =
              payload['download'].toString().toLowerCase() == 'true';
        }
      }
    });
  }

  void _updateTaskStatus(String? taskId, String status) {
    if (taskId != null) {
      setState(() => _tasks[taskId]?.status = status);
    }
  }

  void _handleError(Map<String, dynamic> payload) {
    final taskId = payload['task'] as String?;
    setState(() {
      if (taskId != null) {
        _tasks[taskId]?.status = 'error';
        _tasks[taskId]?.info = payload;
      } else {
        _tasks['finished']?.status = 'error';
        _tasks['finished']?.info = payload;
      }
    });
  }

  void _handleFinished(Map<String, dynamic> payload) {
    setState(() {
      _tasks['finished']?.status = 'done';
      _tasks['finished']?.info = payload.containsKey('data')
          ? payload['data']
          : payload;
      if (payload.containsKey('download')) {
        _tasks['finished']?.download =
            payload['download'].toString().toLowerCase() == 'true';
      }
    });
  }

  void _addLog(String line) {
    setState(
      () => _logBuffer.writeln(
        "${DateTime.now().toString().split('.')[0]}: $line",
      ),
    );
  }

  void _onDownload(Task task) async {
    final path = task.data as String?;
    if (path == null || path.isEmpty) return;

    try {
      final fullUrl = makeAbsolute(widget.baseUrl, path);
      final filename = path.split('/').last;
      await Downloader().downloadFile(fullUrl, filename);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Téléchargement lancé: $filename"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erreur téléchargement: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _sseService?.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tasks = widget.initialTasks.map((t) => _tasks[t.id] ?? t).toList();
    final completedTasks = tasks.where((t) => t.status == 'done').length;
    final totalTasks = tasks.length;
    final double progress = totalTasks > 0 ? completedTasks / totalTasks : 0;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text("Traitement en cours"),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            icon: Icon(_showLogs ? Icons.visibility_off : Icons.visibility),
            onPressed: () => setState(() => _showLogs = !_showLogs),
            tooltip: _showLogs ? "Masquer les logs" : "Afficher les logs",
          ),
        ],
      ),
      body: Column(
        children: [
          // Header avec progression
          _buildProgressHeader(progress, completedTasks, totalTasks),

          // Indicateur de connexion
          if (!_connected) _buildConnectionWarning(),

          // Liste des tâches
          Expanded(
            child: Card(
              margin: EdgeInsets.all(16),
              elevation: 3,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      "Étapes du traitement",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
                      ),
                    ),
                    SizedBox(height: 16),
                    Expanded(
                      child: ListView.separated(
                        itemCount: tasks.length,
                        separatorBuilder: (_, i) => Divider(height: 1),
                        itemBuilder: (_, i) => TaskTileDesign(
                          task: tasks[i],
                          onDownload: () => _onDownload(tasks[i]),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Section logs (réduisible)
          if (_showLogs) _buildLogPanel(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).pop(),
        child: Icon(Icons.arrow_back),
        backgroundColor: Colors.blue[700],
      ),
    );
  }

  Widget _buildProgressHeader(double progress, int completed, int total) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue[600]!, Colors.blue[800]!],
        ),
      ),
      child: Column(
        children: [
          Text(
            "Job #${widget.jobId.substring(0, 8)}...",
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w300,
            ),
          ),
          SizedBox(height: 16),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.blue[200],
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          SizedBox(height: 8),
          Text(
            "$completed/$total étapes complétées (${(progress * 100).toStringAsFixed(0)}%)",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionWarning() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12),
      color: Colors.orange[50],
      child: Row(
        children: [
          Icon(Icons.wifi_off, color: Colors.orange),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              "Connexion perdue - Tentative de reconnexion...",
              style: TextStyle(color: Colors.orange[800]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogPanel() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(Icons.terminal, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  "Logs de débogage",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Spacer(),
                IconButton(
                  icon: Icon(Icons.clear_all, color: Colors.white),
                  onPressed: () => setState(() => _logBuffer.clear()),
                  tooltip: "Effacer les logs",
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              padding: EdgeInsets.all(8),
              child: SingleChildScrollView(
                reverse: true,
                child: Text(
                  _logBuffer.toString(),
                  style: TextStyle(
                    color: Colors.green[300],
                    fontFamily: 'Monospace',
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
