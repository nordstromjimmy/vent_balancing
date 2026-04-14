import 'package:excel/excel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../project_repository.dart';
import '../data/hive_project_repository.dart';
import '../domain/project.dart';
import '../domain/measurement_point.dart';
import 'dart:convert';

enum _ExportMode { base, boost }

class _RoomRow {
  MeasurementPoint? supply;
  MeasurementPoint? exhaust;
}

class _ExportRow {
  _ExportRow(this.room, this.mode, this.row);

  final String room;
  final _ExportMode mode;
  final _RoomRow row;
}

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

  Future<String?> duplicateProject(String projectId) async {
    final p = await _repo.getProject(projectId);
    if (p == null) return null;

    final now = DateTime.now();
    final newProjectId = _uuid.v4();

    final copiedPoints = p.points
        .map(
          (pt) => pt.copyWith(
            id: _uuid.v4(),
            measuredBaseLs: null,
            measuredBoostLs: null,
          ),
        )
        .toList();

    final copiedProject = p.copyWith(
      id: newProjectId,
      name: '${p.name} (kopia)',
      points: copiedPoints,
      createdAt: now,
      updatedAt: now,
    );

    await _repo.upsertProject(copiedProject);
    await refresh();

    return newProjectId;
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

  Future<List<int>> exportProjectToExcelBytes(String projectId) async {
    final p = await _repo.getProject(projectId);
    if (p == null) throw StateError('Project not found');

    // Group by room label (so TL/FL go on same row)
    final byRoom = <String, _RoomRow>{};
    for (final pt in p.points) {
      final key = pt.label.trim();
      final r = byRoom.putIfAbsent(key, () => _RoomRow());
      if (pt.airType == AirType.supply) {
        r.supply = pt;
      } else {
        r.exhaust = pt;
      }
    }

    bool hasAnyBase(_RoomRow r) {
      final s = r.supply;
      final e = r.exhaust;

      final sHas =
          (s?.projectedBaseLs != null && s!.projectedBaseLs! > 0) ||
          (s?.measuredBaseLs != null);
      final eHas =
          (e?.projectedBaseLs != null && e!.projectedBaseLs! > 0) ||
          (e?.measuredBaseLs != null);

      return sHas || eHas;
    }

    bool hasAnyBoost(_RoomRow r) {
      final s = r.supply;
      final e = r.exhaust;

      final sHas =
          (s?.projectedBoostLs != null && s!.projectedBoostLs! > 0) ||
          (s?.measuredBoostLs != null);
      final eHas =
          (e?.projectedBoostLs != null && e!.projectedBoostLs! > 0) ||
          (e?.measuredBoostLs != null);

      return sHas || eHas;
    }

    String fmtNum(double? v) => v == null ? '' : v.toStringAsFixed(1);

    // Build export rows: base row first, then boost row (if exists)
    final exportRows = <_ExportRow>[];

    final rooms = byRoom.keys.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    for (final room in rooms) {
      final rr = byRoom[room]!;
      if (hasAnyBase(rr)) {
        exportRows.add(_ExportRow(room, _ExportMode.base, rr));
      }
      if (hasAnyBoost(rr)) {
        exportRows.add(_ExportRow(room, _ExportMode.boost, rr));
      }
    }

    // Create workbook
    final excel = Excel.createExcel();
    final sheet = excel['Översikt'];
    excel.setDefaultSheet('Översikt');

    // Header row
    sheet.appendRow([
      TextCellValue('Rum'),
      TextCellValue('Projekterat flöde Tilluft'),
      TextCellValue('Uppmätt flöde Tilluft'),
      TextCellValue('Inställning'),
      TextCellValue('Tryck'),
      TextCellValue('K-faktor'),
      TextCellValue('Projekterat flöde Frånluft'),
      TextCellValue('Uppmätt flöde Frånluft'),
      TextCellValue('Inställning'),
      TextCellValue('Tryck'),
      TextCellValue('K-faktor'),
      TextCellValue('Övrigt'),
    ]);

    for (final er in exportRows) {
      final s = er.row.supply;
      final e = er.row.exhaust;

      // Pick values depending on mode
      final sProj = er.mode == _ExportMode.base
          ? s?.projectedBaseLs
          : s?.projectedBoostLs;
      final sMeas = er.mode == _ExportMode.base
          ? s?.measuredBaseLs
          : s?.measuredBoostLs;

      final eProj = er.mode == _ExportMode.base
          ? e?.projectedBaseLs
          : e?.projectedBoostLs;
      final eMeas = er.mode == _ExportMode.base
          ? e?.measuredBaseLs
          : e?.measuredBoostLs;

      // “Övrigt” must always be empty
      sheet.appendRow([
        TextCellValue(er.room),

        // TL
        TextCellValue(fmtNum(sProj)),
        TextCellValue(fmtNum(sMeas)),
        TextCellValue(s?.setting ?? ''),
        TextCellValue(fmtNum(s?.pressurePa)),
        TextCellValue(fmtNum(s?.kFactor)),

        // FL
        TextCellValue(fmtNum(eProj)),
        TextCellValue(fmtNum(eMeas)),
        TextCellValue(e?.setting ?? ''),
        TextCellValue(fmtNum(e?.pressurePa)),
        TextCellValue(fmtNum(e?.kFactor)),

        // Övrigt empty
        TextCellValue(''),
      ]);
    }

    for (var col = 0; col < 12; col++) {
      sheet.setColumnAutoFit(col);
    }

    final bytes = excel.encode();
    if (bytes == null) throw Exception('Excel encode failed');
    return bytes;
  }

  Future<Project?> getProjectById(String projectId) =>
      _repo.getProject(projectId);
}
