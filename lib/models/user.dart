class User {
  const User({
    this.id,
    this.phone,
    required this.name,
    required this.email,
    required this.password,
    required this.role,
  });

  final int? id;
  final String? phone;
  final String name;
  final String email;
  final String password;
  final String role;

  factory User.fromMap(Map<String, Object?> map) {
    return User(
      id: map['id'] as int?,
      phone: map['phone'] as String?,
      name: map['name'] as String,
      email: map['email'] as String,
      password: map['password'] as String,
      role: map['role'] as String,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'phone': phone,
      'name': name,
      'email': email,
      'password': password,
      'role': role,
    };
  }
}
