class Patient {
  final String id;
  final String name;
  final int age;
  final List<String> conditions;
  final DateTime lastCheckIn;
  final DateTime nextAppointment;
  final double adherenceRate;
  final String? profileImage;

  Patient({
    required this.id,
    required this.name,
    required this.age,
    required this.conditions,
    required this.lastCheckIn,
    required this.nextAppointment,
    required this.adherenceRate,
    this.profileImage,
  });
}