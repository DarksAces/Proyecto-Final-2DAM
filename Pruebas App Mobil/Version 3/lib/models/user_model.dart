class UserModel {
  final String id;
  final String email;
  final String name;
  final String? avatarUrl;
  final String? bio;
  final int points;
  final String level;
  final int followers;
  final int following;
  final int role; // 0: User, 1: Admin, etc.

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    this.avatarUrl,
    this.bio,
    this.points = 0,
    this.level = 'Aprendiz de AR',
    this.followers = 0,
    this.following = 0,
    this.role = 0,
  });

  factory UserModel.fromMap(Map<String, dynamic> data, String documentId) {
    return UserModel(
      id: documentId,
      email: data['email'] ?? '',
      name: data['displayName'] ?? data['fullName'] ?? data['name'] ?? data['userName'] ?? data['username'] ?? 'Explorador',
      avatarUrl: data['avatarUrl'] ?? data['photoUrl'],
      bio: data['bio'],
      points: ((data['points'] ?? 0) as num).toInt(),
      level: data['level'] ?? 'Aprendiz de AR',
      followers: data['followers'] ?? 0,
      following: data['following'] ?? 0,
      role: data['role'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': name,
      'avatarUrl': avatarUrl,
      'bio': bio,
      'points': points,
      'level': level,
      'followers': followers,
      'following': following,
      'role': role,
    };
  }
}
