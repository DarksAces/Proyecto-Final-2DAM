import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/user_service.dart';

class AddFriendsScreen extends StatefulWidget {
  const AddFriendsScreen({super.key});

  @override
  State<AddFriendsScreen> createState() => _AddFriendsScreenState();
}

class _AddFriendsScreenState extends State<AddFriendsScreen> {
  final UserService _userService = UserService();
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final allUsers = await _userService.getAllUsersWithFollowStatus();

    if (mounted) {
      setState(() {
        _users = allUsers;
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
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Añadir Amigos",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.qr_code_scanner, color: AppTheme.arteRed),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    icon: Icon(Icons.search, color: Colors.grey),
                    hintText: "Buscar amigos o exploradores",
                    hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            _buildSectionHeader("SUGERENCIAS PARA TI"),
            
            if (_isLoading)
              const Center(child: Padding(
                padding: EdgeInsets.all(40.0),
                child: CircularProgressIndicator(color: AppTheme.arteRed),
              ))
            else if (_users.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Column(
                    children: [
                      Icon(Icons.person_outline,
                          size: 48, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text(
                        "No se encontraron exploradores",
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _users.length,
                itemBuilder: (context, index) {
                  return _buildUserTile(_users[index], index);
                },
              ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, {VoidCallback? onAction}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          if (onAction != null)
            TextButton(
              onPressed: onAction,
              child: const Text(
                "VER TODO",
                style: TextStyle(
                  color: Colors.blue,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUserTile(Map<String, dynamic> user, int index) {
    final bool isFollowing = user['isFollowing'] ?? false;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: Colors.grey.shade200,
            child: Text(
              (user['displayName'] ?? user['username'] ?? 'U')[0].toUpperCase(),
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.black54),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      user['displayName'] ?? "Usuario",
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    if (user['isVerified'] == true)
                      const Padding(
                        padding: EdgeInsets.only(left: 4),
                        child: Icon(Icons.check_circle,
                            color: Colors.blue, size: 14),
                      ),
                  ],
                ),
                Text(
                  user['bio'] ?? user['level'] ?? "Explorador en ARte",
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            height: 32,
            width: isFollowing ? 100 : 80,
            child: ElevatedButton(
              onPressed: () {
                if (isFollowing) {
                  _showUnfollowDialog(user, index);
                } else {
                  _followUser(user['id'], index);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isFollowing ? Colors.grey.shade200 : Colors.blue,
                elevation: 0,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(
                isFollowing ? "Siguiendo" : "Seguir",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isFollowing ? Colors.black87 : Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showUnfollowDialog(Map<String, dynamic> user, int index) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text("Dejar de seguir"),
          content: Text("¿Seguro que quieres dejar de seguir a ${user['displayName'] ?? 'este usuario'}?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancelar", style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _unfollowUser(user['id'], index);
              },
              child: const Text("Dejar de seguir", style: TextStyle(color: AppTheme.arteRed, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _followUser(String userId, int index) async {
    // Optimistic UI update
    setState(() {
      _users[index]['isFollowing'] = true;
    });

    final success = await _userService.followUser(userId);
    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Ahora sigues a este usuario")),
        );
      }
    } else {
      // Revert if failed
      setState(() {
        _users[index]['isFollowing'] = false;
      });
    }
  }

  Future<void> _unfollowUser(String userId, int index) async {
    // Optimistic UI update
    setState(() {
      _users[index]['isFollowing'] = false;
    });

    final success = await _userService.unfollowUser(userId);
    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Has dejado de seguir a este usuario")),
        );
      }
    } else {
      // Revert if failed
      setState(() {
        _users[index]['isFollowing'] = true;
      });
    }
  }
}
