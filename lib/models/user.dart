enum UserRole {
  patient,
  caregiver,
  family,
  admin,
}

class User {
  final String id;
  final String email;
  final String name;
  final UserRole role;
  final String? phoneNumber;
  final String? profileImage;
  final DateTime createdAt;
  final bool isActive;

  User({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.phoneNumber,
    this.profileImage,
    required this.createdAt,
    this.isActive = true,
  });
}