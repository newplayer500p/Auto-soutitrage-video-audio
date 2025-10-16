// historique_traitement_page.dart
import 'package:flutter/material.dart';
import 'package:front_end/navigation/nav_bar.dart';
import 'package:front_end/pages/job_detaille_page.dart';
import 'package:front_end/services/api_service.dart';
import 'package:front_end/pages/helper/make_absolute_url.dart';
import 'package:front_end/services/download_serive.dart';

class HistoriqueTraitementPage extends StatefulWidget {
  final String baseUrl;
  final ApiService api;

  HistoriqueTraitementPage({
    super.key,
    required this.baseUrl,
    ApiService? apiService,
  }) : api = apiService ?? ApiService(baseUrl);

  @override
  State<HistoriqueTraitementPage> createState() =>
      _HistoriqueTraitementPageState();
}

class _HistoriqueTraitementPageState extends State<HistoriqueTraitementPage> {
  late Future<List<Map<String, dynamic>>> _jobsFuture;

  @override
  void initState() {
    super.initState();
    _loadJobs();
  }

  void _loadJobs() {
    _jobsFuture = widget.api.getJobs();
  }

  Future<void> _refresh() async {
    setState(() => _loadJobs());
    await _jobsFuture;
  }

  void _downloadFile(String path) async {
    try {
      final url = makeAbsolute(widget.baseUrl, path);
      final filename = path.split('/').last;
      await Downloader().downloadFile(url, filename);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Téléchargement lancé : $filename')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur téléchargement : $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildFileTile(Map<String, dynamic> file) {
    final String path = file['path'] ?? '';
    final String type = file['file_type'] ?? 'file';
    final String createdAt = file['created_at'] ?? '';
    final bool downloadable = path.isNotEmpty;

    return ListTile(
      title: Text(preserveFilename(path, type)),
      subtitle: Text('$type • ${createdAt.isNotEmpty ? createdAt : "—"}'),
      trailing: downloadable
          ? IconButton(
              icon: const Icon(Icons.download),
              tooltip: 'Télécharger',
              onPressed: () => _downloadFile(path),
            )
          : null,
    );
  }

  String preserveFilename(String path, String type) {
    if (path.isEmpty) return '—';
    final parts = path.split('/');
    return parts.isNotEmpty ? parts.last : path;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: Column(
          children: [
            TopNavBar(
              currentRoute: '/history',
              onRouteChanged: (route) {
                Navigator.pushReplacementNamed(context, route);
              },
            ),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _jobsFuture,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snap.hasError) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        const SizedBox(height: 60),
                        Icon(
                          Icons.error_outline,
                          color: Colors.red[700],
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: Text(
                            'Erreur lors du chargement des jobs : ${snap.error}',
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    );
                  } else {
                    final jobs = snap.data ?? [];
                    if (jobs.isEmpty) {
                      return ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: const [
                          SizedBox(height: 80),
                          Center(child: Text('Aucun traitement trouvé')),
                        ],
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: jobs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, i) {
                        final job = jobs[i];
                        final String id = job['id'] ?? 'unknown';
                        final String status = job['status'] ?? 'unknown';
                        final String start = job['start_time'] ?? '';
                        final String end = job['end_time'] ?? '';
                        final message = job['message'] ?? '';

                        final files = (job['files'] as List<dynamic>?) ?? [];

                        return Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Header row
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Job: ${id.substring(0, 8)}...',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Statut: $status',
                                            style: TextStyle(
                                              color: status == 'finished'
                                                  ? Colors.green[700]
                                                  : status == 'error'
                                                  ? Colors.red[700]
                                                  : Colors.orange[800],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.open_in_new),
                                      tooltip: 'Voir détails',
                                      onPressed: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) => JobDetailPage(
                                              baseUrl: widget.baseUrl,
                                              jobId: id,
                                              apiService: widget.api,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 8),
                                // Date row
                                Row(
                                  children: [
                                    if (start.isNotEmpty)
                                      Text(
                                        'Début: ${start.split(".").first}',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    const SizedBox(width: 12),
                                    if (end.isNotEmpty)
                                      Text(
                                        'Fin: ${end.split(".").first}',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                  ],
                                ),

                                if (message != null &&
                                    (message as String).isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    'Info: $message',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],

                                const SizedBox(height: 8),
                                // Files list (Expansion)
                                ExpansionTile(
                                  title: Text('${files.length} fichier(s)'),
                                  children: files.map((f) {
                                    final file = Map<String, dynamic>.from(
                                      f as Map,
                                    );
                                    return _buildFileTile(file);
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
