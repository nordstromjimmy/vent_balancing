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
    // Trigger a rebuild when the tab index changes so the FAB can hide/show.
    _tabs.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _addPoint(BuildContext context, Project project) async {
    final points = await showAddMeasurementPointDialog(
      context,
      tolerancePct: project.defaultTolerancePct,
    );
    if (points == null || points.isEmpty) return;

    await ref
        .read(projectsControllerProvider.notifier)
        .addPoints(widget.projectId, points);
  }

  @override
  Widget build(BuildContext context) {
    // ref.listen fires once per state change — the correct way to trigger
    // navigation as a side effect without scheduling multiple callbacks.
    ref.listen<AsyncValue<List<Project>>>(projectsControllerProvider, (
      _,
      next,
    ) {
      next.whenData((projects) {
        final exists = projects.any((p) => p.id == widget.projectId);
        if (!exists && mounted) Navigator.of(context).pop();
      });
    });

    final projectsAsync = ref.watch(projectsControllerProvider);

    final Project? project = projectsAsync.whenOrNull(
      data: (projects) =>
          projects.where((p) => p.id == widget.projectId).firstOrNull,
    );

    // Only show the FAB on the Mätningar tab (index 0).
    // _tabs.indexIsChanging is true mid-swipe — checking only index means the
    // FAB hides/shows as soon as the tab settles, not mid-animation.
    final showFab = _tabs.index == 0;

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
        data: (_) {
          if (project == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return TabBarView(
            controller: _tabs,
            physics: const NeverScrollableScrollPhysics(),
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
          );
        },
      ),
      floatingActionButton: showFab
          ? FloatingActionButton.extended(
              onPressed: project == null
                  ? null
                  : () => _addPoint(context, project),
              icon: const Icon(Icons.add),
              label: const Text('Nytt flöde'),
            )
          : null,
    );
  }
}
