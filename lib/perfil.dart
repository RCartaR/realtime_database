class Profile {
  Profile({
    required this.id,
    required this.username,
    required this.createdAt,
    required this.avatar,
  });

  final String id;
  final String username;
  final DateTime createdAt;
  final String avatar;

  Profile.fromMap(Map<String, dynamic> map)
      : id = map['id'],
        username = map['username'],
        createdAt = DateTime.parse(map['created_at']),
        avatar = map['avatar'];
}