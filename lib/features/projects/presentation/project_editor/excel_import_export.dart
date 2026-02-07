import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../application/projects_controller.dart';

class ProjectExcelIo {
  static Future<void> exportProject(
    BuildContext context, {
    required ProjectsController controller,
    required String projectId,
    required String projectName,
  }) async {
    try {
      final bytes = await controller.exportProjectToExcelBytes(projectId);

      final dir = await getTemporaryDirectory();
      final safeName = projectName
          .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
          .trim();

      final file = File('${dir.path}/$safeName.xlsx');
      await file.writeAsBytes(bytes, flush: true);

      await Share.shareXFiles([XFile(file.path)], text: 'Export: $projectName');
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Excel export failed: $e')));
    }
  }
}
