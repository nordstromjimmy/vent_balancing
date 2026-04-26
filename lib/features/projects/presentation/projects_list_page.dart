import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/dialogs.dart';
import '../application/projects_controller.dart';
import 'calculator_page.dart';
import 'project_editor/project_editor_page.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Shell — owns the bottom nav and keeps each tab alive when switching.
// ─────────────────────────────────────────────────────────────────────────────

class ProjectsListPage extends StatefulWidget {
  const ProjectsListPage({super.key});

  @override
  State<ProjectsListPage> createState() => _ProjectsListPageState();
}

class _ProjectsListPageState extends State<ProjectsListPage> {
  int _currentIndex = 0;

  // Keep both pages alive so state is preserved when switching tabs.
  final _pages = const [_ProjectsTab(), CalculatorPage()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.folder_outlined),
            selectedIcon: Icon(Icons.folder),
            label: 'Projekt',
          ),
          NavigationDestination(
            icon: Icon(Icons.calculate_outlined),
            selectedIcon: Icon(Icons.calculate),
            label: 'Kalkylator',
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Projects tab — extracted from the old ProjectsListPage
// ─────────────────────────────────────────────────────────────────────────────

class _ProjectsTab extends ConsumerWidget {
  const _ProjectsTab();

  Future<void> _createProject(BuildContext context, WidgetRef ref) async {
    final name = await showTextInputDialog(
      context: context,
      title: 'Nytt projekt',
      labelText: 'Projekt namn',
      hintText: 'e.x Byggnad A – Våning 2',
      confirmText: 'Skapa',
    );

    final trimmed = name?.trim();
    if (trimmed == null || trimmed.isEmpty) return;

    final projectId = await ref
        .read(projectsControllerProvider.notifier)
        .createProject(trimmed);

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
      appBar: AppBar(title: const Text('Projekt')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createProject(context, ref),
        icon: const Icon(Icons.add),
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
                'Något gick fel:',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text('$e'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () =>
                    ref.read(projectsControllerProvider.notifier).refresh(),
                child: const Text('Försök igen'),
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
                        '"${p.name}" kommer att tas bort från den här enheten.',
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
