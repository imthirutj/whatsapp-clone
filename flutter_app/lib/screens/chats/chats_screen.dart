import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../models/chat.dart';
import '../../models/user.dart';
import '../../services/version_service.dart';
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
        title: Text(
          'SchatApp',
          style: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.w400,
            color: kOnSurface,
          ),
        ),
        actions: [
          if (kIsWeb)
            IconButton(
              icon: const Icon(Icons.download_for_offline_outlined, size: 24),
              tooltip: 'Download APK',
              onPressed: () async {
                final versionInfo = await VersionService.getVersionInfo();
                if (versionInfo != null && versionInfo['apkFilename'] != null) {
                  final url = VersionService.getDownloadUrl(versionInfo['apkFilename']);
                  if (await canLaunchUrl(Uri.parse(url))) {
                    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                  }
                }
              },
            ),
          IconButton(
            icon: const Icon(Icons.camera_alt_outlined, size: 24),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.search, size: 24),
            onPressed: () {},
          ),
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
              const PopupMenuItem(value: 'new_broadcast', child: Text('New broadcast')),
              const PopupMenuItem(value: 'linked_devices', child: Text('Linked devices')),
              const PopupMenuItem(value: 'settings', child: Text('Settings')),
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

          return Column(
            children: [
              // Search Bar matching prototype exactly
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
                child: GestureDetector(
                  onTap: () {
                    // Could open a search overlay
                  },
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: kSurfaceVariant,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.grey.shade300,
                        width: 0.5,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Row(
                      children: [
                        Icon(Icons.search, size: 20, color: Colors.grey.shade600),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onChanged: (v) => setState(() => _searchQuery = v),
                            style: GoogleFonts.inter(fontSize: 14),
                            decoration: InputDecoration(
                              hintText: 'Ask Meta AI or Search',
                              hintStyle: GoogleFonts.inter(
                                fontSize: 14,
                                color: Colors.grey.shade500,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Chat List
              Expanded(
                child: chat.isLoading && chat.chats.isEmpty
                    ? Center(child: CircularProgressIndicator(color: kPrimary))
                    : RefreshIndicator(
                        color: kPrimary,
                        onRefresh: () => chat.loadChats(),
                        child: ListView.builder(
                          itemCount: filteredChats.length,
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
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'chats_fab',
        onPressed: () => _showNewChatDialog(context),
        child: const Icon(Icons.message_rounded),
      ),
    );
  }

  void _showNewChatDialog(BuildContext context) {
    final chatProvider = context.read<ChatProvider>();
    chatProvider.searchUsers(''); 

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
            return Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 6),
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('New Chat',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: TextField(
                    controller: _searchController,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Enter exact @username or email',
                      prefixIcon: Icon(Icons.search, color: kPrimary),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(28),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                    onChanged: (v) {
                      setState(() => _query = v);
                      _debounce?.cancel();
                      _debounce = Timer(const Duration(milliseconds: 500), () {
                        context.read<ChatProvider>().searchUsers(v);
                      });
                    },
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: chatProvider.isLoadingUsers
                      ? Center(child: CircularProgressIndicator(color: kPrimary))
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
                              subtitle: Text(user.email),
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
