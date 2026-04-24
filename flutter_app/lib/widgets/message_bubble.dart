import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/message.dart';
import '../services/api_service.dart';
import '../constants.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMe;
  final bool showTail;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.showTail,
  });

  String _formatTime(DateTime time) {
    final local = time.toLocal();
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Widget _buildStatusRow(bool isMe, String timeStr, bool isRead, bool isDelivered) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          timeStr,
          style: GoogleFonts.inter(
            color: isMe ? Colors.white.withValues(alpha: 0.7) : const Color(0xFF667781),
            fontSize: 11,
          ),
        ),
        if (isMe) ...[
          const SizedBox(width: 4),
          Icon(
            (isRead || isDelivered) ? Icons.done_all : Icons.done,
            size: 16,
            color: isRead ? const Color(0xFF53BDEB) : Colors.white.withValues(alpha: 0.6),
          ),
        ],
      ],
    );
  }

  BoxDecoration _bubbleDecoration(bool isMe) => BoxDecoration(
    color: isMe ? const Color(0xFF005D4B) : Colors.white,
    borderRadius: BorderRadius.only(
      topLeft: Radius.circular(showTail && !isMe ? 2 : 16),
      topRight: Radius.circular(showTail && isMe ? 2 : 16),
      bottomLeft: const Radius.circular(16),
      bottomRight: const Radius.circular(16),
    ),
    boxShadow: [
      BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 1, offset: const Offset(0, 1)),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final timeStr = _formatTime(message.createdAt);
    final isRead = message.status == 'read';
    final isDelivered = message.status == 'delivered';

    return Padding(
      padding: EdgeInsets.only(
        left: isMe ? 64 : 12,
        right: isMe ? 12 : 64,
        top: showTail ? 8 : 2,
        bottom: 0,
      ),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: message.type == 'image'
            ? _ImageBubble(
                message: message,
                isMe: isMe,
                timeStr: timeStr,
                isRead: isRead,
                isDelivered: isDelivered,
                decoration: _bubbleDecoration(isMe),
                statusRow: _buildStatusRow(isMe, timeStr, isRead, isDelivered),
              )
            : Container(
                decoration: _bubbleDecoration(isMe),
                padding: const EdgeInsets.fromLTRB(12, 8, 10, 6),
                child: Wrap(
                  alignment: WrapAlignment.end,
                  crossAxisAlignment: WrapCrossAlignment.end,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Text(
                      message.text,
                      style: GoogleFonts.inter(
                        color: isMe ? Colors.white : const Color(0xFF111B21),
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        height: 1.4,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: _buildStatusRow(isMe, timeStr, isRead, isDelivered),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _ImageBubble extends StatefulWidget {
  final Message message;
  final bool isMe;
  final String timeStr;
  final bool isRead;
  final bool isDelivered;
  final BoxDecoration decoration;
  final Widget statusRow;

  const _ImageBubble({
    required this.message,
    required this.isMe,
    required this.timeStr,
    required this.isRead,
    required this.isDelivered,
    required this.decoration,
    required this.statusRow,
  });

  @override
  State<_ImageBubble> createState() => _ImageBubbleState();
}

class _ImageBubbleState extends State<_ImageBubble> {
  Uint8List? _imageBytes;
  bool _loading = false;

  Future<void> _loadAndShow() async {
    if (_imageBytes != null) {
      _showFullscreen();
      return;
    }
    setState(() => _loading = true);
    try {
      final bytes = await ApiService().fetchMediaBytes(widget.message.text);
      if (mounted) setState(() => _imageBytes = Uint8List.fromList(bytes));
      _showFullscreen();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load image')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showFullscreen() {
    if (_imageBytes == null) return;
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: InteractiveViewer(
            child: Image.memory(_imageBytes!, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _loadAndShow,
      child: Container(
        width: 180,
        decoration: widget.decoration,
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: widget.isMe
                    ? Colors.white.withValues(alpha: 0.12)
                    : Colors.black.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: _loading
                    ? const CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF006A4E))
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.photo,
                            size: 36,
                            color: widget.isMe
                                ? Colors.white.withValues(alpha: 0.7)
                                : const Color(0xFF667781),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Tap to view',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: widget.isMe
                                  ? Colors.white.withValues(alpha: 0.7)
                                  : const Color(0xFF667781),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.bottomRight,
              child: widget.statusRow,
            ),
          ],
        ),
      ),
    );
  }
}
