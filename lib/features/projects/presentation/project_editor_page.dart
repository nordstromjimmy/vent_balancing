import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
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

  Future<void> _exportJson(BuildContext context) async {
    final controller = ref.read(projectsControllerProvider.notifier);

    try {
      final p = await controller.getProjectById(widget.projectId);
      final jsonString = await controller.exportProjectToJsonString(
        widget.projectId,
      );

      final dir = await getTemporaryDirectory();
      final safeName = (p?.name ?? 'project')
          .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
          .trim();

      final file = File('${dir.path}/$safeName.json');
      await file.writeAsString(jsonString);

      await Share.shareXFiles([
        XFile(file.path),
      ], text: 'Export: ${p?.name ?? ''}');
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
    }
  }

  Future<void> _importJson(BuildContext context) async {
    final controller = ref.read(projectsControllerProvider.notifier);

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        withData: true, // important for web/desktop
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;

      final content = file.bytes != null
          ? utf8.decode(file.bytes!) // correct UTF-8 decoding
          : await File(file.path!).readAsString(); // already UTF-8 by default

      // Ask user: overwrite current or import as copy
      if (!context.mounted) return;
      final choice = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Import JSON'),
          content: const Text(
            'Do you want to overwrite this project, or import as a new project?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton.tonal(
              onPressed: () => Navigator.pop(context, 'copy'),
              child: const Text('Import as copy'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, 'overwrite'),
              child: const Text('Overwrite'),
            ),
          ],
        ),
      );

      if (choice == null) return;

      if (choice == 'overwrite') {
        await controller.importIntoProject(
          projectId: widget.projectId,
          jsonString: content,
        );
      } else if (choice == 'copy') {
        final newId = await controller.importAsNewProject(jsonString: content);
        if (!context.mounted) return;
        // Navigate to the new project
        await Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => ProjectEditorPage(projectId: newId),
          ),
        );
        return;
      }

      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Import completed')));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Import failed: $e')));
    }
  }

  Future<void> _addPointDialog(BuildContext context) async {
    const uuid = Uuid();

    final labelController = TextEditingController();

    // Base (grund) flows
    final supplyBaseController = TextEditingController();
    final exhaustBaseController = TextEditingController();

    // Boost (forcerat) flows
    final supplyBoostController = TextEditingController();
    final exhaustBoostController = TextEditingController();

    bool includeSupply = true;
    bool includeExhaust = true;
    bool includeBoost = false;

    double? parseDouble(String s) {
      final raw = s.trim().replaceAll(',', '.');
      if (raw.isEmpty) return null;
      return double.tryParse(raw);
    }

    InputDecoration dec(String label, String hint) =>
        InputDecoration(labelText: label, hintText: hint);

    Widget numberField({
      required String title,
      required TextEditingController controller,
      String hint = 't.ex. 25',
    }) {
      return TextField(
        controller: controller,
        decoration: dec(title, hint),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
        ],
      );
    }

    final result = await showDialog<List<MeasurementPoint>>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            return AlertDialog(
              title: const Text('Lägg till mätpunkt'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: labelController,
                      decoration: dec('Rum / Etikett', 't.ex. Rum 102'),
                      autofocus: false,
                    ),
                    const SizedBox(height: 12),

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

                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Har forcerat flöde'),
                      value: includeBoost,
                      onChanged: (v) => setLocalState(() => includeBoost = v),
                    ),

                    const SizedBox(height: 8),

                    if (includeSupply) ...[
                      numberField(
                        title: 'Tilluft – Grund (l/s)',
                        controller: supplyBaseController,
                      ),
                      if (includeBoost) ...[
                        const SizedBox(height: 12),
                        numberField(
                          title: 'Tilluft – Forcerat (l/s)',
                          controller: supplyBoostController,
                        ),
                      ],
                      const SizedBox(height: 12),
                    ],

                    if (includeExhaust) ...[
                      numberField(
                        title: 'Frånluft – Grund (l/s)',
                        controller: exhaustBaseController,
                      ),
                      if (includeBoost) ...[
                        const SizedBox(height: 12),
                        numberField(
                          title: 'Frånluft – Forcerat (l/s)',
                          controller: exhaustBoostController,
                        ),
                      ],
                    ],

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

                    final created = <MeasurementPoint>[];

                    if (includeSupply) {
                      final base = parseDouble(supplyBaseController.text);
                      if (base == null || base <= 0) return;

                      final boost = includeBoost
                          ? parseDouble(supplyBoostController.text)
                          : null;

                      if (includeBoost && (boost == null || boost <= 0)) return;

                      created.add(
                        MeasurementPoint(
                          id: uuid.v4(),
                          label: baseLabel,
                          airType: AirType.supply,
                          projectedBaseLs: base,
                          projectedBoostLs: boost,
                        ),
                      );
                    }

                    if (includeExhaust) {
                      final base = parseDouble(exhaustBaseController.text);
                      if (base == null || base <= 0) return;

                      final boost = includeBoost
                          ? parseDouble(exhaustBoostController.text)
                          : null;

                      if (includeBoost && (boost == null || boost <= 0)) return;

                      created.add(
                        MeasurementPoint(
                          id: uuid.v4(),
                          label: baseLabel,
                          airType: AirType.exhaust, // ✅ important fix
                          projectedBaseLs: base,
                          projectedBoostLs: boost,
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
              if (value == 'export_json') {
                await _exportJson(context);
              }
              if (value == 'import_json') {
                await _importJson(context);
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'edit', child: Text('Redigera projekt')),

              PopupMenuItem(
                value: 'export_json',
                child: Text('Exportera JSON'),
              ),
              PopupMenuItem(
                value: 'import_json',
                child: Text('Importera JSON'),
              ),
              PopupMenuDivider(),
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
            final meta = <String>[];
            if (pt.pressurePa != null) {
              meta.add('Pa ${pt.pressurePa!.toStringAsFixed(0)}');
            }
            if (pt.kFactor != null) {
              meta.add('K ${pt.kFactor!.toStringAsFixed(2)}');
            }
            if (pt.setting != null && pt.setting!.isNotEmpty) {
              meta.add('Inst ${pt.setting!}');
            }

            final metaText = meta.isEmpty ? null : meta.join(' • ');
            final eval = FlowEval(
              projected: pt.projectedBaseLs,
              measured: pt.measuredBaseLs,
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

                            // ✅ Air type moved next to label
                            Text(
                              pt.airType == AirType.supply
                                  ? 'Tilluft'
                                  : 'Frånluft',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.outline,
                                fontWeight: FontWeight.w600,
                              ),
                            ),

                            const SizedBox(width: 10),
                            RatioBadge(eval: eval),
                          ],
                        ),

                        const SizedBox(height: 10),

                        // ✅ Wrap can only contain non-flex children (no Spacer/Expanded)
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            MetricChip(
                              label: 'Grund proj',
                              value:
                                  '${pt.projectedBaseLs.toStringAsFixed(1)} l/s',
                            ),
                            MetricChip(
                              label: 'Grund mätt',
                              value: pt.measuredBaseLs == null
                                  ? '—'
                                  : '${pt.measuredBaseLs!.toStringAsFixed(1)} l/s',
                            ),
                            if (pt.projectedBoostLs != null ||
                                pt.measuredBoostLs != null) ...[
                              MetricChip(
                                label: 'Forc proj',
                                value: pt.projectedBoostLs == null
                                    ? '—'
                                    : '${pt.projectedBoostLs!.toStringAsFixed(1)} l/s',
                              ),
                              MetricChip(
                                label: 'Forc mätt',
                                value: pt.measuredBoostLs == null
                                    ? '—'
                                    : '${pt.measuredBoostLs!.toStringAsFixed(1)} l/s',
                              ),
                            ],
                          ],
                        ),

                        const SizedBox(height: 12),

                        _MeasuredInputRow(
                          initialValue: pt.measuredBaseLs,
                          onChanged: (val) {
                            ref
                                .read(projectsControllerProvider.notifier)
                                .updateMeasured(projectId, pt.id, val);
                          },
                        ),

                        if (metaText != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            metaText,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                          ),
                        ],
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
