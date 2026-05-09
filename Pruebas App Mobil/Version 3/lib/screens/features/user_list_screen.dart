import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/user_service.dart';
import 'profile_screen.dart';

class UserListScreen extends StatefulWidget {
  final String userId;
  final String type; // 'followers' or 'following'
  final String title;

  const UserListScreen({
    super.key,
    required this.userId,
    required this.type,
    required this.title,
  });

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  final UserService _userService = UserService();
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    List<Map<String, dynamic>> users = [];
    
    if (widget.type == 'followers') {
      users = await _userService.getFollowersDetails(widget.userId);
    } else {
      users = await _userService.getFollowingDetails(widget.userId);
    }

    if (mounted) {
      setState(() {
        _users = users;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.title,
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 18),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF)))
          : _users.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _users.length,
                  itemBuilder: (context, index) {
                    final user = _users[index];
                    return _buildUserTile(user, index);
                  },
                ),
    );
  }

  Widget _buildUserTile(Map<String, dynamic> user, int index) {
    final String name = user['displayName'] ?? user['username'] ?? 'Usuario';
    final String username = user['username'] ?? name.toLowerCase().replaceAll(' ', '_');
    final String? avatarUrl = user['avatarUrl'];
    final bool isMyList = widget.userId == _userService.currentUserId;

    return ListTile(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen(userId: user['id']))),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: CircleAvatar(
        radius: 28,
        backgroundColor: const Color(0xFFF0F0FF),
        backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
        child: avatarUrl == null ? Text(name[0].toUpperCase(), style: const TextStyle(color: Color(0xFF6C63FF), fontWeight: FontWeight.bold)) : null,
      ),
      title: Text(username, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
      subtitle: Text(name, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
      trailing: !isMyList 
        ? null 
        : SizedBox(
            height: 32,
            child: OutlinedButton(
              onPressed: () => _confirmAction(user, index),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.red.shade100),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              child: const Text("Eliminar", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          ),
    );
  }

  void _confirmAction(Map<String, dynamic> user, int index) {
    final String name = user['displayName'] ?? user['username'] ?? 'este usuario';
    final bool isFollowers = widget.type == 'followers';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(isFollowers ? "Eliminar seguidor" : "Dejar de seguir", 
          style: const TextStyle(fontWeight: FontWeight.w900)),
        content: Text("¿Estás seguro de que quieres ${isFollowers ? "eliminar a $name de tus seguidores" : "dejar de seguir a $name"}?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancelar", style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _handleDelete(user['id'], index);
            },
            child: const Text("Eliminar", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _handleDelete(String targetId, int index) async {
    bool success = false;
    if (widget.type == 'followers') {
      success = await _userService.removeFollower(targetId);
    } else {
      success = await _userService.unfollowUser(targetId);
    }

    if (success && mounted) {
      setState(() {
        _users.removeAt(index);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Acción realizada con éxito")),
      );
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_add_rounded, size: 64, color: Colors.grey.shade200),
          const SizedBox(height: 16),
          Text(
            widget.type == 'followers' ? "No tienes seguidores todavía" : "No sigues a nadie todavía",
            style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
