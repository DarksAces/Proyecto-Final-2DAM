class UserModel {
  final String id;
  final String email;
  final String name;
  final int followers;
  final int following;
  final int role; // 0: User, 1: Admin, etc.

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    this.followers = 0,
    this.following = 0,
    this.role = 0,
  });

  factory UserModel.fromMap(Map<String, dynamic> data, String documentId) {
    return UserModel(
      id: documentId,
      email: data['email'] ?? '',
      name: data['name'] ?? 'Usuario',
      followers: data['followers'] ?? 0,
      following: data['following'] ?? 0,
      role: data['role'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'followers': followers,
      'following': following,
      'role': role,
    };
  }
}
