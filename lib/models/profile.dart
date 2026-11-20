class Profile {
  const Profile({
    required this.id,
    required this.role,
    this.email,
    this.firstname,
    this.lastname,
  });

  final String id;
  final String role;
  final String? email;
  final String? firstname;
  final String? lastname;

  bool get isAdmin => role == 'admin';

  String get displayName {
    final name = [
      firstname,
      lastname,
    ].whereType<String>().where((part) => part.trim().isNotEmpty).join(' ');
    return name.isNotEmpty ? name : (email ?? 'Customer');
  }

  factory Profile.fromMap(Map<String, dynamic> map) {
    final role = map['roles'];
    return Profile(
      id: map['id'] as String,
      email: map['email'] as String?,
      firstname: map['firstname'] as String?,
      lastname: map['lastname'] as String?,
      role: role is Map<String, dynamic>
          ? (role['role'] as String?) ?? 'customer'
          : 'customer',
    );
  }
}
