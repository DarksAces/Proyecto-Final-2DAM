import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/user_service.dart';
import 'profile_screen.dart';

class ConnectionsScreen extends StatefulWidget {
  final String userId;
  final int initialTabIndex;

  const ConnectionsScreen({
    super.key,
    required this.userId,
    this.initialTabIndex = 0,
  });

  @override
  State<ConnectionsScreen> createState() => _ConnectionsScreenState();
}

class _ConnectionsScreenState extends State<ConnectionsScreen> {
  final UserService _userService = UserService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _followers = [];
  List<Map<String, dynamic>> _following = [];

  @override
  void initState() {
    super.initState();
    _loadConnections();
  }

  Future<void> _loadConnections() async {
    setState(() => _isLoading = true);
    try {
      final followers = await _userService.getFollowersDetails(widget.userId);
      final following = await _userService.getFollowingDetails(widget.userId);
      if (mounted) {
        setState(() {
          _followers = followers;
          _following = following;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      initialIndex: widget.initialTabIndex,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: const BackButton(color: Colors.black),
          title: Text(
            widget.userId == _userService.currentUserId ? 'Mis Conexiones' : 'Conexiones',
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          centerTitle: true,
          bottom: const TabBar(
            indicatorColor: AppTheme.arteRed,
            labelColor: AppTheme.arteRed,
            unselectedLabelColor: Colors.grey,
            labelStyle: TextStyle(fontWeight: FontWeight.bold),
            tabs: [
              Tab(text: 'Seguidores'),
              Tab(text: 'Siguiendo'),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppTheme.arteRed))
            : TabBarView(
                children: [
                  _buildUserList(_followers, "Aún no tienes seguidores."),
                  _buildUserList(_following, "Aún no sigues a nadie."),
                ],
              ),
      ),
    );
  }

  Widget _buildUserList(List<Map<String, dynamic>> users, String emptyMessage) {
    if (users.isEmpty) {
      return Center(
        child: Text(
          emptyMessage,
          style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
        ),
      );
    }

    return RefreshIndicator(
      color: AppTheme.arteRed,
      onRefresh: _loadConnections,
      child: ListView.builder(
        itemCount: users.length,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemBuilder: (context, index) {
          final user = users[index];
          return _UserConnectionTile(
            user: user,
            userService: _userService,
            onRefresh: _loadConnections,
          );
        },
      ),
    );
  }
}

class _UserConnectionTile extends StatefulWidget {
  final Map<String, dynamic> user;
  final UserService userService;
  final VoidCallback onRefresh;

  const _UserConnectionTile({
    required this.user,
    required this.userService,
    required this.onRefresh,
  });

  @override
  State<_UserConnectionTile> createState() => _UserConnectionTileState();
}

class _UserConnectionTileState extends State<_UserConnectionTile> {
  bool _isFollowing = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkFollowingStatus();
  }

  Future<void> _checkFollowingStatus() async {
    final isFollowing = await widget.userService.isFollowing(widget.user['id']);
    if (mounted) {
      setState(() {
        _isFollowing = isFollowing;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleFollow() async {
    setState(() => _isLoading = true);
    final targetId = widget.user['id'];
    
    bool success;
    if (_isFollowing) {
      success = await widget.userService.unfollowUser(targetId);
    } else {
      success = await widget.userService.followUser(targetId);
    }

    if (success) {
      setState(() {
        _isFollowing = !_isFollowing;
      });
      // Optionally notify parent to refresh lists
      widget.onRefresh();
    }
    
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String name = widget.user['displayName'] ?? 'Usuario';
    final String title = widget.user['userTitle'] ?? 'Creador AR';
    final int colorVal = widget.user['avatarColor'] ?? 0xFFE30613;
    final String? avatarUrl = widget.user['avatarUrl'];
    final bool isMe = widget.user['id'] == widget.userService.currentUserId;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProfileScreen(userId: widget.user['id']),
          ),
        ).then((_) => widget.onRefresh());
      },
      leading: CircleAvatar(
        radius: 26,
        backgroundColor: Color(colorVal),
        backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
        child: avatarUrl == null
            ? Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              )
            : null,
      ),
      title: Text(
        name,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
      subtitle: Text(
        title,
        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
      ),
      trailing: isMe
          ? null
          : _isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.arteRed,
                  ),
                )
              : ElevatedButton(
                  onPressed: _toggleFollow,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isFollowing ? Colors.grey.shade200 : AppTheme.arteRed,
                    foregroundColor: _isFollowing ? Colors.black87 : Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: Text(
                    _isFollowing ? 'Siguiendo' : 'Seguir',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
    );
  }
}
