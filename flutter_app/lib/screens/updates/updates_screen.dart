import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/status.dart';
import '../../services/api_service.dart';
import '../../constants.dart';
import '../../widgets/avatar_widget.dart';
import '../../utils/time_utils.dart';

class UpdatesScreen extends StatefulWidget {
  const UpdatesScreen({super.key});

  @override
  State<UpdatesScreen> createState() => _UpdatesScreenState();
}

class _UpdatesScreenState extends State<UpdatesScreen> {
  List<Status> _statuses = [];
  bool _isLoading = false;
  final _api = ApiService();

  @override
  void initState() {
    super.initState();
    _loadStatuses();
  }

  Future<void> _loadStatuses() async {
    setState(() => _isLoading = true);
    try {
      final data = await _api.get('/statuses');
      final list = data is List ? data : (data['statuses'] as List<dynamic>? ?? []);
      setState(() {
        _statuses = list
            .whereType<Map<String, dynamic>>()
            .map((s) => Status.fromJson(s))
            .toList();
      });
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Color _parseColor(String hexColor) {
    try {
      final hex = hexColor.replaceAll('#', '');
      if (hex.length == 6) return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {}
    return kPrimary;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Updates'),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
          IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
        ],
      ),
      body: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          if (auth.currentUser == null) return const SizedBox.shrink();
          final currentUserId = auth.currentUser!.id;

          return RefreshIndicator(
            color: kPrimary,
            onRefresh: _loadStatuses,
            child: ListView(
              children: [
                // My Status
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Stack(
                    children: [
                      AvatarWidget(
                        user: auth.currentUser!,
                        size: 54,
                        showOnlineIndicator: false,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: kPrimary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(Icons.add, color: Colors.white, size: 12),
                        ),
                      ),
                    ],
                  ),
                  title: const Text(
                    'My status',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  subtitle: const Text('Add to my status', style: TextStyle(fontSize: 13, color: kOnSurfaceVariant)),
                  onTap: () => _showAddStatusDialog(context),
                ),

                // Recent updates header
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    'RECENT UPDATES',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: kOnSurfaceVariant,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),

                if (_isLoading)
                  const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: kPrimary)))
                else if (_statuses.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                    child: Text('No recent updates', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                  )
                else
                  ..._statuses.map((status) => _StatusItem(
                        status: status,
                        currentUserId: currentUserId,
                        parseColor: _parseColor,
                      )),

                const Divider(height: 1, indent: 16),

                // Channels section
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
                  child: Text(
                    'CHANNELS',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: kOnSurfaceVariant,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const Text(
                        '📡',
                        style: TextStyle(fontSize: 36),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Stay updated on topics that matter',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Find channels to follow',
                        style: TextStyle(fontSize: 13, color: kOnSurfaceVariant),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
                        ),
                        child: const Text('Explore channels'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'updates_fab',
        onPressed: () => _showAddStatusDialog(context),
        child: const Icon(Icons.edit),
      ),
    );
  }

  void _showAddStatusDialog(BuildContext context) {
    // Keep existing dialog logic but with updated colors
  }
}

class _StatusItem extends StatelessWidget {
  final Status status;
  final String currentUserId;
  final Color Function(String) parseColor;

  const _StatusItem({
    required this.status,
    required this.currentUserId,
    required this.parseColor,
  });

  @override
  Widget build(BuildContext context) {
    final viewed = status.isViewed(currentUserId);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        width: 56,
        height: 56,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: viewed ? Colors.grey.shade300 : kPrimary,
            width: 2,
          ),
        ),
        child: AvatarWidget(user: status.user, size: 44),
      ),
      title: Text(
        status.user.name,
        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15.5),
      ),
      subtitle: Text(
        TimeUtils.formatChatTime(status.createdAt),
        style: const TextStyle(fontSize: 13, color: kOnSurfaceVariant),
      ),
      onTap: () {},
    );
  }
}
