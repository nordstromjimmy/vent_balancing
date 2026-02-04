import 'package:hive/hive.dart';
import '../../project_repository.dart';
import '../domain/project.dart';

class HiveProjectRepository implements ProjectRepository {
  static const _boxName = 'projects_box';

  Future<Box> _openBox() async {
    if (Hive.isBoxOpen(_boxName)) return Hive.box(_boxName);
    return Hive.openBox(_boxName);
  }

  // Converts Hive's Map<dynamic, dynamic> / List<dynamic> structures into
  // JSON-friendly Map<String, dynamic> / List with nested conversion.
  Map<String, dynamic> _deepStringKeyedMap(Object raw) {
    dynamic convert(dynamic v) {
      if (v is Map) {
        return v.map((key, value) => MapEntry(key.toString(), convert(value)));
      }
      if (v is List) {
        return v.map(convert).toList();
      }
      return v;
    }

    final converted = convert(raw);
    return Map<String, dynamic>.from(converted as Map);
  }

  @override
  Future<List<Project>> listProjects() async {
    final box = await _openBox();

    return box.values
        .whereType<Map>()
        .map((raw) => Project.fromJson(_deepStringKeyedMap(raw)))
        .toList()
      ..sort(
        (a, b) =>
            (b.updatedAt ?? DateTime(0)).compareTo(a.updatedAt ?? DateTime(0)),
      );
  }

  @override
  Future<Project?> getProject(String id) async {
    final box = await _openBox();
    final raw = box.get(id);
    if (raw == null) return null;

    return Project.fromJson(_deepStringKeyedMap(raw));
  }

  @override
  Future<void> upsertProject(Project project) async {
    final box = await _openBox();

    // Write JSON-safe structure
    final safe = <String, dynamic>{
      ...project.toJson(),
      'points': project.points.map((p) => p.toJson()).toList(),
    };

    await box.put(project.id, safe);
  }

  @override
  Future<void> deleteProject(String id) async {
    final box = await _openBox();
    await box.delete(id);
  }
}
