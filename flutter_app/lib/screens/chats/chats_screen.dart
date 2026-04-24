import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../models/chat.dart';
import '../../constants.dart';
import '../../widgets/chat_list_item.dart';
import 'chat_detail_screen.dart';

class ChatsScreen extends StatefulWidget {
  const ChatsScreen({super.key});

  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  bool _showSearch = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().loadChats();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _showSearch
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                cursorColor: Colors.white,
                decoration: const InputDecoration(
                  hintText: 'Search...',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  fillColor: Colors.transparent,
                  filled: false,
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: (v) => setState(() => _searchQuery = v),
              )
            : const Text('WhatsApp'),
        actions: [
          IconButton(
            icon: Icon(_showSearch ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _showSearch = !_showSearch;
                if (!_showSearch) {
                  _searchController.clear();
                  _searchQuery = '';
                }
              });
            },
          ),
          if (!_showSearch)
            IconButton(
              icon: const Icon(Icons.camera_alt_outlined),
              onPressed: () {},
            ),
          if (!_showSearch)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) async {
                if (value == 'logout') {
                  final authProvider = context.read<AuthProvider>();
                  final chatProvider = context.read<ChatProvider>();
                  await authProvider.logout();
                  chatProvider.reset();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'new_group', child: Text('New group')),
                const PopupMenuItem(
                    value: 'new_broadcast', child: Text('New broadcast')),
                const PopupMenuItem(
                    value: 'linked_devices', child: Text('Linked devices')),
                const PopupMenuItem(
                    value: 'settings', child: Text('Settings')),
                const PopupMenuItem(value: 'logout', child: Text('Logout')),
              ],
            ),
        ],
      ),
      body: Consumer2<AuthProvider, ChatProvider>(
        builder: (context, auth, chat, _) {
          if (auth.currentUser == null) return const SizedBox.shrink();

          final currentUserId = auth.currentUser!.id;
          final filteredChats = chat.searchChats(_searchQuery, currentUserId);

          if (chat.isLoading && chat.chats.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: kPrimary),
            );
          }

          if (chat.error != null && chat.chats.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline,
                      size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    chat.error!,
                    style: TextStyle(color: Colors.grey.shade600),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  FilledButton.tonal(
                    onPressed: () => chat.loadChats(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (filteredChats.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline,
                      size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    _searchQuery.isNotEmpty
                        ? 'No chats found for "$_searchQuery"'
                        : 'No chats yet\nStart a new conversation!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            color: kPrimary,
            onRefresh: () => chat.loadChats(),
            child: ListView.separated(
              itemCount: filteredChats.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                indent: 82,
                color: Colors.grey.shade200,
              ),
              itemBuilder: (context, index) {
                final chatItem = filteredChats[index];
                return ChatListItem(
                  chat: chatItem,
                  currentUserId: currentUserId,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ChatDetailScreen(chat: chatItem),
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'chats_fab',
        onPressed: () {
          _showNewChatDialog(context);
        },
        child: const Icon(Icons.chat_rounded),
      ),
    );
  }

  void _showNewChatDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Chat'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'User ID or Phone',
            hintText: 'Enter participant ID',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final id = controller.text.trim();
              if (id.isEmpty) return;
              Navigator.pop(ctx);
              final chatProvider = context.read<ChatProvider>();
              final chat = await chatProvider.createChat(id);
              if (chat != null && context.mounted) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ChatDetailScreen(chat: chat),
                  ),
                );
              }
            },
            child: const Text('Start Chat'),
          ),
        ],
      ),
    );
  }
}
