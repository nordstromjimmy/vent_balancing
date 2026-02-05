import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../project_repository.dart';
import '../data/hive_project_repository.dart';
import '../domain/project.dart';
import '../domain/measurement_point.dart';
import 'dart:convert';

final projectRepositoryProvider = Provider<ProjectRepository>((ref) {
  return HiveProjectRepository();
});

final projectsControllerProvider =
    StateNotifierProvider<ProjectsController, AsyncValue<List<Project>>>(
      (ref) => ProjectsController(ref.watch(projectRepositoryProvider)),
    );

class ProjectsController extends StateNotifier<AsyncValue<List<Project>>> {
  ProjectsController(this._repo) : super(const AsyncValue.loading()) {
    refresh();
  }

  final ProjectRepository _repo;
  final _uuid = const Uuid();

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repo.listProjects());
  }

  Future<String> createProject(String name) async {
    final now = DateTime.now();
    final project = Project(
      id: _uuid.v4(),
      name: name,
      createdAt: now,
      updatedAt: now,
    );
    await _repo.upsertProject(project);
    await refresh();
    return project.id;
  }

  Future<void> addPoint(String projectId, MeasurementPoint point) async {
    final p = await _repo.getProject(projectId);
    if (p == null) return;
    final updated = p.copyWith(
      points: [...p.points, point],
      updatedAt: DateTime.now(),
    );
    await _repo.upsertProject(updated);
    await refresh();
  }

  Future<void> updateMeasuredBase(
    String projectId,
    String pointId,
    double? measured,
  ) async {
    final p = await _repo.getProject(projectId);
    if (p == null) return;

    final updatedPoints = p.points.map((pt) {
      if (pt.id != pointId) return pt;
      return pt.copyWith(measuredBaseLs: measured);
    }).toList();

    await _repo.upsertProject(
      p.copyWith(points: updatedPoints, updatedAt: DateTime.now()),
    );
    await refresh();
  }

  Future<void> updateMeasuredBoost(
    String projectId,
    String pointId,
    double? measured,
  ) async {
    final p = await _repo.getProject(projectId);
    if (p == null) return;

    final updatedPoints = p.points.map((pt) {
      if (pt.id != pointId) return pt;
      return pt.copyWith(measuredBoostLs: measured);
    }).toList();

    await _repo.upsertProject(
      p.copyWith(points: updatedPoints, updatedAt: DateTime.now()),
    );
    await refresh();
  }

  Future<void> renameProject(String projectId, String newName) async {
    final p = await _repo.getProject(projectId);
    if (p == null) return;

    final updated = p.copyWith(name: newName.trim(), updatedAt: DateTime.now());

    await _repo.upsertProject(updated);
    await refresh();
  }

  Future<void> updateProjectDetails({
    required String projectId,
    String? name,
    String? address,
    double? defaultTolerancePct,
  }) async {
    final p = await _repo.getProject(projectId);
    if (p == null) return;

    final updated = p.copyWith(
      name: name?.trim() ?? p.name,
      address: address ?? p.address,
      defaultTolerancePct: defaultTolerancePct ?? p.defaultTolerancePct,
      updatedAt: DateTime.now(),
    );

    await _repo.upsertProject(updated);
    await refresh();
  }

  Future<void> deleteProject(String projectId) async {
    await _repo.deleteProject(projectId);
    await refresh();
  }

  Future<void> updatePoint(
    String projectId,
    MeasurementPoint updatedPoint,
  ) async {
    final p = await _repo.getProject(projectId);
    if (p == null) return;

    final updatedPoints = p.points.map((pt) {
      if (pt.id != updatedPoint.id) return pt;
      return updatedPoint;
    }).toList();

    await _repo.upsertProject(
      p.copyWith(points: updatedPoints, updatedAt: DateTime.now()),
    );
    await refresh();
  }

  Future<void> deletePoint(String projectId, String pointId) async {
    final p = await _repo.getProject(projectId);
    if (p == null) return;

    final updatedPoints = p.points.where((pt) => pt.id != pointId).toList();

    await _repo.upsertProject(
      p.copyWith(points: updatedPoints, updatedAt: DateTime.now()),
    );
    await refresh();
  }

  Future<void> addPoints(
    String projectId,
    List<MeasurementPoint> points,
  ) async {
    final p = await _repo.getProject(projectId);
    if (p == null) return;

    final updated = p.copyWith(
      points: [...p.points, ...points],
      updatedAt: DateTime.now(),
    );

    await _repo.upsertProject(updated);
    await refresh();
  }

  Future<String> exportProjectToJsonString(String projectId) async {
    final p = await _repo.getProject(projectId);
    if (p == null) throw StateError('Project not found');
    // pretty printed JSON is nicer for humans
    return const JsonEncoder.withIndent('  ').convert(p.toJson());
  }

  /// Import JSON into an existing project (overwrite points etc)
  Future<void> importIntoProject({
    required String projectId,
    required String jsonString,
  }) async {
    final decoded = jsonDecode(jsonString);
    if (decoded is! Map) throw FormatException('Invalid JSON');

    final incoming = Project.fromJson(Map<String, dynamic>.from(decoded));

    // overwrite current project but preserve its ID (and name if you want)
    final updated = incoming.copyWith(id: projectId, updatedAt: DateTime.now());

    await _repo.upsertProject(updated);
    await refresh();
  }

  /// Import JSON as a *new* project (copy)
  Future<String> importAsNewProject({
    required String jsonString,
    String? nameOverride,
  }) async {
    final decoded = jsonDecode(jsonString);
    if (decoded is! Map) throw FormatException('Invalid JSON');

    final incoming = Project.fromJson(Map<String, dynamic>.from(decoded));

    final now = DateTime.now();
    final newId = const Uuid().v4();

    final created = incoming.copyWith(
      id: newId,
      name: (nameOverride?.trim().isNotEmpty ?? false)
          ? nameOverride!.trim()
          : '${incoming.name} (import)',
      createdAt: now,
      updatedAt: now,
    );

    await _repo.upsertProject(created);
    await refresh();
    return newId;
  }

  Future<Project?> getProjectById(String projectId) =>
      _repo.getProject(projectId);
}
