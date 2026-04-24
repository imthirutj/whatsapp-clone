import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../chats/chats_screen.dart';
import '../updates/updates_screen.dart';
import '../community/community_screen.dart';
import '../calls/calls_screen.dart';
import '../../constants.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    ChatsScreen(),
    UpdatesScreen(),
    CommunityScreen(),
    CallsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      final chat = context.read<ChatProvider>();
      if (auth.currentUser != null) {
        chat.setCurrentUserId(auth.currentUser!.id);
      }
      chat.initSocketListeners();
      chat.loadChats();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, ChatProvider>(
      builder: (context, auth, chat, _) {
        final unreadCount = chat.totalUnreadCount;

        return Scaffold(
          body: IndexedStack(
            index: _selectedIndex,
            children: _screens,
          ),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: kSurface,
              border: Border(
                top: BorderSide(color: Colors.grey.shade200, width: 0.5),
              ),
            ),
            child: SafeArea(
              child: SizedBox(
                height: 56,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavItem(
                      index: 0,
                      icon: Icons.chat_bubble_outline,
                      activeIcon: Icons.chat_bubble,
                      label: 'Chats',
                    ),
                    _buildNavItem(
                      index: 1,
                      icon: Icons.donut_large_outlined,
                      activeIcon: Icons.donut_large,
                      label: 'Updates',
                      badgeCount: 2,
                      badgeColor: Colors.red,
                    ),
                    _buildNavItem(
                      index: 2,
                      icon: Icons.groups_outlined,
                      activeIcon: Icons.groups,
                      label: 'Communities',
                    ),
                    _buildNavItem(
                      index: 3,
                      icon: Icons.call_outlined,
                      activeIcon: Icons.call,
                      label: 'Calls',
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    int badgeCount = 0,
    Color badgeColor = kPrimary,
  }) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 72,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  isSelected ? activeIcon : icon,
                  color: isSelected ? kOnSurface : kOnSurfaceVariant,
                  size: 26,
                ),
                if (badgeCount > 0)
                  Positioned(
                    top: -5,
                    right: -10,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: badgeColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '$badgeCount',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? kOnSurface : kOnSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
