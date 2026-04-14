import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/projects_controller.dart';
import '../../domain/project.dart';
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

  Future<void> _addPoint(BuildContext context, Project project) async {
    final points = await showAddMeasurementPointDialog(
      context,
      tolerancePct: project.defaultTolerancePct, // ← wired through
    );
    if (points == null || points.isEmpty) return;

    await ref
        .read(projectsControllerProvider.notifier)
        .addPoints(widget.projectId, points);
  }

  @override
  Widget build(BuildContext context) {
    final projectsAsync = ref.watch(projectsControllerProvider);

    // ← compute once, used for AppBar title, FAB guard, and actions
    final Project? project = projectsAsync.whenOrNull(
      data: (projects) {
        try {
          return projects.firstWhere((p) => p.id == widget.projectId);
        } catch (_) {
          return null;
        }
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(project?.name ?? 'Projekt'),
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
        data: (_) => TabBarView(
          controller: _tabs,
          children: [
            MeasureTab(projectId: widget.projectId),
            OverviewPage(
              projectId: widget.projectId,
              filter: _filter,
              sort: _sort,
              onFilterChanged: (f) => setState(() => _filter = f),
              onSortChanged: (s) => setState(() => _sort = s),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: project == null ? null : () => _addPoint(context, project),
        icon: const Icon(Icons.add),
        foregroundColor: Colors.white,
        backgroundColor: Colors.black54,
        label: const Text('Nytt flöde'),
      ),
    );
  }
}
