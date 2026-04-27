class UserModel {
  final String id;
  final String email;
  final String name;
  final String? schoolId;
  final int followers;
  final int following;
  final int role; // 0: User, 1: Admin, etc.

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    this.schoolId,
    this.followers = 0,
    this.following = 0,
    this.role = 0,
  });

  factory UserModel.fromMap(Map<String, dynamic> data, String documentId) {
    return UserModel(
      id: documentId,
      email: data['email'] ?? '',
      name: data['name'] ?? 'Usuario',
      schoolId: data['schoolId'],
      followers: data['followers'] ?? 0,
      following: data['following'] ?? 0,
      role: data['role'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'schoolId': schoolId,
      'followers': followers,
      'following': following,
      'role': role,
    };
  }
}
