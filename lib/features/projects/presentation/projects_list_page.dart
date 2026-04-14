import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/dialogs.dart';
import '../application/projects_controller.dart';
import 'project_editor/project_editor_page.dart';

class ProjectsListPage extends ConsumerWidget {
  const ProjectsListPage({super.key});

  Future<void> _createProject(BuildContext context, WidgetRef ref) async {
    final controller = ref.read(projectsControllerProvider.notifier);

    final name = await showDialog<String>(
      context: context,
      builder: (context) {
        final textController = TextEditingController();
        return AlertDialog(
          title: const Text('Nytt projekt'),
          content: TextField(
            controller: textController,
            autofocus: false,
            decoration: const InputDecoration(
              labelText: 'Projekt namn',
              hintText: 'e.x Byggnad A – Våning 2',
            ),
            onSubmitted: (_) =>
                Navigator.pop(context, textController.text.trim()),
          ),
          actions: [
            Row(
              children: [
                TextButton(
                  style: ButtonStyle(
                    foregroundColor: WidgetStatePropertyAll<Color>(
                      Colors.black54,
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Ångra'),
                ),
                Spacer(),
                FilledButton(
                  style: ButtonStyle(
                    backgroundColor: WidgetStatePropertyAll<Color>(
                      Colors.black54,
                    ),
                  ),
                  onPressed: () =>
                      Navigator.pop(context, textController.text.trim()),
                  child: const Text('Skapa'),
                ),
              ],
            ),
          ],
        );
      },
    );

    final trimmed = name?.trim();
    if (trimmed == null || trimmed.isEmpty) return;

    final projectId = await controller.createProject(trimmed);

    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProjectEditorPage(projectId: projectId),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsAsync = ref.watch(projectsControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Projekt'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () =>
                ref.read(projectsControllerProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createProject(context, ref),
        icon: const Icon(Icons.add),
        foregroundColor: Colors.white,
        backgroundColor: Colors.black54,
        label: const Text('Nytt projekt'),
      ),
      body: projectsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Something went wrong:',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text('$e'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () =>
                    ref.read(projectsControllerProvider.notifier).refresh(),
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
        data: (projects) {
          if (projects.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Inga projekt ännu.\nTryck på "Nytt projekt" för att komma igång.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
            itemCount: projects.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final p = projects[index];
              final pointsCount = p.points.length;

              return Dismissible(
                key: ValueKey(p.id),
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
                    title: 'Radera projekt?',
                    message:
                        '“${p.name}” kommer att tas bort från den här enheten.',
                    confirmText: 'Radera',
                  );
                },
                onDismissed: (_) async {
                  await ref
                      .read(projectsControllerProvider.notifier)
                      .deleteProject(p.id);
                },
                child: Card(
                  child: ListTile(
                    title: Text(
                      p.name,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      '$pointsCount mätning${pointsCount == 1 ? '' : 'ar'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) async {
                        final controller = ref.read(
                          projectsControllerProvider.notifier,
                        );

                        if (value == 'rename') {
                          final name = await showTextInputDialog(
                            context: context,
                            title: 'Ändra namn',
                            labelText: 'Projekt namn',
                            initialValue: p.name,
                            confirmText: 'Spara',
                          );
                          if (name != null && name.trim().isNotEmpty) {
                            await controller.renameProject(p.id, name);
                          }
                        }

                        if (value == 'duplicate') {
                          final newProjectId = await controller
                              .duplicateProject(p.id);

                          if (newProjectId != null && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Projekt kopierat')),
                            );
                          }
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: 'rename',
                          child: Text('Ändra namn'),
                        ),
                        PopupMenuItem(
                          value: 'duplicate',
                          child: Text('Kopiera projekt'),
                        ),
                      ],
                    ),
                    onTap: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ProjectEditorPage(projectId: p.id),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
