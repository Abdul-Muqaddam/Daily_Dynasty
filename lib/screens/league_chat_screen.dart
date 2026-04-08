import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/colors.dart';
import '../core/responsive_helper.dart';
import '../services/user_service.dart';

class LeagueChatScreen extends StatefulWidget {
  final String leagueId;
  final String leagueName;

  const LeagueChatScreen({
    super.key,
    required this.leagueId,
    required this.leagueName,
  });

  @override
  State<LeagueChatScreen> createState() => _LeagueChatScreenState();
}

class _LeagueChatScreenState extends State<LeagueChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final Map<String, String> _userNames = {};
  final String? _currentUserId = FirebaseAuth.instance.currentUser?.uid;
  String? _currentUserName;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserName();
  }

  Future<void> _loadCurrentUserName() async {
    if (_currentUserId == null) return;
    final name = await UserService.getUsername(_currentUserId!);
    if (mounted) setState(() => _currentUserName = name);
  }

  Future<String> _getUserName(String uid) async {
    if (_userNames.containsKey(uid)) return _userNames[uid]!;
    final name = await UserService.getUsername(uid);
    if (mounted) setState(() => _userNames[uid] = name);
    return name;
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _currentUserId == null) return;

    final message = _messageController.text.trim();
    _messageController.clear();

    await FirebaseFirestore.instance
        .collection('leagues')
        .doc(widget.leagueId)
        .collection('chat')
        .add({
      'senderId': _currentUserId,
      'senderName': _currentUserName ?? 'Unknown',
      'text': message,
      'timestamp': FieldValue.serverTimestamp(),
    });

    _scrollController.animateTo(
      0.0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveHelper.init(context);
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "LEAGUE CHAT",
              style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.w900),
            ),
            Text(
              widget.leagueName.toUpperCase(),
              style: TextStyle(color: AppColors.accentCyan, fontSize: 10.sp, fontWeight: FontWeight.bold, letterSpacing: 1.0),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('leagues')
                  .doc(widget.leagueId)
                  .collection('chat')
                  .orderBy('timestamp', descending: true)
                  .limit(100)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.accentCyan));
                }

                final docs = snapshot.data!.docs;

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: EdgeInsets.all(16.w),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final senderId = data['senderId'] as String? ?? 'unknown';
                    final senderName = data['senderName'] as String?;
                    final text = data['text'] as String? ?? '';
                    final timestamp = data['timestamp'] as Timestamp?;
                    final isMe = senderId == _currentUserId;

                    return _buildMessageBubble(senderId, senderName, text, timestamp, isMe);
                  },
                );
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(String senderId, String? senderName, String text, Timestamp? timestamp, bool isMe) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (senderName != null)
            Padding(
              padding: EdgeInsets.only(left: 4.w, right: 4.w, bottom: 4.h),
              child: Text(
                isMe ? "YOU" : senderName,
                style: TextStyle(
                  color: isMe ? AppColors.accentCyan : Colors.white54, 
                  fontSize: 10.sp, 
                  fontWeight: FontWeight.bold
                ),
              ),
            )
          else
            FutureBuilder<String>(
              future: _getUserName(senderId),
              builder: (context, snap) {
                return Padding(
                  padding: EdgeInsets.only(left: 4.w, bottom: 4.h),
                  child: Text(
                    isMe ? "YOU" : (snap.data ?? '...'),
                    style: TextStyle(
                      color: isMe ? AppColors.accentCyan : Colors.white54, 
                      fontSize: 10.sp, 
                      fontWeight: FontWeight.bold
                    ),
                  ),
                );
              },
            ),
          Row(
            mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              Container(
                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                decoration: BoxDecoration(
                  color: isMe ? AppColors.accentCyan.withOpacity(0.2) : AppColors.surface,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(isMe ? 16 : 0),
                    bottomRight: Radius.circular(isMe ? 0 : 16),
                  ),
                  border: Border.all(
                    color: isMe ? AppColors.accentCyan.withOpacity(0.5) : Colors.white10,
                  ),
                ),
                child: Text(
                  text,
                  style: TextStyle(color: Colors.white, fontSize: 13.sp),
                ),
              ),
            ],
          ),
          if (timestamp != null)
            Padding(
              padding: EdgeInsets.only(top: 4.h, left: 4.w, right: 4.w),
              child: Text(
                _formatTime(timestamp),
                style: TextStyle(color: Colors.white24, fontSize: 8.sp),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 16.h + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(24.h),
                border: Border.all(color: Colors.white10),
              ),
              child: TextField(
                controller: _messageController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Type a message...",
                  hintStyle: TextStyle(color: Colors.white24, fontSize: 13.sp),
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          SizedBox(width: 8.w),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              padding: EdgeInsets.all(12.w),
              decoration: const BoxDecoration(
                color: AppColors.accentCyan,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send_rounded, color: Colors.black, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(Timestamp ts) {
    final dt = ts.toDate();
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final min = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return "$hour:$min $ampm";
  }
}
