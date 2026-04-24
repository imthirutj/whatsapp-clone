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
      // Handle gracefully - show empty state
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
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            itemBuilder: (context) => [
              const PopupMenuItem(
                  value: 'status_privacy', child: Text('Status privacy')),
              const PopupMenuItem(
                  value: 'settings', child: Text('Settings')),
            ],
          ),
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
                // My Status section
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Text(
                    'My status',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
                ListTile(
                  leading: Stack(
                    children: [
                      AvatarWidget(
                        user: auth.currentUser!,
                        size: 52,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: const BoxDecoration(
                            color: kPrimary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  title: const Text(
                    'Add to my status',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text('Tap to add status update'),
                  onTap: () => _showAddStatusDialog(context),
                ),
                const Divider(height: 1, indent: 16),
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                        child: CircularProgressIndicator(color: kPrimary)),
                  )
                else if (_statuses.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(Icons.circle_outlined,
                            size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text(
                          'No recent updates',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Status updates from your contacts\nwill appear here.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ],
                    ),
                  )
                else ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                    child: Text(
                      'Recent updates',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                  ..._statuses.map((status) => _StatusItem(
                    status: status,
                    currentUserId: currentUserId,
                    parseColor: _parseColor,
                  )),
                ],
                // Channels section
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
                  child: Divider(height: 1),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Channels',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: const Text('Find channels'),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  child: Column(
                    children: [
                      Icon(Icons.campaign_outlined,
                          size: 48, color: Colors.grey.shade300),
                      const SizedBox(height: 8),
                      Text(
                        'Stay updated on topics that matter to you.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          foregroundColor: kPrimary,
                          side: const BorderSide(color: kPrimary),
                          minimumSize: const Size(double.infinity, 44),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        child: const Text('Find channels to follow'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddStatusDialog(context),
        child: const Icon(Icons.edit),
      ),
    );
  }

  void _showAddStatusDialog(BuildContext context) {
    final controller = TextEditingController();
    Color selectedColor = kPrimary;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add Status'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Type a status...',
                  labelText: 'Status text',
                ),
              ),
              const SizedBox(height: 16),
              const Text('Background color:'),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Color(0xFF006A4E),
                  Color(0xFF1565C0),
                  Color(0xFF6A1B9A),
                  Color(0xFFBF360C),
                  Color(0xFF37474F),
                ].map((color) {
                  return GestureDetector(
                    onTap: () => setDialogState(() => selectedColor = color),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: selectedColor == color
                            ? Border.all(
                                color: Colors.black38, width: 3)
                            : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final text = controller.text.trim();
                if (text.isEmpty) return;
                Navigator.pop(ctx);
                try {
                  final colorHex =
                      '#${selectedColor.value.toRadixString(16).substring(2)}';
                  await _api.post('/statuses', {
                    'text': text,
                    'backgroundColor': colorHex,
                  });
                  await _loadStatuses();
                } catch (_) {}
              },
              child: const Text('Post'),
            ),
          ],
        ),
      ),
    );
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
    final ringColor = viewed ? Colors.grey.shade400 : kPrimary;

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: ringColor, width: 2.5),
        ),
        child: AvatarWidget(
          user: status.user,
          size: 44,
        ),
      ),
      title: Text(
        status.user.name,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        TimeUtils.formatChatTime(status.createdAt),
        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
      ),
      onTap: () {
        _viewStatus(context);
      },
    );
  }

  void _viewStatus(BuildContext context) {
    final bgColor = parseColor(status.backgroundColor);
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          height: 500,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AvatarWidget(user: status.user, size: 60),
              const SizedBox(height: 16),
              Text(
                status.user.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 32),
              if (status.text != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    status.text!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              const SizedBox(height: 32),
              Text(
                TimeUtils.formatChatTime(status.createdAt),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
