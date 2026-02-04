import 'projects/domain/project.dart';

abstract class ProjectRepository {
  Future<List<Project>> listProjects();
  Future<Project?> getProject(String id);

  Future<void> upsertProject(Project project);
  Future<void> deleteProject(String id);
}
