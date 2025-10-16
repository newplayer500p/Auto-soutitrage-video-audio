// lib/pages/processing_overview_page.dart
import 'package:flutter/material.dart';
import 'package:front_end/navigation/nav_bar.dart';
import 'package:front_end/pages/processing_page.dart';
import 'package:front_end/services/api_service.dart';
import 'package:front_end/services/task_model.dart';

class ProcessingOverviewPage extends StatefulWidget {
  final String baseUrl;
  final ApiService? apiService;

  const ProcessingOverviewPage({
    super.key,
    required this.baseUrl,
    this.apiService,
  });

  @override
  State<ProcessingOverviewPage> createState() => _ProcessingOverviewPageState();
}

class _ProcessingOverviewPageState extends State<ProcessingOverviewPage> {
  late final ApiService api;
  late Future<List<Map<String, dynamic>>> _jobsFuture;

  @override
  void initState() {
    super.initState();
    api = widget.apiService ?? ApiService(widget.baseUrl);
    _jobsFuture = api.getJobs();
  }

  Future<void> _refresh() async {
    setState(() => _jobsFuture = api.getJobs());
    await _jobsFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: Column(
          children: [
            TopNavBar(
              currentRoute: '/processing',
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
                        const SizedBox(height: 80),
                        Center(child: Text('Erreur: ${snap.error}')),
                      ],
                    );
                  } else {
                    final jobs = snap.data ?? [];
                    // chercher un job "en cours"
                    final inProgress = jobs.firstWhere((j) {
                      final s = (j['status'] ?? '').toString().toLowerCase();
                      return !(s == 'finished' ||
                          s == 'error' ||
                          s == 'canceled');
                    }, orElse: () => {});

                    if (inProgress.isEmpty) {
                      return ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          const SizedBox(height: 80),
                          const Center(
                            child: Text('Aucun traitement en cours'),
                          ),
                          const SizedBox(height: 12),
                          Center(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.upload_file),
                              label: const Text('Aller à Upload'),
                              onPressed: () =>
                                  Navigator.pushNamed(context, '/upload'),
                            ),
                          ),
                        ],
                      );
                    }

                    final job = Map<String, dynamic>.from(inProgress as Map);
                    final jobId = job['id'] as String? ?? '';

                    return ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Card(
                          child: ListTile(
                            title: Text('Job ${jobId.substring(0, 8)}...'),
                            subtitle: Text('Status: ${job['status'] ?? '—'}'),
                            trailing: ElevatedButton(
                              onPressed: () {
                                // ouvre la page de traitement détaillée (ProcessingPage)
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ProcessingPageRouteWrapper(
                                      baseUrl: widget.baseUrl,
                                      jobId: jobId,
                                    ),
                                  ),
                                );
                              },
                              child: const Text('Voir'),
                            ),
                          ),
                        ),
                      ],
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

// ... dans le même fichier ProcessingOverviewPage : remplace l'ancien wrapper par ceci

class ProcessingPageRouteWrapper extends StatelessWidget {
  final String baseUrl;
  final String jobId;

  const ProcessingPageRouteWrapper({
    super.key,
    required this.baseUrl,
    required this.jobId,
  });

  @override
  Widget build(BuildContext context) {
    final api = ApiService(baseUrl);

    return FutureBuilder<Map<String, dynamic>>(
      future: api.getJobById(jobId),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (snap.hasError) {
          return Scaffold(
            appBar: AppBar(title: Text('Job ${jobId.substring(0, 8)}...')),
            body: Center(child: Text('Erreur: ${snap.error}')),
          );
        } else {
          final job = snap.data ?? {};
          // récupération des tasks : backend peut renvoyer 'tasks' (list) ou 'tasks' absent
          final rawTasks = (job['tasks'] as List<dynamic>?) ?? [];
          final List<Task> tasks = rawTasks.map((t) {
            final map = Map<String, dynamic>.from(t as Map);
            return Task.fromMap(map);
          }).toList();

          return ProcessingPage(
            baseUrl: baseUrl,
            jobId: jobId,
            initialTasks: tasks,
          );
        }
      },
    );
  }
}
