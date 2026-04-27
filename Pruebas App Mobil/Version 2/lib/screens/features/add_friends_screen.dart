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
  List<Map<String, dynamic>> _suggestions = [];
  List<Map<String, dynamic>> _explorers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final suggested = await _userService.getSuggestedUsers();

    if (mounted) {
      setState(() {
        _suggestions = suggested.take(5).toList();
        _explorers = suggested.skip(5).toList();
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

            // Suggestions Carousel
            if (_suggestions.isNotEmpty) ...[
              _buildSectionHeader("SUGERENCIAS PARA TI", onAction: () {}),
              const SizedBox(height: 12),
              SizedBox(
                height: 180,
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        itemCount: _suggestions.length,
                        itemBuilder: (context, index) {
                          return _buildSuggestionCard(_suggestions[index]);
                        },
                      ),
              ),
              const SizedBox(height: 24),
            ],

            const SizedBox(height: 24),
            // Follow Requests (Temporarily hidden until real logic is implemented)
            // _buildSectionHeader("SOLICITUDES DE SEGUIMIENTO"),

            const SizedBox(height: 24),

            // Explorers List
            if (_explorers.isNotEmpty) ...[
              _buildSectionHeader("EXPLORADORES QUE QUIZÁ CONOZCAS"),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _explorers.length,
                  itemBuilder: (context, index) {
                    return _buildExplorerTile(_explorers[index]);
                  },
                ),
            ] else if (!_isLoading && _suggestions.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Column(
                    children: [
                      Icon(Icons.person_outline,
                          size: 48, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text(
                        "No se encontraron más exploradores",
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ),
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

  Widget _buildSuggestionCard(Map<String, dynamic> user) {
    return Container(
      width: 130,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.orange, width: 2),
            ),
            child: CircleAvatar(
              radius: 30,
              backgroundColor: Colors.grey.shade200,
              child: Text(
                (user['displayName'] ?? user['username'] ?? 'U')[0]
                    .toUpperCase(),
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.black54),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            user['displayName'] ?? "Usuario",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            user['level'] ?? "Explorador",
            style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: 100,
            height: 32,
            child: ElevatedButton(
              onPressed: () => _followUser(user['id']),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding: EdgeInsets.zero,
              ),
              child: const Text("Seguir",
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExplorerTile(Map<String, dynamic> user) {
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
            width: 80,
            child: ElevatedButton(
              onPressed: () => _followUser(user['id']),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text("Seguir",
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _followUser(String userId) async {
    final success = await _userService.followUser(userId);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ahora sigues a este usuario")),
      );
      _loadData(); // Refresh lists
    }
  }
}
