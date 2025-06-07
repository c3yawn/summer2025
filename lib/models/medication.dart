class Medication {
  final String id;
  final String name;
  final String dosage;
  final String frequency;
  final String? ndcCode;
  final DateTime startDate;
  final DateTime? endDate;
  final int quantity;
  final List<MedicationReminder> reminders;

  Medication({
    required this.id,
    required this.name,
    required this.dosage,
    required this.frequency,
    this.ndcCode,
    required this.startDate,
    this.endDate,
    required this.quantity,
    this.reminders = const [],
  });
}

class MedicationReminder {
  final String id;
  final String medicationId;
  final String time;
  final bool isActive;

  MedicationReminder({
    required this.id,
    required this.medicationId,
    required this.time,
    this.isActive = true,
  });
}