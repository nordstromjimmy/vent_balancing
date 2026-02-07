import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/projects_controller.dart';
import '../overview/overview_page.dart';
import 'add_measurement_point_dialog.dart';
import 'measure_tab.dart';
import 'overview_types.dart';
import 'project_editor_actions.dart';

class ProjectEditorPage extends ConsumerStatefulWidget {
  const ProjectEditorPage({super.key, required this.projectId});
  final String projectId;

  @override
  ConsumerState<ProjectEditorPage> createState() => _ProjectEditorPageState();
}

class _ProjectEditorPageState extends ConsumerState<ProjectEditorPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  OverviewFilter _filter = OverviewFilter.all;
  OverviewSort _sort = OverviewSort.worstDeviation;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _addPoint(BuildContext context) async {
    final points = await showAddMeasurementPointDialog(context);
    if (points == null || points.isEmpty) return;

    await ref
        .read(projectsControllerProvider.notifier)
        .addPoints(widget.projectId, points);
  }

  @override
  Widget build(BuildContext context) {
    final projectsAsync = ref.watch(projectsControllerProvider);

    final project = projectsAsync.whenOrNull(
      data: (projects) => projects.firstWhere(
        (p) => p.id == widget.projectId,
        orElse: () => throw StateError('Project not found'),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(project?.name ?? 'Project'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(icon: Icon(Icons.edit), text: 'Mätningar'),
            Tab(icon: Icon(Icons.assessment), text: 'Överblick'),
          ],
        ),
        actions: [
          ProjectEditorActions(projectId: widget.projectId, project: project),
        ],
      ),
      body: projectsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
        data: (projects) {
          final p = projects.firstWhere(
            (x) => x.id == widget.projectId,
            orElse: () => throw StateError('Project not found'),
          );

          return TabBarView(
            controller: _tabs,
            children: [
              MeasureTab(projectId: p.id),
              OverviewPage(
                projectId: p.id,
                filter: _filter,
                sort: _sort,
                onFilterChanged: (f) => setState(() => _filter = f),
                onSortChanged: (s) => setState(() => _sort = s),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: project == null ? null : () => _addPoint(context),
        icon: const Icon(Icons.add),
        label: const Text('Nytt flöde'),
      ),
    );
  }
}
