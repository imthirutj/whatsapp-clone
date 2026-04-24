import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/call.dart';
import '../../services/api_service.dart';
import '../../constants.dart';
import '../../widgets/avatar_widget.dart';
import '../../utils/time_utils.dart';

class CallsScreen extends StatefulWidget {
  const CallsScreen({super.key});

  @override
  State<CallsScreen> createState() => _CallsScreenState();
}

class _CallsScreenState extends State<CallsScreen> {
  List<Call> _calls = [];
  bool _isLoading = false;
  final _api = ApiService();

  @override
  void initState() {
    super.initState();
    _loadCalls();
  }

  Future<void> _loadCalls() async {
    setState(() => _isLoading = true);
    try {
      final data = await _api.get('/calls');
      final list = data is List
          ? data
          : (data['calls'] as List<dynamic>? ?? []);
      setState(() {
        _calls = list
            .whereType<Map<String, dynamic>>()
            .map((c) => Call.fromJson(c))
            .toList();
        _calls.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      });
    } catch (_) {
      // Show empty state gracefully
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calls'),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            itemBuilder: (context) => [
              const PopupMenuItem(
                  value: 'clear_calls', child: Text('Clear call log')),
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

          if (_isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: kPrimary),
            );
          }

          if (_calls.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.call_outlined,
                      size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    'No recent calls',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your call history will appear here.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            color: kPrimary,
            onRefresh: _loadCalls,
            child: ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Text(
                    'Recent',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
                ..._calls.map((call) => _CallItem(
                  call: call,
                  currentUserId: currentUserId,
                )),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'calls_fab',
        onPressed: () {},
        child: const Icon(Icons.add_call),
      ),
    );
  }
}

class _CallItem extends StatelessWidget {
  final Call call;
  final String currentUserId;

  const _CallItem({
    required this.call,
    required this.currentUserId,
  });

  bool get _isOutgoing => call.caller.id == currentUserId;

  @override
  Widget build(BuildContext context) {
    final contactUser = _isOutgoing ? call.receiver : call.caller;
    final isMissed = call.isMissed;
    final nameColor = isMissed ? Colors.red.shade600 : const Color(0xFF1A1A1A);

    String callDescription;
    if (isMissed) {
      callDescription = 'Missed call';
    } else if (_isOutgoing) {
      callDescription = 'Outgoing';
    } else {
      callDescription = 'Incoming';
    }

    if (call.formattedDuration.isNotEmpty) {
      callDescription += ' · ${call.formattedDuration}';
    }

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: AvatarWidget(
        user: contactUser,
        size: 50,
      ),
      title: Row(
        children: [
          Icon(
            isMissed
                ? Icons.call_missed
                : _isOutgoing
                    ? Icons.call_made
                    : Icons.call_received,
            size: 14,
            color: isMissed
                ? Colors.red.shade600
                : _isOutgoing
                    ? Colors.green.shade600
                    : kPrimary,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              contactUser.name,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: nameColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      subtitle: Row(
        children: [
          Text(
            callDescription,
            style: TextStyle(
              fontSize: 13,
              color: isMissed ? Colors.red.shade400 : Colors.grey.shade600,
            ),
          ),
          Text(
            ' · ${TimeUtils.formatChatTime(call.createdAt)}',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
      trailing: IconButton(
        icon: Icon(
          call.type == 'video' ? Icons.videocam_outlined : Icons.call_outlined,
          color: kPrimary,
        ),
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Calling ${contactUser.name}...'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      ),
    );
  }
}
