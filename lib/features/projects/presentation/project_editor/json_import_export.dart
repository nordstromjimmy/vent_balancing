import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../application/projects_controller.dart';
import 'project_editor_page.dart';

class ProjectJsonIo {
  static Future<void> exportProject(
    BuildContext context, {
    required ProjectsController controller,
    required String projectId,
  }) async {
    try {
      final p = await controller.getProjectById(projectId);
      final jsonString = await controller.exportProjectToJsonString(projectId);

      final dir = await getTemporaryDirectory();
      final safeName = (p?.name ?? 'projekt')
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
      ).showSnackBar(SnackBar(content: Text('Export misslyckades: $e')));
    }
  }

  static Future<void> importProject(
    BuildContext context, {
    required ProjectsController controller,
    required String currentProjectId,
  }) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      final content = file.bytes != null
          ? utf8.decode(file.bytes!)
          : await File(file.path!).readAsString();

      if (!context.mounted) return;
      final choice = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Importera JSON'),
          content: const Text(
            'Vill du skriva över det här projektet, eller importera som ett nytt projekt?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Ångra'),
            ),
            FilledButton.tonal(
              onPressed: () => Navigator.pop(context, 'copy'),
              child: const Text('Importera som kopia'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, 'overwrite'),
              child: const Text('Skriv över'),
            ),
          ],
        ),
      );

      if (choice == null) return;

      if (choice == 'overwrite') {
        await controller.importIntoProject(
          projectId: currentProjectId,
          jsonString: content,
        );
      } else if (choice == 'copy') {
        final newId = await controller.importAsNewProject(jsonString: content);
        if (!context.mounted) return;
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
      ).showSnackBar(const SnackBar(content: Text('Import slutförd')));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Import misslyckades: $e')));
    }
  }
}
