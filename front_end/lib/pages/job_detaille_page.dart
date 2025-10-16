// job_detail_page.dart
import 'package:flutter/material.dart';
import 'package:front_end/services/api_service.dart';
import 'package:front_end/pages/helper/make_absolute_url.dart';
import 'package:front_end/services/download_serive.dart';

class JobDetailPage extends StatefulWidget {
  final String baseUrl;
  final String jobId;
  final ApiService? apiService;

  const JobDetailPage({
    super.key,
    required this.baseUrl,
    required this.jobId,
    this.apiService,
  });

  @override
  State<JobDetailPage> createState() => _JobDetailPageState();
}

class _JobDetailPageState extends State<JobDetailPage> {
  late final ApiService _api;
  late Future<Map<String, dynamic>> _jobFuture;

  @override
  void initState() {
    super.initState();
    _api = widget.apiService ?? ApiService(widget.baseUrl);
    _jobFuture = _api.getJobById(widget.jobId);
  }

  void _download(String path) async {
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
        SnackBar(content: Text('Erreur : $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Job ${widget.jobId.substring(0, 8)}...')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _jobFuture,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snap.hasError) {
            return Center(child: Text('Erreur: ${snap.error}'));
          } else {
            final job = snap.data!;
            final files = (job['files'] as List<dynamic>?) ?? [];

            return ListView(
              padding: const EdgeInsets.all(12),
              children: [
                ListTile(
                  title: const Text('Statut'),
                  subtitle: Text(job['status'] ?? '—'),
                ),
                ListTile(
                  title: const Text('Début'),
                  subtitle: Text(job['start_time'] ?? '—'),
                ),
                ListTile(
                  title: const Text('Fin'),
                  subtitle: Text(job['end_time'] ?? '—'),
                ),
                const Divider(),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    'Fichiers',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                ...files.map((f) {
                  final file = Map<String, dynamic>.from(f as Map);
                  final path = file['path'] ?? '';
                  final name = path.isNotEmpty ? path.split('/').last : '—';
                  return ListTile(
                    title: Text(name),
                    subtitle: Text(file['file_type'] ?? 'file'),
                    trailing: path.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.download),
                            onPressed: () => _download(path),
                          )
                        : null,
                  );
                }).toList(),
              ],
            );
          }
        },
      ),
    );
  }
}
