import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/utils/dialogs.dart';
import '../../../core/widgets/metric_chip.dart';
import '../application/projects_controller.dart';
import '../domain/measurement_point.dart';
import '../domain/flow_eval.dart';
import '../../../core/widgets/ratio_badge.dart';
import 'edit_measurement_point_dialog.dart';
import 'overview_page.dart';

enum OverviewFilter { all, needsWork, badOnly }

enum OverviewSort { label, worstDeviation }

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

  Future<void> _addPointDialog(BuildContext context) async {
    final uuid = const Uuid();

    final labelController = TextEditingController();
    final supplyProjectedController = TextEditingController();
    final exhaustProjectedController = TextEditingController();

    bool includeSupply = true;
    bool includeExhaust = true;

    final result = await showDialog<List<MeasurementPoint>>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            InputDecoration dec(String label, String hint) =>
                InputDecoration(labelText: label, hintText: hint);

            Widget projectedField({
              required String title,
              required TextEditingController controller,
            }) {
              return TextField(
                controller: controller,
                decoration: dec(title, 'e.g. 25'),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                ],
              );
            }

            return AlertDialog(
              title: const Text('Lägg till mätning'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: labelController,
                      decoration: dec('Rum / Etikett', 'e.x Rum 102'),
                      autofocus: true,
                    ),
                    const SizedBox(height: 12),

                    // Multi-select via FilterChips
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilterChip(
                          label: const Text('Tilluft'),
                          selected: includeSupply,
                          onSelected: (v) =>
                              setLocalState(() => includeSupply = v),
                        ),
                        FilterChip(
                          label: const Text('Frånluft'),
                          selected: includeExhaust,
                          onSelected: (v) =>
                              setLocalState(() => includeExhaust = v),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (includeSupply)
                      projectedField(
                        title: 'Projekterad Tilluft (l/s)',
                        controller: supplyProjectedController,
                      ),
                    if (includeSupply) const SizedBox(height: 12),

                    if (includeExhaust)
                      projectedField(
                        title: 'Projekterad Frånluft (l/s)',
                        controller: exhaustProjectedController,
                      ),

                    if (!includeSupply && !includeExhaust)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          'Välj Tilluft och/eller Frånluft.',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Ångra'),
                ),
                FilledButton(
                  onPressed: () {
                    final baseLabel = labelController.text.trim();
                    if (baseLabel.isEmpty) return;
                    if (!includeSupply && !includeExhaust) return;

                    double? parse(TextEditingController c) {
                      final raw = c.text.trim().replaceAll(',', '.');
                      if (raw.isEmpty) return null;
                      return double.tryParse(raw);
                    }

                    final created = <MeasurementPoint>[];

                    if (includeSupply) {
                      final v = parse(supplyProjectedController);
                      if (v == null || v <= 0) return;
                      created.add(
                        MeasurementPoint(
                          id: uuid.v4(),
                          label: '$baseLabel – Tilluft',
                          airType: AirType.supply,
                          projectedLs: v,
                        ),
                      );
                    }

                    if (includeExhaust) {
                      final v = parse(exhaustProjectedController);
                      if (v == null || v <= 0) return;
                      created.add(
                        MeasurementPoint(
                          id: uuid.v4(),
                          label: '$baseLabel – Frånluft',
                          airType: AirType.exhaust,
                          projectedLs: v,
                        ),
                      );
                    }

                    Navigator.pop(context, created);
                  },
                  child: const Text('Spara'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == null || result.isEmpty) return;

    // Add in one write
    await ref
        .read(projectsControllerProvider.notifier)
        .addPoints(widget.projectId, result);
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
          PopupMenuButton<String>(
            onSelected: (value) async {
              final controller = ref.read(projectsControllerProvider.notifier);

              if (value == 'edit') {
                final p =
                    project; // from your build method (ensure it's not null)
                if (p == null) return;

                final newName = await showTextInputDialog(
                  context: context,
                  title: 'Redigera projekt',
                  labelText: 'Projekt namn',
                  initialValue: p.name,
                  confirmText: 'Spara',
                );
                if (newName != null && newName.trim().isNotEmpty) {
                  await controller.updateProjectDetails(
                    projectId: widget.projectId,
                    name: newName.trim(),
                  );
                }
              }

              if (value == 'delete') {
                final p = project;
                final ok = await showConfirmDialog(
                  context: context,
                  title: 'Radera projekt?',
                  message: p == null
                      ? 'Det här projektet kommer att tas bort från den här enheten.'
                      : '“${p.name}” kommer att tas bort från den här enheten.',
                  confirmText: 'Radera',
                );
                if (ok) {
                  await controller.deleteProject(widget.projectId);
                  if (context.mounted) Navigator.pop(context);
                }
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'edit', child: Text('Redigera projekt')),
              PopupMenuItem(value: 'delete', child: Text('Radera')),
            ],
          ),
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
              _MeasureTab(projectId: p.id),
              OverviewTab(
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
        onPressed: project == null ? null : () => _addPointDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Ny mätning'),
      ),
    );
  }
}

class _MeasureTab extends ConsumerWidget {
  const _MeasureTab({required this.projectId});
  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsAsync = ref.watch(projectsControllerProvider);

    return projectsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error: $e')),
      data: (projects) {
        final p = projects.firstWhere((x) => x.id == projectId);
        if (p.points.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Inga mätningar ännu.\nTryck på "Ny mätning" för att börja.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
          itemCount: p.points.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, i) {
            final pt = p.points[i];
            final eval = FlowEval(
              projected: pt.projectedLs,
              measured: pt.measuredLs,
              tolerancePct: pt.tolerancePct,
            );

            return Dismissible(
              key: ValueKey(pt.id),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                color: Colors.red.withValues(alpha: 0.15),
                child: const Icon(Icons.delete_outline),
              ),
              confirmDismiss: (_) async {
                return await showConfirmDialog(
                  context: context,
                  title: 'Radera mätningar?',
                  message: '“${pt.label}” kommer tas bort.',
                  confirmText: 'Radera',
                );
              },
              onDismissed: (_) async {
                await ref
                    .read(projectsControllerProvider.notifier)
                    .deletePoint(projectId, pt.id);
              },
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () async {
                  final updated = await showDialog<MeasurementPoint>(
                    context: context,
                    builder: (_) => EditMeasurementPointDialog(point: pt),
                  );

                  if (updated != null) {
                    await ref
                        .read(projectsControllerProvider.notifier)
                        .updatePoint(projectId, updated);
                  }
                },
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                pt.label,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            RatioBadge(eval: eval),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            MetricChip(
                              label: 'Projekterat',
                              value: '${pt.projectedLs.toStringAsFixed(1)} l/s',
                            ),
                            const SizedBox(width: 8),
                            MetricChip(
                              label: 'Uppmätt',
                              value: pt.measuredLs == null
                                  ? '—'
                                  : '${pt.measuredLs!.toStringAsFixed(1)} l/s',
                            ),
                            const Spacer(),
                            Text(
                              pt.airType == AirType.supply
                                  ? 'Tilluft'
                                  : 'Frånluft',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.outline,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _MeasuredInputRow(
                          initialValue: pt.measuredLs,
                          onChanged: (val) {
                            ref
                                .read(projectsControllerProvider.notifier)
                                .updateMeasured(projectId, pt.id, val);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _MeasuredInputRow extends StatefulWidget {
  const _MeasuredInputRow({
    required this.initialValue,
    required this.onChanged,
  });

  final double? initialValue;
  final ValueChanged<double?> onChanged;

  @override
  State<_MeasuredInputRow> createState() => _MeasuredInputRowState();
}

class _MeasuredInputRowState extends State<_MeasuredInputRow> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.initialValue?.toStringAsFixed(1) ?? '',
    );
  }

  @override
  void didUpdateWidget(covariant _MeasuredInputRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the value was updated externally (rare in v1), reflect it:
    final newText = widget.initialValue?.toStringAsFixed(1) ?? '';
    if (_controller.text != newText) {
      _controller.text = newText;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _commit() {
    final raw = _controller.text.trim().replaceAll(',', '.');
    if (raw.isEmpty) {
      widget.onChanged(null);
      return;
    }
    final v = double.tryParse(raw);
    widget.onChanged(v);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            decoration: const InputDecoration(
              labelText: 'Uppmätt (l/s)',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            ],
            onChanged: (_) {
              // optional: live update, but can be noisy. we commit on blur/submit:
            },
            onSubmitted: (_) => _commit(),
            onEditingComplete: _commit,
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          tooltip: 'Clear',
          onPressed: () {
            _controller.clear();
            widget.onChanged(null);
          },
          icon: const Icon(Icons.backspace_outlined),
        ),
      ],
    );
  }
}
