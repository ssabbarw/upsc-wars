class ChatThread {
  const ChatThread({
    required this.chatId,
    required this.participantEmails,
    required this.lastMessageText,
    required this.lastMessageAt,
    required this.updatedAt,
    required this.unreadCount,
  });

  final String chatId;
  final List<String> participantEmails;
  final String? lastMessageText;
  final int? lastMessageAt;
  final int updatedAt;
  final int unreadCount;
}
