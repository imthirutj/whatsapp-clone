import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../models/chat.dart';
import '../../models/user.dart';
import '../../constants.dart';
import '../../widgets/chat_list_item.dart';
import '../../widgets/avatar_widget.dart';
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
    final chatProvider = context.read<ChatProvider>();
    chatProvider.searchUsers(''); // clear previous results

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _ContactPickerSheet(
        onSelectUser: (user) async {
          Navigator.pop(ctx);
          final chat = await chatProvider.createChat(user.id);
          if (chat != null && context.mounted) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ChatDetailScreen(chat: chat),
              ),
            );
          }
        },
      ),
    );
  }
}

class _ContactPickerSheet extends StatefulWidget {
  final void Function(User user) onSelectUser;
  const _ContactPickerSheet({required this.onSelectUser});

  @override
  State<_ContactPickerSheet> createState() => _ContactPickerSheetState();
}

class _ContactPickerSheetState extends State<_ContactPickerSheet> {
  final _searchController = TextEditingController();
  String _query = '';
  Timer? _debounce;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (_, scrollController) {
        return Consumer<ChatProvider>(
          builder: (context, chatProvider, _) {
            final filtered = chatProvider.users.where((u) {
              if (_query.isEmpty) return true;
              final q = _query.toLowerCase();
              return u.name.toLowerCase().contains(q) ||
                  (u.phone?.contains(q) ?? false) ||
                  u.email.toLowerCase().contains(q);
            }).toList();

            return Column(
              children: [
                // Handle
                Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 6),
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Title
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('New Chat',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  ),
                ),
                // Search
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: TextField(
                    controller: _searchController,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Enter exact @username or email',
                      prefixIcon: const Icon(Icons.search, color: kPrimary),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.arrow_forward, color: kPrimary),
                        onPressed: () => context.read<ChatProvider>().searchUsers(_query),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(28),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                    textInputAction: TextInputAction.search,
                    onChanged: (v) => setState(() => _query = v),
                    onSubmitted: (v) => context.read<ChatProvider>().searchUsers(v),
                  ),
                ),
                const Divider(height: 1),
                // List
                Expanded(
                  child: chatProvider.isLoadingUsers
                      ? const Center(child: CircularProgressIndicator(color: kPrimary))
                      : _query.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.person_search,
                                      size: 56, color: Colors.grey.shade300),
                                  const SizedBox(height: 12),
                                  Text('Type exact @username or email,\nthen press search',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          color: Colors.grey.shade500, fontSize: 14)),
                                ],
                              ),
                            )
                          : chatProvider.users.isEmpty
                              ? Center(
                                  child: Text(
                                    'No user found for "$_query"',
                                    style: TextStyle(color: Colors.grey.shade500),
                                  ),
                                )
                              : ListView.builder(
                                  controller: scrollController,
                                  itemCount: chatProvider.users.length,
                                  itemBuilder: (context, index) {
                                    final user = chatProvider.users[index];
                                    return ListTile(
                                      leading: AvatarWidget(
                                        user: user,
                                        size: 48,
                                        showOnlineIndicator: true,
                                      ),
                                      title: Text(
                                        user.name,
                                        style: const TextStyle(fontWeight: FontWeight.w600),
                                      ),
                                      subtitle: Text(
                                        user.username != null
                                            ? '@${user.username}  ·  ${user.email}'
                                            : user.email,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                      trailing: user.online
                                          ? Container(
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: kPrimary.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: const Text('online',
                                                  style: TextStyle(
                                                      fontSize: 11,
                                                      color: kPrimary,
                                                      fontWeight: FontWeight.w500)),
                                            )
                                          : null,
                                      onTap: () => widget.onSelectUser(user),
                                    );
                                  },
                                ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
