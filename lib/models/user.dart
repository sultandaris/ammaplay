class User {
  final int? id;
  final String email;
  final String username;

  const User({
    this.id,
    required this.email,
    required this.username,
  });

  User copyWith({
    int? id,
    String? email,
    String? username,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      username: username ?? this.username,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'username': username,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id']?.toInt(),
      email: map['email'] ?? '',
      username: map['username'] ?? '',
    );
  }

  @override
  String toString() {
    return 'User(id: $id, email: $email, username: $username)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User &&
        other.id == id &&
        other.email == email &&
        other.username == username;
  }

  @override
  int get hashCode {
    return id.hashCode ^ email.hashCode ^ username.hashCode;
  }
}
