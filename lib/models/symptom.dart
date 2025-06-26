class Symptom {
  final String id;
  final String name;
  final String category;
  final int? criticalLevel;
  final bool isActive;
  final DateTime? startDate;
  final List<SymptomLog> logs;

  Symptom({
    required this.id,
    required this.name,
    required this.category,
    this.criticalLevel,
    this.isActive = true,
    this.startDate,
    this.logs = const [],
  });
}

class SymptomLog {
  final String id;
  final String symptomId;
  final int? severity;
  final String? note;
  final DateTime timestamp;

  SymptomLog({
    required this.id,
    required this.symptomId,
    this.severity,
    this.note,
    required this.timestamp,
  });
}