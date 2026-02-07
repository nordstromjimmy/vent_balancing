import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/dialogs.dart';
import '../../application/projects_controller.dart';
import '../../domain/project.dart';
import 'excel_import_export.dart';
import 'json_import_export.dart';

class ProjectEditorActions extends ConsumerWidget {
  const ProjectEditorActions({
    super.key,
    required this.projectId,
    required this.project,
  });

  final String projectId;
  final Project? project;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<String>(
      onSelected: (value) async {
        final controller = ref.read(projectsControllerProvider.notifier);

        if (value == 'edit') {
          final p = project;
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
              projectId: projectId,
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
            await controller.deleteProject(projectId);
            if (context.mounted) Navigator.pop(context);
          }
        }

        if (value == 'export_json') {
          await ProjectJsonIo.exportProject(
            context,
            controller: controller,
            projectId: projectId,
          );
        }

        if (value == 'export_excel') {
          final p = project;
          if (p == null) return;

          await ProjectExcelIo.exportProject(
            context,
            controller: controller,
            projectId: projectId,
            projectName: p.name,
          );
        }

        if (value == 'import_json') {
          await ProjectJsonIo.importProject(
            context,
            controller: controller,
            currentProjectId: projectId,
          );
        }
      },
      itemBuilder: (context) => const [
        PopupMenuItem(value: 'edit', child: Text('Redigera projekt')),
        PopupMenuItem(value: 'export_json', child: Text('Exportera JSON')),
        PopupMenuItem(value: 'export_excel', child: Text('Exportera Excel')),
        PopupMenuItem(value: 'import_json', child: Text('Importera JSON')),
        PopupMenuDivider(),
        PopupMenuItem(value: 'delete', child: Text('Radera')),
      ],
    );
  }
}
